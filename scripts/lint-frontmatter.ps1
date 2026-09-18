#!/usr/bin/env pwsh
param(
    [string]$Root
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

if (-not $Root) {
    $Root = git rev-parse --show-toplevel 2>$null
    if (-not $Root) { throw 'Run this inside a git repository or pass -Root' }
}
$repoRoot = (Resolve-Path -LiteralPath $Root).Path
Set-Location $repoRoot

$errors = [System.Collections.Generic.List[string]]::new()

function Add-Err([string]$msg) { $errors.Add($msg) | Out-Null }

function Get-RelPath([string]$path) {
    $relative = [System.IO.Path]::GetRelativePath($repoRoot, $path)
    return ($relative -replace '\\', '/')
}

function Convert-Scalar([string]$value, [string]$rel, [int]$lineNumber) {
    $trimmed = $value.Trim()
    if ($trimmed -eq '[]') { return ,@() }
    if ($trimmed -match '^\[(.*)\]$') {
        $inner = $Matches[1].Trim()
        if (-not $inner) { return ,@() }
        return ,@($inner -split ',' | ForEach-Object { Convert-Scalar $_ $rel $lineNumber })
    }
    if ($trimmed.StartsWith('"') -or $trimmed.StartsWith("'")) {
        $quote = $trimmed.Substring(0, 1)
        $escaped = $false
        $end = -1
        for ($idx = 1; $idx -lt $trimmed.Length; $idx++) {
            $char = $trimmed[$idx]
            if ($quote -eq '"' -and $escaped) {
                if ('0abtnvfre "_\/N_LP' -notlike "*$char*") {
                    Add-Err "${rel}:${lineNumber}: invalid YAML escape '\$char'"
                    return $null
                }
                $escaped = $false
                continue
            }
            if ($quote -eq '"' -and $char -eq '\') {
                $escaped = $true
                continue
            }
            if ($char -eq $quote[0]) {
                if ($quote -eq "'" -and ($idx + 1) -lt $trimmed.Length -and $trimmed[$idx + 1] -eq "'") {
                    $idx++
                    continue
                }
                $end = $idx
                break
            }
        }
        if ($escaped -or $end -lt 0) {
            Add-Err "${rel}:${lineNumber}: unterminated quoted scalar"
            return $null
        }
        $tail = $trimmed.Substring($end + 1).Trim()
        if ($tail -and -not $tail.StartsWith('#')) {
            Add-Err "${rel}:${lineNumber}: malformed quoted scalar"
            return $null
        }
        return $trimmed.Substring(1, $end - 1)
    }
    if ($trimmed.Contains('"') -or $trimmed.Contains("'")) {
        Add-Err "${rel}:${lineNumber}: malformed quoted scalar"
        return $null
    }
    if ($trimmed -eq 'true') { return $true }
    if ($trimmed -eq 'false') { return $false }
    if ($trimmed -in @('null', 'Null', 'NULL', '~')) { return $null }
    if ($trimmed -match '^-?\d+$') {
        return [int]$trimmed
    }
    if ($trimmed -match '^-?\d+\.\d+$') { return [double]$trimmed }
    if ($trimmed -notmatch '^[A-Za-z0-9][A-Za-z0-9._:/@*+-]*$') {
        Add-Err "${rel}:${lineNumber}: unsupported unquoted scalar '$trimmed'"
        return $null
    }
    return $trimmed
}

function Get-FrontmatterLines([string]$path) {
    $lines = @(Get-Content -LiteralPath $path)
    if ($lines.Count -lt 3 -or $lines[0].Trim() -ne '---') { return $null }
    $end = -1
    for ($i = 1; $i -lt [Math]::Min(80, $lines.Count); $i++) {
        if ($lines[$i].Trim() -eq '---') { $end = $i; break }
    }
    if ($end -lt 0) { return $null }
    if ($end -eq 1) { return @() }
    return @($lines[1..($end - 1)])
}

function Get-Indent([string]$line) {
    if ($line -match '^(\s*)') { return $Matches[1].Length }
    return 0
}

function Read-BlockScalar([string[]]$lines, [int]$start, [string]$mode, [int]$headerIndent) {
    $parts = [System.Collections.Generic.List[string]]::new()
    $i = $start + 1
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        if ($line.Trim() -and (Get-Indent $line) -le $headerIndent) { break }
        if ($line.Trim()) { $parts.Add($line.Trim()) | Out-Null }
        $i++
    }
    $separator = if ($mode -eq '|') { "`n" } else { ' ' }
    return @{ value = ($parts -join $separator); next = ($i - 1) }
}

function Get-NextContentLine([string[]]$lines, [int]$start) {
    for ($j = $start + 1; $j -lt $lines.Count; $j++) {
        if ($lines[$j].Trim() -and -not $lines[$j].TrimStart().StartsWith('#')) {
            return $lines[$j]
        }
    }
    return $null
}

function Add-MapValue([System.Collections.IDictionary]$map, [hashtable]$seen, [string]$path, [string]$key, [object]$value, [string]$relPath) {
    if ($seen.ContainsKey($key)) {
        Add-Err "${relPath}: duplicate frontmatter key '$path$key'"
        return
    }
    $seen[$key] = $true
    $map[$key] = $value
}

function Parse-Frontmatter([string]$path) {
    $rel = Get-RelPath $path
    $lines = Get-FrontmatterLines $path
    if ($null -eq $lines) {
        Add-Err "${rel}: missing valid frontmatter"
        return $null
    }

    $root = [ordered]@{}
    $rootSeen = @{}
    $nestedSeen = @{}
    $currentMap = $null
    $currentMapName = $null
    $currentTopArray = $null
    $currentNestedArray = $null

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if (-not $line.Trim() -or $line.TrimStart().StartsWith('#')) { continue }
        if ($line -match "`t") {
            Add-Err "${rel}:$($i + 2): tabs are not allowed in frontmatter indentation"
            continue
        }

        if ($line -match '^([A-Za-z][A-Za-z0-9_-]*):(?:\s*(.*))?$') {
            $key = $Matches[1]
            $rawValue = $Matches[2]
            $currentMap = $null
            $currentMapName = $null
            $currentTopArray = $null
            $currentNestedArray = $null

            if ($rawValue -in @('|', '>')) {
                $block = Read-BlockScalar $lines $i $rawValue 0
                Add-MapValue $root $rootSeen '' $key $block.value $rel
                $i = $block.next
            } elseif ($rawValue -eq '') {
                $next = Get-NextContentLine $lines $i
                if ($next -and $next -match '^\s{2}-\s*') {
                    $array = @()
                    Add-MapValue $root $rootSeen '' $key $array $rel
                    $currentTopArray = $key
                } else {
                    $map = [ordered]@{}
                    Add-MapValue $root $rootSeen '' $key $map $rel
                    $nestedSeen[$key] = @{}
                    $currentMap = $map
                    $currentMapName = $key
                }
            } else {
                $value = Convert-Scalar $rawValue $rel ($i + 2)
                Add-MapValue $root $rootSeen '' $key $value $rel
            }
            continue
        }

        if ($line -match '^\s{2}([A-Za-z][A-Za-z0-9_-]*):(?:\s*(.*))?$' -and $null -ne $currentMap) {
            $key = $Matches[1]
            $rawValue = $Matches[2]
            $currentTopArray = $null
            $currentNestedArray = $null
            if (-not $nestedSeen.ContainsKey($currentMapName)) { $nestedSeen[$currentMapName] = @{} }

            if ($rawValue -in @('|', '>')) {
                $block = Read-BlockScalar $lines $i $rawValue 2
                Add-MapValue $currentMap $nestedSeen[$currentMapName] "$currentMapName." $key $block.value $rel
                $i = $block.next
            } elseif ($rawValue -eq '') {
                $array = @()
                Add-MapValue $currentMap $nestedSeen[$currentMapName] "$currentMapName." $key $array $rel
                $currentNestedArray = "$currentMapName.$key"
            } else {
                Add-MapValue $currentMap $nestedSeen[$currentMapName] "$currentMapName." $key (Convert-Scalar $rawValue $rel ($i + 2)) $rel
            }
            continue
        }

        if ($line -match '^\s{2}-\s*(.+?)\s*$' -and $currentTopArray) {
            $root[$currentTopArray] += @(Convert-Scalar $Matches[1] $rel ($i + 2))
            continue
        }

        if ($line -match '^\s{4}-\s*(.+?)\s*$' -and $currentNestedArray) {
            $segments = $currentNestedArray.Split('.')
            $map = $root[$segments[0]]
            $items = @($map[$segments[1]])
            $map[$segments[1]] = @($items + @(Convert-Scalar $Matches[1] $rel ($i + 2)))
            continue
        }

        Add-Err "${rel}:$($i + 2): malformed or unsupported frontmatter line '$line'"
    }

    return $root
}

function Test-StringField([System.Collections.IDictionary]$fm, [string]$field, [string]$rel) {
    if (-not $fm.Contains($field) -or -not ($fm[$field] -is [string]) -or -not $fm[$field].Trim()) {
        Add-Err "${rel}: missing or invalid string field '$field'"
        return $null
    }
    return $fm[$field]
}

function Test-ArrayField([System.Collections.IDictionary]$fm, [string]$field, [string]$rel) {
    if (-not $fm.Contains($field) -or -not ($fm[$field] -is [array])) {
        Add-Err "${rel}: missing or invalid array field '$field'"
        return @()
    }
    $items = @($fm[$field])
    foreach ($item in $items) {
        if (-not ($item -is [string]) -or -not $item.Trim()) {
            Add-Err "${rel}: array field '$field' must contain only non-empty strings"
        }
    }
    return $items
}

function Test-MapField([System.Collections.IDictionary]$fm, [string]$field, [string]$rel) {
    if (-not $fm.Contains($field) -or -not ($fm[$field] -is [System.Collections.IDictionary])) {
        Add-Err "${rel}: missing or invalid mapping field '$field'"
        return $null
    }
    return $fm[$field]
}

function Test-IntegerField([System.Collections.IDictionary]$fm, [string]$field, [string]$rel) {
    if (-not $fm.Contains($field) -or -not ($fm[$field] -is [int])) {
        Add-Err "${rel}: missing or invalid integer field '$field'"
        return $null
    }
    return $fm[$field]
}

function Test-Enum([string]$value, [string]$field, [string[]]$allowed, [string]$rel) {
    if ($value -and $value -notin $allowed) {
        Add-Err "${rel}: $field '$value' must be one of: $($allowed -join ', ')"
    }
}

function Get-EvalCounts([string]$evalPath) {
    $txt = Get-Content -LiteralPath $evalPath -Raw
    $pos = ([regex]::Matches($txt, 'expect_activation:\s*true')).Count
    $neg = ([regex]::Matches($txt, 'expect_activation:\s*false')).Count
    return @{ pos = $pos; neg = $neg }
}

$validCategories = @('design', 'foundation', 'brand', 'ia', 'usability', 'a11y', 'security', 'content', 'mapping', 'lifecycle', 'governance')
$validPillars = @('foundations', 'brand', 'ia', 'components', 'usability', 'content', 'a11y', 'security', 'mapping', 'lifecycle', 'governance')
$validMaturity = @('draft', 'beta', 'stable')

# --- skills ---
$skillDirs = Get-ChildItem skills -Directory -ErrorAction SilentlyContinue
foreach ($dir in $skillDirs) {
    $skillPath = Join-Path $dir.FullName 'SKILL.md'
    $evalPath = Join-Path $dir.FullName 'eval.yaml'
    $rel = if (Test-Path $skillPath) { Get-RelPath $skillPath } else { "skills/$($dir.Name)/SKILL.md" }
    if (-not (Test-Path $skillPath)) { Add-Err "skills/$($dir.Name): missing SKILL.md"; continue }
    if (-not (Test-Path $evalPath)) { Add-Err "skills/$($dir.Name): missing eval.yaml" }

    $fm = Parse-Frontmatter $skillPath
    if ($null -eq $fm) { continue }

    $name = Test-StringField $fm 'name' $rel
    if ($name -and $name -ne $dir.Name) { Add-Err "${rel}: name '$name' must match folder '$($dir.Name)'" }
    $compatibility = @(Test-ArrayField $fm 'compatibility' $rel)
    if ('github-copilot-cli' -notin $compatibility) { Add-Err "${rel}: compatibility must include github-copilot-cli" }
    $description = Test-StringField $fm 'description' $rel
    $category = Test-StringField $fm 'category' $rel
    Test-Enum $category 'category' $validCategories $rel
    $metadata = Test-MapField $fm 'metadata' $rel
    $allowedTools = @(Test-ArrayField $fm 'allowed-tools' $rel)
    $null = $allowedTools

    if ($metadata) {
        $metadataCategory = Test-StringField $metadata 'category' "$rel metadata"
        Test-Enum $metadataCategory 'metadata.category' $validCategories $rel
        if ($category -and $metadataCategory -and $metadataCategory -ne $category) {
            Add-Err "${rel}: metadata.category '$metadataCategory' must match category '$category'"
        }
        $maturity = Test-StringField $metadata 'maturity' "$rel metadata"
        Test-Enum $maturity 'metadata.maturity' $validMaturity $rel
        $audience = @(Test-ArrayField $metadata 'audience' "$rel metadata")
        if ($audience.Count -eq 0) { Add-Err "${rel}: metadata.audience must contain at least one audience" }
        $pillar = Test-StringField $metadata 'pillar' "$rel metadata"
        Test-Enum $pillar 'metadata.pillar' $validPillars $rel
    }

    if ($description) {
        if ($description -notmatch 'USE FOR:') { Add-Err "skills/$($dir.Name): description missing 'USE FOR:'" }
        if ($description -notmatch 'DO NOT USE FOR:') { Add-Err "skills/$($dir.Name): description missing 'DO NOT USE FOR:'" }
        if ($description -match 'USE FOR:\s*([^\.]+)') {
            $triggers = @($Matches[1].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            if ($triggers.Count -lt 3) { Add-Err "skills/$($dir.Name): USE FOR must include >=3 triggers" }
        }
        if ($description -match 'DO NOT USE FOR:\s*([^\.]+)') {
            $anti = @($Matches[1].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            if ($anti.Count -lt 2) { Add-Err "skills/$($dir.Name): DO NOT USE FOR must include >=2 anti-triggers" }
        }
    }

    if (Test-Path $evalPath) {
        $counts = Get-EvalCounts $evalPath
        if ($counts.pos -lt 3 -or $counts.neg -lt 2) {
            Add-Err "skills/$($dir.Name)/eval.yaml: requires >=3 positive and >=2 negative scenarios"
        }
    }
}

# --- agents ---
$agentFiles = Get-ChildItem agents -Filter '*.agent.md' -File -ErrorAction SilentlyContinue
foreach ($agent in $agentFiles) {
    $rel = Get-RelPath $agent.FullName
    $fm = Parse-Frontmatter $agent.FullName
    if ($null -eq $fm) { continue }

    $expectedName = $agent.BaseName -replace '\.agent$', ''
    $name = Test-StringField $fm 'name' $rel
    if ($name -and $name -ne $expectedName) { Add-Err "${rel}: name '$name' must match file basename '$expectedName'" }
    $compatibility = @(Test-ArrayField $fm 'compatibility' $rel)
    if ('github-copilot-cli' -notin $compatibility) { Add-Err "${rel}: compatibility must include github-copilot-cli" }
    $null = Test-StringField $fm 'description' $rel
    $metadata = Test-MapField $fm 'metadata' $rel
    if ($metadata) {
        $maturity = Test-StringField $metadata 'maturity' "$rel metadata"
        Test-Enum $maturity 'metadata.maturity' $validMaturity $rel
        $pillar = Test-StringField $metadata 'pillar' "$rel metadata"
        Test-Enum $pillar 'metadata.pillar' $validPillars $rel
    }
    $composes = Test-MapField $fm 'composes' $rel
    if ($composes) {
        $skills = @(Test-ArrayField $composes 'skills' "$rel composes")
        if ($skills.Count -eq 0) { Add-Err "${rel}: composes.skills must contain at least one skill" }
        $null = Test-ArrayField $composes 'instructions' "$rel composes"
    }
    $null = Test-ArrayField $fm 'allowed-tools' $rel
    if ($fm.Contains('model') -and -not ($fm['model'] -is [string])) { Add-Err "${rel}: model must be a string when present" }

    $eval = Join-Path $agent.DirectoryName (($agent.BaseName -replace '\.agent$', '') + '.agent.eval.yaml')
    if (-not (Test-Path $eval)) { Add-Err "agents/$($agent.Name): missing eval file" }
    else {
        $counts = Get-EvalCounts $eval
        if ($counts.pos -lt 3 -or $counts.neg -lt 2) {
            Add-Err "agents/$($agent.Name): eval requires >=3 positive and >=2 negative scenarios"
        }
    }
}

# --- instructions ---
$instructionFiles = Get-ChildItem instructions -Filter '*.instructions.md' -File -ErrorAction SilentlyContinue
foreach ($ins in $instructionFiles) {
    $rel = Get-RelPath $ins.FullName
    if ($ins.Name -notmatch '^sheen-(10|20|30|40|50|60|70|80|90)-[a-z0-9]+(?:-[a-z0-9]+)*\.instructions\.md$') {
        Add-Err "instructions/$($ins.Name): invalid naming"
    }
    $fm = Parse-Frontmatter $ins.FullName
    if ($null -eq $fm) { continue }
    $name = Test-StringField $fm 'name' $rel
    if ($name -and "$name.instructions.md" -ne $ins.Name) { Add-Err "${rel}: name '$name' must match filename" }
    $compatibility = @(Test-ArrayField $fm 'compatibility' $rel)
    if ('github-copilot-cli' -notin $compatibility) { Add-Err "${rel}: compatibility must include github-copilot-cli" }
    $null = Test-StringField $fm 'description' $rel
    $applyTo = Test-StringField $fm 'applyTo' $rel
    if ($applyTo) {
        $patterns = @($applyTo.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        if ('**' -in $patterns -or '**/*' -in $patterns) {
            Add-Err "${rel}: applyTo must not include universal scope '**' or '**/*'"
        }
    }
    $metadata = Test-MapField $fm 'metadata' $rel
    if ($metadata) {
        $band = Test-IntegerField $metadata 'band' "$rel metadata"
        if ($null -ne $band -and $name -match '^sheen-([0-9]{2})-') {
            $expectedBand = [int]$Matches[1]
            if ($band -ne $expectedBand) { Add-Err "${rel}: metadata.band '$band' must match filename band '$expectedBand'" }
        }
        $null = Test-StringField $metadata 'layer' "$rel metadata"
    }
}

# --- reference integrity ---
$knownSkills = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
(Get-ChildItem skills -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) | ForEach-Object { $knownSkills.Add($_) | Out-Null }

foreach ($agent in $agentFiles) {
    $fm = Parse-Frontmatter $agent.FullName
    if ($null -eq $fm -or -not $fm.Contains('composes') -or -not ($fm['composes'] -is [System.Collections.IDictionary]) -or -not $fm['composes'].Contains('skills')) { continue }
    foreach ($ref in @($fm['composes']['skills'])) {
        if (-not $knownSkills.Contains($ref)) {
            Add-Err "agents/$($agent.Name): composes.skills references missing skill '$ref'"
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($e in $errors) { Write-Host "::error::$e" }
    Write-Host "lint-frontmatter: FAILED ($($errors.Count) error(s))"
    exit 1
}

Write-Host "lint-frontmatter: OK"
exit 0

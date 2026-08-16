# Shared helpers for eval routing audit/test scripts.
Set-StrictMode -Version Latest

function Get-RepoRoot {
    param([string]$Start = (Get-Location).Path)
    $current = Resolve-Path -LiteralPath $Start
    while ($current) {
        if (Test-Path -LiteralPath (Join-Path $current.Path '.git')) { return $current.Path }
        $parent = Split-Path -Parent $current.Path
        if (-not $parent -or $parent -eq $current.Path) { break }
        $current = Resolve-Path -LiteralPath $parent
    }
    return (Resolve-Path -LiteralPath $Start).Path
}

function ConvertTo-PlainYamlValue {
    param([string]$Value)
    if ($null -eq $Value) { return '' }
    $v = $Value.Trim()
    if (($v.StartsWith('"') -and $v.EndsWith('"')) -or ($v.StartsWith("'") -and $v.EndsWith("'"))) {
        $v = $v.Substring(1, $v.Length - 2)
    }
    return $v -replace '\\"','"' -replace "''","'"
}

function Get-TokenSet {
    param([string]$Text)
    $stop = @{
        'about'=1;'above'=1;'after'=1;'again'=1;'agent'=1;'also'=1;'and'=1;'are'=1;'audit'=1;'basecoat'=1;'before'=1;'being'=1;'between'=1;'build'=1;'can'=1;'cli'=1;'composed'=1;'create'=1;'design'=1;'does'=1;'done'=1;'for'=1;'from'=1;'handle'=1;'help'=1;'into'=1;'need'=1;'only'=1;'orchestrate'=1;'our'=1;'please'=1;'product'=1;'request'=1;'run'=1;'sheen'=1;'skill'=1;'skills'=1;'spec'=1;'that'=1;'the'=1;'their'=1;'this'=1;'using'=1;'validate'=1;'with'=1;'workflow'=1;'your'=1
    }
    $matches = [regex]::Matches($Text.ToLowerInvariant(), '[a-z][a-z0-9-]{2,}')
    $tokens = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($m in $matches) {
        $t = $m.Value.Trim('-')
        if ($t.Length -ge 4 -and -not $stop.ContainsKey($t)) { [void]$tokens.Add($t) }
    }
    return $tokens
}

function Get-EvalFiles {
    param([string]$RepoRoot)
    $skillFiles = @()
    $agentFiles = @()
    $skillsDir = Join-Path $RepoRoot 'skills'
    $agentsDir = Join-Path $RepoRoot 'agents'
    if (Test-Path -LiteralPath $skillsDir) {
        $skillFiles = @(Get-ChildItem -LiteralPath $skillsDir -Directory | ForEach-Object {
            $path = Join-Path $_.FullName 'eval.yaml'
            if (Test-Path -LiteralPath $path) { Get-Item -LiteralPath $path }
        })
    }
    if (Test-Path -LiteralPath $agentsDir) {
        $agentFiles = @(Get-ChildItem -LiteralPath $agentsDir -Filter '*.agent.eval.yaml' -File)
    }
    return @($skillFiles + $agentFiles | Sort-Object FullName)
}

function Parse-EvalFile {
    param([string]$Path, [string]$RepoRoot)
    $lines = Get-Content -LiteralPath $Path
    $eval = [ordered]@{
        path = (Resolve-Path -LiteralPath $Path).Path.Substring((Resolve-Path -LiteralPath $RepoRoot).Path.Length + 1) -replace '\\','/'
        name = $null
        description = $null
        skill = $null
        scenarios = @()
        parse_errors = @()
    }
    $current = $null
    foreach ($line in $lines) {
        if ($line -match '^\s*#') { continue }
        if ($line -match '^name:\s*(.+?)\s*$') { $eval.name = ConvertTo-PlainYamlValue $Matches[1]; continue }
        if ($line -match '^description:\s*(.+?)\s*$') { $eval.description = ConvertTo-PlainYamlValue $Matches[1]; continue }
        if ($line -match '^skill:\s*(.+?)\s*$') { $eval.skill = ConvertTo-PlainYamlValue $Matches[1]; continue }
        if ($line -match '^\s*-\s*\{\s*id:\s*([^,]+),\s*input:\s*(.+),\s*expect_activation:\s*(true|false)\s*\}\s*$') {
            $eval.scenarios += [ordered]@{ id = ConvertTo-PlainYamlValue $Matches[1]; input = ConvertTo-PlainYamlValue $Matches[2]; expect_activation = [bool]::Parse($Matches[3]) }
            $current = $null
            continue
        }
        if ($line -match '^\s*-\s*id:\s*(.+?)\s*$') {
            if ($current) { $eval.scenarios += $current }
            $current = [ordered]@{ id = ConvertTo-PlainYamlValue $Matches[1]; input = $null; expect_activation = $null }
            continue
        }
        if ($null -ne $current -and $line -match '^\s*input:\s*(.+?)\s*$') { $current.input = ConvertTo-PlainYamlValue $Matches[1]; continue }
        if ($null -ne $current -and $line -match '^\s*expect_activation:\s*(true|false)\s*$') { $current.expect_activation = [bool]::Parse($Matches[1]); continue }
    }
    if ($current) { $eval.scenarios += $current }
    if (-not $eval.name) { $eval.parse_errors += 'missing top-level name' }
    if (-not $eval.description) { $eval.parse_errors += 'missing top-level description' }
    if (-not $eval.skill) { $eval.parse_errors += 'missing top-level skill' }
    $i = 0
    foreach ($s in $eval.scenarios) {
        $i++
        if (-not $s.id) { $eval.parse_errors += "scenario $i missing id" }
        if (-not $s.input) { $eval.parse_errors += "scenario $i missing input" }
        if ($null -eq $s.expect_activation) { $eval.parse_errors += "scenario $i missing expect_activation" }
    }
    return [pscustomobject]$eval
}

function Get-ReferencedAssetText {
    param([string]$RepoRoot, [string]$SkillPath)
    if (-not $SkillPath) { return '' }
    $relative = $SkillPath -replace '/', [System.IO.Path]::DirectorySeparatorChar
    $full = Join-Path $RepoRoot $relative
    if (Test-Path -LiteralPath $full) { return (Get-Content -LiteralPath $full -Raw) }
    return ''
}

function Get-EvalSpecificity {
    param([pscustomobject]$Eval, [string]$AssetText)
    $positive = @($Eval.scenarios | Where-Object { $_.expect_activation -eq $true })
    $negative = @($Eval.scenarios | Where-Object { $_.expect_activation -eq $false })
    $score = 0.0
    $notes = [System.Collections.Generic.List[string]]::new()

    if ($positive.Count -ge 4) { $score += 2.0 } elseif ($positive.Count -eq 3) { $score += 1.7 } elseif ($positive.Count -eq 2) { $score += 1.0 } elseif ($positive.Count -eq 1) { $score += 0.5 }
    if ($negative.Count -ge 3) { $score += 2.0 } elseif ($negative.Count -eq 2) { $score += 1.7 } elseif ($negative.Count -eq 1) { $score += 0.8 }

    $inputs = @($Eval.scenarios | ForEach-Object { [string]$_.input })
    $posInputs = @($positive | ForEach-Object { [string]$_.input })
    $avgWords = 0.0
    if ($inputs.Count -gt 0) { $avgWords = (($inputs | ForEach-Object { ([regex]::Matches($_, '\b\S+\b')).Count } | Measure-Object -Average).Average) }
    if ($avgWords -ge 11) { $score += 2.0 } elseif ($avgWords -ge 9) { $score += 1.6 } elseif ($avgWords -ge 7) { $score += 1.1 } elseif ($avgWords -ge 5) { $score += 0.6 }

    $allTokens = Get-TokenSet ($posInputs -join ' ')
    $diversityRatio = 0.0
    if ($positive.Count -gt 0) { $diversityRatio = $allTokens.Count / [double]$positive.Count }
    if ($diversityRatio -ge 6) { $score += 1.5 } elseif ($diversityRatio -ge 4.5) { $score += 1.1 } elseif ($diversityRatio -ge 3) { $score += 0.7 }

    $assetTokens = Get-TokenSet $AssetText
    $overlap = 0
    foreach ($t in $allTokens) { if ($assetTokens.Contains($t)) { $overlap++ } }
    if ($overlap -ge 8) { $score += 1.5 } elseif ($overlap -ge 5) { $score += 1.1 } elseif ($overlap -ge 3) { $score += 0.7 } elseif ($overlap -ge 1) { $score += 0.3 }

    $adjacentTerms = @('accessibility','a11y','brand','component','contrast','copy','content','css','design','figma','grid','handoff','i18n','icon','information','interaction','journey','layout','localization','mapping','navigation','palette','pattern','research','responsive','security','states','taxonomy','theme','token','typography','usability','visual','wireframe','wcag')
    $hardNegatives = 0
    foreach ($n in $negative) {
        $text = ([string]$n.input).ToLowerInvariant()
        $hasAdjacent = $false
        foreach ($term in $adjacentTerms) { if ($text.Contains($term)) { $hasAdjacent = $true; break } }
        $wordCount = ([regex]::Matches($text, '\b\S+\b')).Count
        if ($hasAdjacent -and $wordCount -ge 6) { $hardNegatives++ }
    }
    if ($hardNegatives -ge 2) { $score += 1.0 } elseif ($hardNegatives -eq 1) { $score += 0.5 }

    $boilerplatePatterns = @(
        'Need help with .+ for our product experience',
        'Create a plan for .+ in an upcoming release',
        'Compare approaches for .+ and recommend one',
        'Use .+ to handle a .+ request',
        'Need a .+-focused decision package from this agent',
        'Orchestrate composed skills for this mandate using',
        'This request is only about',
        'Please focus exclusively on',
        'Implement backend APIs and database migrations'
    )
    $boilerplateHits = 0
    foreach ($input in $inputs) {
        foreach ($pattern in $boilerplatePatterns) {
            if ($input -match $pattern) { $boilerplateHits++; break }
        }
    }
    if ($boilerplateHits -ge 4) { $score -= 1.0; $notes.Add("boilerplate inputs: $boilerplateHits") }
    elseif ($boilerplateHits -ge 2) { $score -= 0.6; $notes.Add("boilerplate inputs: $boilerplateHits") }
    elseif ($boilerplateHits -eq 1) { $score -= 0.4; $notes.Add('one boilerplate input') }

    $normalizedInputs = @($inputs | ForEach-Object { ($_ -replace '[^a-zA-Z0-9 ]','').ToLowerInvariant() })
    $duplicateCount = $normalizedInputs.Count - ($normalizedInputs | Select-Object -Unique).Count
    if ($duplicateCount -gt 0) { $score -= [Math]::Min(1.0, $duplicateCount * 0.5); $notes.Add("duplicate-like inputs: $duplicateCount") }

    if ($positive.Count -lt 3) { $notes.Add('needs at least 3 positives') }
    if ($negative.Count -lt 2) { $notes.Add('needs at least 2 negatives') }
    if ($avgWords -lt 7) { $notes.Add(('short average input length: {0:n1}' -f $avgWords)) }
    if ($overlap -lt 3) { $notes.Add("low trigger vocabulary overlap: $overlap") }
    if ($hardNegatives -lt 2) { $notes.Add("needs stronger adjacent negatives: $hardNegatives") }

    $score = [Math]::Max(0, [Math]::Min(10, $score))
    return [pscustomobject]@{
        score = [Math]::Round($score, 1)
        positive_count = $positive.Count
        negative_count = $negative.Count
        scenario_count = $Eval.scenarios.Count
        avg_words = [Math]::Round($avgWords, 1)
        trigger_overlap = $overlap
        hard_negatives = $hardNegatives
        notes = @($notes)
    }
}

function Invoke-EvalAudit {
    param([string]$RepoRoot = (Get-RepoRoot), [double]$MinimumScore = 7.0)
    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($file in Get-EvalFiles -RepoRoot $RepoRoot) {
        $eval = Parse-EvalFile -Path $file.FullName -RepoRoot $RepoRoot
        $assetText = Get-ReferencedAssetText -RepoRoot $RepoRoot -SkillPath $eval.skill
        $specificity = Get-EvalSpecificity -Eval $eval -AssetText $assetText
        $relative = $eval.path
        $skillExists = $false
        if ($eval.skill) {
            $skillFull = Join-Path $RepoRoot ($eval.skill -replace '/', [System.IO.Path]::DirectorySeparatorChar)
            $skillExists = Test-Path -LiteralPath $skillFull
        }
        $results.Add([pscustomobject]@{
            path = $relative
            name = $eval.name
            target = $eval.skill
            target_exists = $skillExists
            score = $specificity.score
            scenario_count = $specificity.scenario_count
            positive_count = $specificity.positive_count
            negative_count = $specificity.negative_count
            avg_words = $specificity.avg_words
            trigger_overlap = $specificity.trigger_overlap
            hard_negatives = $specificity.hard_negatives
            below_threshold = ($specificity.score -lt $MinimumScore)
            parse_errors = @($eval.parse_errors)
            notes = @($specificity.notes)
        })
    }
    return @($results | Sort-Object score, path)
}


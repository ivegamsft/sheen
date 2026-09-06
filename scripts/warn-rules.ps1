#!/usr/bin/env pwsh
# warn-rules.ps1 — Spec 05 §2.2 warn-level design-system rules
#
# Rules (all warn, never fail — use checks.json error rules for hard gates):
#   W01 token-budget     Each semantic tier file should have ≤ 120 tokens
#   W02 description-overlap  Agent descriptions must contain USE FOR / DO NOT USE FOR
#   W03 skill-body-size  SKILL.md body should be ≤ 500 tokens (~2500 chars)
#   W04 aria-keyboard    Positive accessibility scenarios need a resolved specialist
#                        pairing or accessibility-auditor composition
#   W05 eval-coverage    Skills without a neg-adjacent-domain scenario
#
# Usage: pwsh scripts/warn-rules.ps1 [-RepoRoot <source-or-consumer-root>]
# Exits 0 always; warnings printed to stdout (::warning:: in CI).

param([string]$RepoRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

. (Join-Path $PSScriptRoot 'eval-routing-lib.ps1')
$IsCI = $env:GITHUB_ACTIONS -eq 'true'
if (-not $RepoRoot) { $RepoRoot = Get-RepoRoot }
$repoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
# Auto-detect consumer repo: if .sheen/manifest.json present, use consumer asset paths (#87)
$IsConsumer = Test-Path (Join-Path $repoRoot '.sheen' 'manifest.json')
$warnings = 0

function Warn([string]$Rule, [string]$Path, [string]$Msg) {
    $script:warnings++
    if ($IsCI) { Write-Host "::warning file=${Path}::[$Rule] $Msg" }
    else       { Write-Host "[warn/$Rule] $Path : $Msg" }
}
function Info([string]$Msg) { Write-Host "  $Msg" }

$skillsDir = if ($IsConsumer) { Join-Path $repoRoot '.github/skills' } else { Join-Path $repoRoot 'skills' }
$agentsDir = if ($IsConsumer) { Join-Path $repoRoot '.github/agents' } else { Join-Path $repoRoot 'agents' }
$skillFiles = @()
$evalFiles = @()
$agentFiles = @()
if ($IsConsumer) {
    # A consumer can also contain BaseCoat and local assets; ownership is explicit.
    $manifestText = Get-Content -LiteralPath (Join-Path $repoRoot '.sheen/manifest.json') -Raw
    $manifest = if (-not [string]::IsNullOrWhiteSpace($manifestText) -and (Test-Json -Json $manifestText -ErrorAction SilentlyContinue)) { ConvertFrom-Json -InputObject $manifestText -AsHashtable } else { $null }
    if ($manifest -isnot [System.Collections.IDictionary] -or -not $manifest.Contains('schema') -or -not $manifest.Contains('files') -or $manifest.schema -ne 'sheen-manifest/v1' -or $manifest.files -isnot [array]) {
        Warn 'W04' '.sheen/manifest.json' 'aria-keyboard: invalid ownership manifest; skill/agent scope cannot be evaluated.'
    } else {
        foreach ($path in $manifest.files | Sort-Object -Unique) {
            if ($path -isnot [string]) {
                Warn 'W04' '.sheen/manifest.json' 'aria-keyboard: ownership files must contain path strings.'
                continue
            }
            $path = $path.Replace('\', '/')
            if ($path -notmatch '^\.github/(skills/[a-z0-9-]+/(SKILL\.md|eval\.yaml)|agents/[a-z0-9-]+\.agent\.md)$') { continue }
            $full = Join-Path $repoRoot $path
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
                Warn 'W04' $path 'aria-keyboard: manifest-owned routing asset is missing.'
                continue
            }
            $file = Get-Item -LiteralPath $full
            if ($path.EndsWith('/SKILL.md')) { $skillFiles += $file }
            elseif ($path.EndsWith('/eval.yaml')) { $evalFiles += $file }
            else { $agentFiles += $file }
        }
    }
} else {
    if (Test-Path -LiteralPath $skillsDir) {
        foreach ($dir in Get-ChildItem -LiteralPath $skillsDir -Directory) {
            $skill = Join-Path $dir.FullName 'SKILL.md'
            $eval = Join-Path $dir.FullName 'eval.yaml'
            if (Test-Path -LiteralPath $skill -PathType Leaf) { $skillFiles += Get-Item -LiteralPath $skill }
            if (Test-Path -LiteralPath $eval -PathType Leaf) { $evalFiles += Get-Item -LiteralPath $eval }
        }
    }
    if (Test-Path -LiteralPath $agentsDir) { $agentFiles = @(Get-ChildItem -LiteralPath $agentsDir -Filter '*.agent.md' -File) }
}

# W01 — token-budget: semantic tier files should have ≤ 120 tokens
$semanticDir = if ($IsConsumer) { Join-Path $repoRoot 'sheen/tokens/semantic' } else { Join-Path $repoRoot 'tokens/semantic' }
if (Test-Path $semanticDir) {
    foreach ($f in Get-ChildItem $semanticDir -Filter '*.tokens.json') {
        $content = Get-Content -Raw $f.FullName
        $tokenCount = ([regex]::Matches($content, '"\$type"')).Count
        if ($tokenCount -gt 120) {
            Warn 'W01' (Resolve-Path -Relative $f.FullName) "token-budget: $tokenCount tokens (> 120 recommended). Consider splitting."
        }
    }
    Info "W01 token-budget: $(Get-ChildItem $semanticDir -Filter '*.tokens.json' | Measure-Object | Select-Object -ExpandProperty Count) semantic file(s) checked"
}

# W02 — description-overlap: agent descriptions must have USE FOR / DO NOT USE FOR
if (Test-Path $agentsDir) {
    foreach ($f in $agentFiles) {
        $fm = Get-Content $f.FullName | Select-Object -First 20
        $desc = ($fm | Select-String 'description:') -replace '.*description:\s*"?','' -replace '"?\s*$',''
        if ($desc -and ($desc -notmatch 'USE FOR:' -or $desc -notmatch 'DO NOT USE FOR:')) {
            Warn 'W02' (Resolve-Path -Relative $f.FullName) "description-overlap: missing USE FOR / DO NOT USE FOR in description field"
        }
    }
    Info "W02 description-overlap: $($agentFiles.Count) agent(s) checked"
}

# W03 — skill-body-size: SKILL.md body should be ≤ 500 tokens (~2500 chars)
if (Test-Path $skillsDir) {
    foreach ($f in $skillFiles) {
        $lines = @(Get-Content $f.FullName)
        # Strip frontmatter
        $body = if ($lines.Count -gt 2 -and $lines[0].Trim() -eq '---') {
            $closing = $lines | Select-Object -Skip 1 | Select-String '^---$' | Select-Object -First 1
            $end = if ($closing) { $closing.LineNumber } else { $null }
            if ($end) { $lines | Select-Object -Skip ($end + 1) } else { $lines }
        } else { $lines }
        $chars = ($body -join "`n").Length
        if ($chars -gt 2500) {
            Warn 'W03' (Resolve-Path -Relative $f.FullName) "skill-body-size: body is ~$chars chars (> 2500 / ~500-token recommended). Move examples to templates/."
        }
    }
    $skillCount = $skillFiles.Count
    Info "W03 skill-body-size: $skillCount SKILL.md file(s) checked"
}

# W04 — aria-keyboard: resolve declared relationships, not raw keyword co-occurrence.
if (Test-Path $skillsDir) {
    $knownSkills = @{}
    foreach ($f in $skillFiles) {
        $content = Get-Content -LiteralPath $f.FullName -Raw
        $fm = Get-AssetFrontmatter $content
        if ($fm -match '(?m)^name:[ \t]*(.+?)\r?$' -and (ConvertTo-PlainYamlValue $Matches[1]) -ceq $f.Directory.Name) {
            $knownSkills[$f.Directory.Name] = $content
        }
    }
    $auditor = @($agentFiles | Where-Object Name -CEQ 'accessibility-auditor.agent.md')
    $specialists = @()
    $auditorExists = $false
    if ($auditor.Count -eq 1) {
        $content = Get-Content -LiteralPath $auditor[0].FullName -Raw
        $fm = Get-AssetFrontmatter $content
        $auditorExists = $fm -match '(?m)^name:[ \t]*(.+?)\r?$' -and (ConvertTo-PlainYamlValue $Matches[1]) -ceq 'accessibility-auditor'
        if ($auditorExists) { $specialists = @(Get-AgentComposedSkills $content | Where-Object { $knownSkills.ContainsKey($_) }) }
    }
    foreach ($f in $evalFiles) {
        $eval = Parse-EvalFile -Path $f.FullName -RepoRoot $repoRoot
        $path = [IO.Path]::GetRelativePath($repoRoot, $f.FullName)
        if ($eval.parse_errors.Count -gt 0 -or $eval.scenarios.Count -eq 0) {
            Warn 'W04' $path "aria-keyboard: routing evidence cannot be parsed ($($eval.parse_errors -join '; ')); provide supported scenarios."
            continue
        }
        $positive = @($eval.scenarios | Where-Object { $_.expect_activation -eq $true -and $_.input -imatch '\b(aria|keyboard|screen.reader|focus.ring)\b' })
        if ($positive.Count -eq 0) { continue }
        $name = $f.Directory.Name
        $expected = "skills/$name/SKILL.md"
        $reference = ([string]$eval.skill).Replace('\', '/')
        if (($reference -cne $expected -and (-not $IsConsumer -or $reference -cne ".github/$expected")) -or -not $knownSkills.ContainsKey($name)) {
            Warn 'W04' $path 'aria-keyboard: positive accessibility scenario has a missing, invalid or mismatched skill reference.'
            continue
        }
        $pairs = @(Get-AssetDelegates $knownSkills[$name] -IncludeLegacyPairing)
        $resolved = $specialists -contains $name -or @($pairs | Where-Object { $specialists -contains $_ }).Count -gt 0 -or ($auditorExists -and $pairs -contains 'accessibility-auditor')
        if (-not $resolved) {
            Warn 'W04' $path "aria-keyboard: positive scenario(s) [$($positive.id -join ', ')] have no resolved accessibility-auditor composition or direct specialist pairing. Verify routing."
        }
    }
    Info "W04 aria-keyboard: $($evalFiles.Count) owned eval file(s) checked; negative scenarios are anti-triggers, not handoffs"
}

# W05 — eval-coverage: skills without a hard negative (adjacent-domain) scenario
if (Test-Path $skillsDir) {
    foreach ($f in $evalFiles) {
        $content = Get-Content -Raw $f.FullName
        $negCount = ([regex]::Matches($content, 'expect_activation:\s*false')).Count
        if ($negCount -lt 2) {
            Warn 'W05' (Resolve-Path -Relative $f.FullName) "eval-coverage: only $negCount negative scenario(s). Add ≥1 adjacent-domain negative."
        }
    }
    Info "W05 eval-coverage: eval coverage checked"
}

Write-Host "warn-rules: $warnings warning(s) emitted."
exit 0

#!/usr/bin/env pwsh
# warn-rules.ps1 — Spec 05 §2.2 warn-level design-system rules
#
# Rules (all warn, never fail — use checks.json error rules for hard gates):
#   W01 token-budget     Each semantic tier file should have ≤ 120 tokens
#   W02 description-overlap  Agent descriptions must contain USE FOR / DO NOT USE FOR
#   W03 skill-body-size  SKILL.md body should be ≤ 500 tokens (~2000 chars)
#   W04 aria-keyboard    Skill evals referencing 'aria' or 'keyboard' should pair
#                        with accessibility-auditor agent
#   W05 eval-coverage    Skills without a neg-adjacent-domain scenario
#
# Usage: pwsh scripts/warn-rules.ps1
# Exits 0 always; warnings printed to stdout (::warning:: in CI).

param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$IsCI = $env:GITHUB_ACTIONS -eq 'true'
$repoRoot = git rev-parse --show-toplevel 2>$null
# Auto-detect consumer repo: if .sheen/manifest.json present, use consumer asset paths (#87)
$IsConsumer = Test-Path (Join-Path $repoRoot '.sheen' 'manifest.json')
$warnings = 0

function Warn([string]$Rule, [string]$Path, [string]$Msg) {
    $script:warnings++
    if ($IsCI) { Write-Host "::warning file=${Path}::[$Rule] $Msg" }
    else       { Write-Host "[warn/$Rule] $Path : $Msg" }
}
function Info([string]$Msg) { Write-Host "  $Msg" }

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
$agentsDir = if ($IsConsumer) { Join-Path $repoRoot '.github/agents' } else { Join-Path $repoRoot 'agents' }
if (Test-Path $agentsDir) {
    foreach ($f in Get-ChildItem $agentsDir -Filter '*.agent.md') {
        $fm = Get-Content $f.FullName | Select-Object -First 20
        $desc = ($fm | Select-String 'description:') -replace '.*description:\s*"?','' -replace '"?\s*$',''
        if ($desc -and ($desc -notmatch 'USE FOR:' -or $desc -notmatch 'DO NOT USE FOR:')) {
            Warn 'W02' (Resolve-Path -Relative $f.FullName) "description-overlap: missing USE FOR / DO NOT USE FOR in description field"
        }
    }
    Info "W02 description-overlap: $(Get-ChildItem $agentsDir -Filter '*.agent.md' | Measure-Object | Select-Object -ExpandProperty Count) agent(s) checked"
}

# W03 — skill-body-size: SKILL.md body should be ≤ 500 tokens (~2000 chars)
$skillsDir = if ($IsConsumer) { Join-Path $repoRoot '.github/skills' } else { Join-Path $repoRoot 'skills' }
if (Test-Path $skillsDir) {
    foreach ($f in Get-ChildItem $skillsDir -Recurse -Filter 'SKILL.md') {
        $lines = Get-Content $f.FullName
        # Strip frontmatter
        $body = if ($lines.Count -gt 2 -and $lines[0].Trim() -eq '---') {
            $end = ($lines | Select-Object -Skip 1 | Select-String -List '^---').LineNumber
            if ($end) { $lines | Select-Object -Skip ($end + 1) } else { $lines }
        } else { $lines }
        $chars = ($body -join "`n").Length
        if ($chars -gt 2500) {
            Warn 'W03' (Resolve-Path -Relative $f.FullName) "skill-body-size: body is ~$chars chars (> 2500 / ~500-token recommended). Move examples to templates/."
        }
    }
    $skillCount = (Get-ChildItem $skillsDir -Recurse -Filter 'SKILL.md' | Measure-Object).Count
    Info "W03 skill-body-size: $skillCount SKILL.md file(s) checked"
}

# W04 — aria-keyboard: evals referencing aria/keyboard should pair with accessibility-auditor
if (Test-Path $skillsDir) {
    foreach ($f in Get-ChildItem $skillsDir -Recurse -Filter 'eval.yaml') {
        $content = Get-Content -Raw $f.FullName
        if ($content -imatch '\b(aria|keyboard|screen.reader|focus.ring)\b') {
            if ($content -notmatch 'accessibility-auditor') {
                Warn 'W04' (Resolve-Path -Relative $f.FullName) "aria-keyboard: eval references aria/keyboard terms but agent is not accessibility-auditor. Verify routing."
            }
        }
    }
    Info "W04 aria-keyboard: eval files checked for aria/keyboard routing alignment"
}

# W05 — eval-coverage: skills without a hard negative (adjacent-domain) scenario
if (Test-Path $skillsDir) {
    foreach ($f in Get-ChildItem $skillsDir -Recurse -Filter 'eval.yaml') {
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

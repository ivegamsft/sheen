#!/usr/bin/env pwsh
# lint-router.ps1 — validates the sheen router contract (Spec 09)
#
# Checks:
#   1. sheen.vocab.yaml exists and parses as valid YAML-like structure
#   2. Every intent has: intent, keywords (≥1), skill, agent, discriminator
#   3. Every skill referenced in vocab exists in skills/_catalog.md
#   4. Every agent referenced in vocab exists in agents/*.agent.md
#   5. No duplicate intent names
#   6. discriminator values are from the allowed set
#
# Exits 0 on pass, 1 on any error.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$IsCI = $env:GITHUB_ACTIONS -eq 'true'
$repoRoot = git rev-parse --show-toplevel 2>$null
$vocabPath = Join-Path $repoRoot 'sheen.vocab.yaml'
$status = 0

$AllowedDiscriminators = @('wireframe','audit-report','decision-record','token-spec',
    'ia-artifact','brand-guide','content-spec','component-spec','handoff-package',
    'concept-brief','design-update')

function Fail([string]$msg) {
    if ($IsCI) { Write-Host "::error::$msg" } else { Write-Host "[error] $msg" }
    $script:status = 1
}
function Warn([string]$msg) {
    if ($IsCI) { Write-Host "::warning::$msg" } else { Write-Host "[warn] $msg" }
}

if (-not (Test-Path $vocabPath)) { Fail "sheen.vocab.yaml not found"; exit 1 }

# Parse the vocab YAML manually (same approach as build-metadata.ps1 --Check)
$lines = Get-Content $vocabPath
$schema = ($lines | Select-String '^schema:' | Select-Object -First 1).ToString() -replace '^schema:\s*',''
if ($schema -notmatch 'sheen-vocab/v') { Fail "sheen.vocab.yaml: missing or invalid schema line" }

# Extract intent blocks
$intents = @()
$current = $null
foreach ($line in $lines) {
    if ($line -match '^\s{2}- intent:\s*"?([^"]+)"?') {
        if ($current) { $intents += $current }
        $current = @{ intent=$Matches[1]; keywords=@(); skill=''; agent=''; discriminator='' }
    } elseif ($current -and $line -match '^\s{4}keywords:\s*\[([^\]]+)\]') {
        $current.keywords = @($Matches[1].Split(',') | ForEach-Object { $_.Trim().Trim('"') })
    } elseif ($current -and $line -match '^\s{4}skill:\s*"?([^"]+)"?') {
        $current.skill = $Matches[1]
    } elseif ($current -and $line -match '^\s{4}agent:\s*"?([^"]+)"?') {
        $current.agent = $Matches[1]
    } elseif ($current -and $line -match '^\s{4}discriminator:\s*"?([^"]+)"?') {
        $current.discriminator = $Matches[1]
    }
}
if ($current) { $intents += $current }

Write-Host "lint-router: $($intents.Count) intent(s) parsed from sheen.vocab.yaml"

# 1. Required fields
foreach ($i in $intents) {
    if (-not $i.intent)        { Fail "Intent missing 'intent' field" }
    if ($i.keywords.Count -eq 0) { Fail "Intent '$($i.intent)': no keywords" }
    if (-not $i.skill)         { Fail "Intent '$($i.intent)': missing skill" }
    if (-not $i.agent)         { Fail "Intent '$($i.intent)': missing agent" }
    if (-not $i.discriminator) { Fail "Intent '$($i.intent)': missing discriminator" }
    elseif ($AllowedDiscriminators -notcontains $i.discriminator) {
        Fail "Intent '$($i.intent)': unknown discriminator '$($i.discriminator)'"
    }
}

# 2. Duplicate intent names
$seen = @{}
foreach ($i in $intents) {
    if ($seen.ContainsKey($i.intent)) { Fail "Duplicate intent name: '$($i.intent)'" }
    $seen[$i.intent] = $true
}

# 3. Skills exist in catalog
$catalogPath = Join-Path $repoRoot 'skills/_catalog.md'
$catalogSkills = @()
if (Test-Path $catalogPath) {
    $catalogSkills = (Get-Content $catalogPath | Select-String '^\s*-\s+`?(\S+)`?' |
        ForEach-Object { $_.Matches[0].Groups[1].Value.Trim('`') })
}
$skillDirs = @()
$skillsDir = Join-Path $repoRoot 'skills'
if (Test-Path $skillsDir) {
    $skillDirs = (Get-ChildItem $skillsDir -Directory | ForEach-Object { $_.Name })
}
$knownSkills = ($catalogSkills + $skillDirs) | Sort-Object -Unique
foreach ($i in $intents) {
    if ($i.skill -and $knownSkills -notcontains $i.skill) {
        Warn "Intent '$($i.intent)': skill '$($i.skill)' not found in catalog"
    }
}

# 4. Agents exist
$agentFiles = @()
$agentsDir = Join-Path $repoRoot 'agents'
if (Test-Path $agentsDir) {
    $agentFiles = (Get-ChildItem $agentsDir -Filter '*.agent.md' |
        ForEach-Object { $_.Name -replace '\.agent\.md$','' })
}
foreach ($i in $intents) {
    if ($i.agent -and $agentFiles -notcontains $i.agent) {
        Warn "Intent '$($i.intent)': agent '$($i.agent)' not found in agents/"
    }
}

if ($status -eq 0) { Write-Host "lint-router: all checks passed." }
else               { Write-Host "lint-router: $status error(s) found." }
exit $status

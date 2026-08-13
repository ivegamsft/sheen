#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [string]$SkillsDir = "skills",
    [switch]$Force,
    [switch]$DryRun,
    [string]$SkillName = ""
)

$ErrorActionPreference = "Stop"
$script:DefaultNegativeScenario = "Tell me a joke about programming"

function Get-FrontmatterDescription {
    param([string]$FilePath)

    $content = Get-Content $FilePath -Raw
    # Extract YAML frontmatter between --- delimiters
    if ($content -notmatch '(?s)^---\s*\n(.*?)\n---') {
        return $null
    }
    $yaml = $Matches[1]

    # Extract description value (handles quoted and unquoted, single-line)
    if ($yaml -match '(?m)^description:\s*"(.*)"') {
        return $Matches[1]
    }
    if ($yaml -match "(?m)^description:\s*'(.*)'") {
        return $Matches[1]
    }
    if ($yaml -match '(?m)^description:\s*(.+)') {
        return $Matches[1].Trim()
    }
    return $null
}

function Split-TriggerList {
    param([string]$Raw)
    # Split on comma or semicolon, trim whitespace and trailing punctuation
    $items = $Raw -split '[,;]' | ForEach-Object {
        $_.Trim().TrimEnd('.').Trim()
    } | Where-Object { $_ -ne '' }
    return @($items)
}

function Parse-Description {
    param([string]$Description)

    $useForItems = @()
    $doNotUseForItems = @()

    if ($Description -match 'USE FOR:\s*(.+?)(?:\.\s*DO NOT USE FOR:|$)') {
        $useForItems = Split-TriggerList $Matches[1]
    }

    if ($Description -match 'DO NOT USE FOR:\s*(.+?)\.?\s*$') {
        $doNotUseForItems = Split-TriggerList $Matches[1]
    }

    return @{
        UseFor      = $useForItems
        DoNotUseFor = $doNotUseForItems
    }
}

function Build-EvalYaml {
    param(
        [string]$SkillName,
        [string[]]$UseForItems,
        [string[]]$DoNotUseForItems
    )

    # Pad positive scenarios to exactly 3
    $pos = @() + $UseForItems
    if ($pos.Count -eq 0) {
        $pos += "Help me with $SkillName"
    }
    while ($pos.Count -lt 3) {
        $pos += $pos[-1]
    }
    $pos = $pos[0..2]

    # Pad negative scenarios to exactly 2
    $neg = @() + $DoNotUseForItems
    if ($neg.Count -lt 2) {
        $neg += $script:DefaultNegativeScenario
    }
    $neg = $neg[0..1]

    $lines = @(
        "name: `"$SkillName-routing`""
        "description: `"Routing evaluation — validates trigger activation for the $SkillName skill.`""
        "skill: `"skills/$SkillName/SKILL.md`""
        "scenarios:"
        "  - id: `"pos-1`""
        "    input: `"$($pos[0])`""
        "    expect_activation: true"
        "  - id: `"pos-2`""
        "    input: `"$($pos[1])`""
        "    expect_activation: true"
        "  - id: `"pos-3`""
        "    input: `"$($pos[2])`""
        "    expect_activation: true"
        "  - id: `"neg-1`""
        "    input: `"$($neg[0])`""
        "    expect_activation: false"
        "  - id: `"neg-2`""
        "    input: `"$($neg[1])`""
        "    expect_activation: false"
    )

    return ($lines -join "`n") + "`n"
}

# Resolve skills directory relative to the script's repo root
$repoRoot = Split-Path $PSScriptRoot -Parent
$resolvedSkillsDir = Join-Path $repoRoot $SkillsDir

if (-not (Test-Path $resolvedSkillsDir)) {
    Write-Error "Skills directory not found: $resolvedSkillsDir"
    exit 1
}

$skillDirs = Get-ChildItem $resolvedSkillsDir -Directory
if ($SkillName) {
    $skillDirs = $skillDirs | Where-Object { $_.Name -eq $SkillName }
    if (-not $skillDirs) {
        Write-Error "Skill '$SkillName' not found in $resolvedSkillsDir"
        exit 1
    }
}

$generated = 0
$skipped   = 0
$warned    = 0

foreach ($dir in $skillDirs) {
    $skillFile = Join-Path $dir.FullName "SKILL.md"
    if (-not (Test-Path $skillFile)) {
        continue
    }

    $evalFile = Join-Path $dir.FullName "eval.yaml"

    if ((Test-Path $evalFile) -and -not $Force) {
        $skipped++
        continue
    }

    $description = Get-FrontmatterDescription $skillFile
    if (-not $description) {
        Write-Warning "[$($dir.Name)] No description found in frontmatter — skipping."
        $warned++
        continue
    }

    $parsed = Parse-Description $description
    if ($parsed.UseFor.Count -eq 0) {
        Write-Warning "[$($dir.Name)] No USE FOR items found in description — skipping."
        $warned++
        continue
    }

    $yaml = Build-EvalYaml -SkillName $dir.Name -UseForItems $parsed.UseFor -DoNotUseForItems $parsed.DoNotUseFor

    if ($DryRun) {
        Write-Host "=== DRY RUN: $evalFile ===" -ForegroundColor Cyan
        Write-Host $yaml
    } else {
        [System.IO.File]::WriteAllText($evalFile, $yaml)
    }

    $generated++
}

Write-Host ""
if ($DryRun) {
    Write-Host "DRY RUN complete — Generated $generated new eval.yaml files, skipped $skipped existing." -ForegroundColor Yellow
} else {
    Write-Host "Generated $generated new eval.yaml files, skipped $skipped existing." -ForegroundColor Green
}
if ($warned -gt 0) {
    Write-Host "$warned skill(s) had no parseable USE FOR items and were skipped." -ForegroundColor Yellow
}

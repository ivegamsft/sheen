#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Audits BaseCoat assets against vocabulary/syntax guide conventions.

.DESCRIPTION
    Checks agents, skills, instructions, and prompts for consistency with
    `docs/reference/GUIDANCE_VOCABULARY_SYNTAX_GUIDE.md`.
#>
param(
    [string]$OutputDir = 'test-results/audits/vocabulary-syntax'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$outputPath = Join-Path $repoRoot $OutputDir
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}

function Get-FrontmatterAndBody {
    param([string]$Path)
    $content = Get-Content $Path -Raw
    if ($content -match '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)$') {
        return @{
            frontmatter = $Matches[1]
            body = $Matches[2]
        }
    }
    return @{
        frontmatter = ''
        body = $content
    }
}

function Get-Description {
    param([string]$Frontmatter)
    if ($Frontmatter -match '(?m)^description:\s*"([^"]*)"') { return $Matches[1].Trim() }
    if ($Frontmatter -match '(?m)^description:\s*(.+)$') { return $Matches[1].Trim().Trim("'").Trim('"') }
    return ''
}

function Add-Finding {
    param(
        [System.Collections.Generic.List[object]]$List,
        [string]$Category,
        [string]$File,
        [string]$Severity,
        [string]$Rule,
        [string]$Detail
    )
    $List.Add([pscustomobject]@{
        category = $Category
        file = $File
        severity = $Severity
        rule = $Rule
        detail = $Detail
    })
}

$findings = [System.Collections.Generic.List[object]]::new()

# Agents
Get-ChildItem (Join-Path $repoRoot 'agents') -Filter '*.agent.md' -File | ForEach-Object {
    $parsed = Get-FrontmatterAndBody $_.FullName
    $desc = Get-Description $parsed.frontmatter
    $rel = $_.FullName.Replace($repoRoot + '\', '')

    if (-not $desc) {
        Add-Finding $findings 'agent' $rel 'error' 'description' 'missing description'
    } else {
        if ($desc -notmatch '(?i)^use when') {
            Add-Finding $findings 'agent' $rel 'warn' 'voice-use-when' "description should start with 'Use when'"
        }
        if ($desc -notmatch 'USE FOR') {
            Add-Finding $findings 'agent' $rel 'warn' 'trigger-use-for' 'description missing USE FOR trigger'
        }
        if ($desc -notmatch 'DO NOT USE FOR') {
            Add-Finding $findings 'agent' $rel 'warn' 'trigger-do-not-use-for' 'description missing DO NOT USE FOR trigger'
        }
    }

    if ($parsed.body -notmatch '(?im)^##\s+inputs\b') {
        Add-Finding $findings 'agent' $rel 'warn' 'section-inputs' 'missing ## Inputs section'
    }
    if ($parsed.body -notmatch '(?im)^##\s+(workflow|process)\b') {
        Add-Finding $findings 'agent' $rel 'warn' 'section-workflow' 'missing ## Workflow/Process section'
    }
    if ($parsed.body -notmatch '(?im)^##\s+(output|outputs|results|deliverables)\b') {
        Add-Finding $findings 'agent' $rel 'warn' 'section-output' 'missing ## Output/Results/Deliverables section'
    }
    if ($parsed.body -match '(?m)^\s*\*\*[^*]+\*\*\s*$') {
        Add-Finding $findings 'agent' $rel 'warn' 'md036' 'contains bold-as-heading line(s)'
    }
}

# Skills
Get-ChildItem (Join-Path $repoRoot 'skills') -Directory | ForEach-Object {
    $skillFile = Join-Path $_.FullName 'SKILL.md'
    if (-not (Test-Path $skillFile)) { return }
    $parsed = Get-FrontmatterAndBody $skillFile
    $desc = Get-Description $parsed.frontmatter
    $rel = $skillFile.Replace($repoRoot + '\', '')

    if (-not $desc) {
        Add-Finding $findings 'skill' $rel 'error' 'description' 'missing description'
    } else {
        if ($desc -notmatch '(?i)^use when') {
            Add-Finding $findings 'skill' $rel 'warn' 'voice-use-when' "description should start with 'Use when'"
        }
        if ($desc -notmatch 'USE FOR') {
            Add-Finding $findings 'skill' $rel 'warn' 'trigger-use-for' 'description missing USE FOR trigger'
        }
        if ($desc -notmatch 'DO NOT USE FOR') {
            Add-Finding $findings 'skill' $rel 'warn' 'trigger-do-not-use-for' 'description missing DO NOT USE FOR trigger'
        }
    }

    if ($parsed.body -match '(?m)^\s*\*\*[^*]+\*\*\s*$') {
        Add-Finding $findings 'skill' $rel 'warn' 'md036' 'contains bold-as-heading line(s)'
    }
}

# Instructions
Get-ChildItem (Join-Path $repoRoot 'instructions') -Filter '*.instructions.md' -File | ForEach-Object {
    $parsed = Get-FrontmatterAndBody $_.FullName
    $rel = $_.FullName.Replace($repoRoot + '\', '')

    if ($parsed.body -notmatch '(?m)^##\s+') {
        Add-Finding $findings 'instruction' $rel 'warn' 'section-headings' 'no ## headings found'
    }
    if ($parsed.body -match '(?m)^\s*\*\*[^*]+\*\*\s*$') {
        Add-Finding $findings 'instruction' $rel 'warn' 'md036' 'contains bold-as-heading line(s)'
    }
}

# Prompts
Get-ChildItem (Join-Path $repoRoot 'prompts') -Filter '*.prompt.md' -File | ForEach-Object {
    $parsed = Get-FrontmatterAndBody $_.FullName
    $rel = $_.FullName.Replace($repoRoot + '\', '')
    $desc = Get-Description $parsed.frontmatter
    if (-not $desc) {
        Add-Finding $findings 'prompt' $rel 'error' 'description' 'missing description'
    }
}

$jsonFile = Join-Path $outputPath 'vocabulary-syntax-audit.json'
$mdFile = Join-Path $outputPath 'vocabulary-syntax-audit.md'
$findings | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonFile -Encoding UTF8

$summary = $findings | Group-Object category, severity | Sort-Object Name
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Vocabulary/Syntax Audit')
$lines.Add('')
$lines.Add('| Category | Severity | Count |')
$lines.Add('|---|---|---:|')
foreach ($g in $summary) {
    $parts = $g.Name -split ',\s*'
    $lines.Add("| $($parts[0]) | $($parts[1]) | $($g.Count) |")
}
$lines.Add('')
$lines.Add('| Severity | File | Rule | Detail |')
$lines.Add('|---|---|---|---|')
foreach ($f in $findings | Sort-Object severity, category, file) {
    $lines.Add("| $($f.severity) | `$($f.file)` | `$($f.rule)` | $($f.detail) |")
}
$lines | Set-Content -Path $mdFile -Encoding UTF8

Write-Host "Vocabulary/syntax audit complete:"
Write-Host "  - $mdFile"
Write-Host "  - $jsonFile"

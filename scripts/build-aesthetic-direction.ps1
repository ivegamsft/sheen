#!/usr/bin/env pwsh
# build-aesthetic-direction.ps1 — Generate AESTHETIC-DIRECTION.md from sheen
# design values, influence sources, and DTCG tokens.
#
# DESIGN.md (build-design-md.ps1) renders mechanical token facts (exact color
# hex values, font sizes, easing curves) for AI design agents. This script is
# additive to that: it renders the *creative direction* narrative — mood,
# color story, type pairing, spacing rhythm, motion character — so a
# downstream team has a single artifact that answers "what should this
# look/feel like" instead of synthesizing it themselves from tokens plus
# docs/design-context.md's review rubric. It intentionally excludes any
# reporting/analytics chart guidance — this is a creative-direction doc, not
# a metrics doc.
#
# Usage:
#   pwsh scripts/build-aesthetic-direction.ps1                      # auto-detect paths
#   pwsh scripts/build-aesthetic-direction.ps1 -Theme dark          # use dark theme
#   pwsh scripts/build-aesthetic-direction.ps1 -Out path/AESTHETIC-DIRECTION.md
#   pwsh scripts/build-aesthetic-direction.ps1 -Check               # validate existing file

param(
    [string]$Theme  = 'light',
    [string]$Out    = '',
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { throw 'Run this inside a git repository' }

$IsConsumer = Test-Path (Join-Path $repoRoot '.sheen' 'manifest.json')
$TokensBase = if ($IsConsumer) { Join-Path $repoRoot 'sheen/tokens' } else { Join-Path $repoRoot 'tokens' }
$OutPath    = if ($Out) { $Out } else { Join-Path $repoRoot 'AESTHETIC-DIRECTION.md' }
$ContextMd  = Join-Path $repoRoot 'docs' 'design-context.md'

function Get-TokenFile([string]$RelPath) {
    $full = Join-Path $TokensBase $RelPath
    if (-not (Test-Path $full)) { return $null }
    return (Get-Content -LiteralPath $full -Raw | ConvertFrom-Json)
}

$coreColor  = Get-TokenFile 'core/color.tokens.json'
$coreType   = Get-TokenFile 'core/type.tokens.json'
$coreMotion = Get-TokenFile 'core/motion.tokens.json'
$themeFile  = Get-TokenFile "themes/$Theme.tokens.json"
if (-not $themeFile) {
    Write-Warning "build-aesthetic-direction: theme '$Theme' not found; falling back to light"
    $themeFile = Get-TokenFile 'themes/light.tokens.json'
    if (-not $themeFile) { throw "No theme files found in $TokensBase/themes/" }
}

function Get-CoreValue([object]$Root, [string]$DotPath) {
    $parts = $DotPath -split '\.'
    $node  = $Root
    foreach ($p in $parts) {
        if ($null -eq $node) { return $null }
        if ($node -is [System.Collections.IDictionary]) { $node = $node[$p] }
        else {
            $prop = $node.PSObject.Properties[$p]
            $node = if ($prop) { $prop.Value } else { $null }
        }
    }
    if ($null -eq $node) { return $null }
    $val = if ($node -is [System.Collections.IDictionary]) { $node['$value'] }
           else { $node.PSObject.Properties['$value']?.Value }
    return $val
}

function Resolve-Alias([string]$Alias) {
    if ($Alias -notmatch '^\{(.+)\}$') { return $Alias }
    $path = $Matches[1]
    foreach ($root in @($coreColor, $coreType)) {
        if ($null -eq $root) { continue }
        $val = Get-CoreValue $root $path
        if ($null -ne $val) {
            if ($val -is [System.Collections.IEnumerable] -and -not ($val -is [string])) {
                return ($val -join ', ')
            }
            return "$val"
        }
    }
    return $Alias
}

function Get-ThemeColor([string]$Key) {
    if ($null -eq $themeFile) { return '' }
    $node = if ($themeFile -is [System.Collections.IDictionary]) { $themeFile['color'] } else { $themeFile.PSObject.Properties['color']?.Value }
    if ($null -eq $node) { return '' }
    $entry = if ($node -is [System.Collections.IDictionary]) { $node[$Key] } else { $node.PSObject.Properties[$Key]?.Value }
    if ($null -eq $entry) { return '' }
    $val = if ($entry -is [System.Collections.IDictionary]) { $entry['$value'] } else { $entry.PSObject.Properties['$value']?.Value }
    if ($null -ne $val) { return Resolve-Alias "$val" }
    return ''
}

$primary    = Get-ThemeColor 'primary'
$accent     = Get-ThemeColor 'accent'
$background = Get-ThemeColor 'background'
$foreground = Get-ThemeColor 'foreground'
$sans = Resolve-Alias '{type.font-family.sans}'
$mono = Resolve-Alias '{type.font-family.mono}'

function Get-Duration([string]$Key) {
    if ($null -eq $coreMotion) { return '' }
    $val = Get-CoreValue $coreMotion "motion.duration.$Key"
    if ($null -ne $val) { return "$val" }
    return ''
}
$normalDuration = Get-Duration 'normal'
$slowDuration   = Get-Duration 'slow'

# ── Parse docs/design-context.md's markdown tables ────────────────────────────
function Get-MdTableRows([string[]]$Lines, [string]$SectionHeading) {
    $rows = @()
    $inSection = $false
    $sawHeaderSep = $false
    foreach ($line in $Lines) {
        if ($line -match "^##\s+$([regex]::Escape($SectionHeading))\s*$") { $inSection = $true; $sawHeaderSep = $false; continue }
        if ($inSection -and $line -match '^##\s') { break }
        if (-not $inSection) { continue }
        if ($line -match '^\|\s*-') { $sawHeaderSep = $true; continue }
        if ($line -match '^\|(.+)\|\s*$') {
            $cells = $Matches[1] -split '\|' | ForEach-Object { $_.Trim() }
            if (-not $sawHeaderSep) { continue }  # skip the header row itself
            $rows += , $cells
        }
    }
    return $rows
}

$contextLines = if (Test-Path $ContextMd) { Get-Content -LiteralPath $ContextMd } else { @() }
$valueRows      = Get-MdTableRows $contextLines 'Design values'
$influenceRows  = Get-MdTableRows $contextLines 'Influence sources'

$moodRows = ($valueRows | ForEach-Object {
    $val = ($_[0] -replace '\*\*', '').Trim()
    $meaning = $_[1].Trim()
    "- **$val** — $meaning"
}) -join "`n"

$influenceLines = ($influenceRows | ForEach-Object {
    $src = ($_[0] -replace '\*.*\*', '').Trim()
    $takes = $_[1].Trim()
    "- **$src**: $takes"
}) -join "`n"

$date = (Get-Date -Format 'yyyy-MM-dd')

$fm = @"
name: aesthetic-direction
theme: $Theme
generated: $date
primary: "$primary"
accent: "$accent"
background: "$background"
foreground: "$foreground"
"@

$doc = @"
---
$fm
---

## Overview

The creative direction basecoat-sheen suggests for an application, doc site,
or mobile app built on these tokens — mood, color story, type pairing,
spacing rhythm, and motion character. Additive to
``docs/design-context.md`` (the review rubric this direction is derived
from); regenerate with ``pwsh scripts/build-aesthetic-direction.ps1`` after
any token or design-values change. This is a creative-direction doc, not a
reporting/analytics doc — it does not cover dashboards, funnels, or metrics
visualizations.

## Mood & personality

$moodRows

## Color story

Lead with **``$primary``** (primary) against **``$background``**/**``$foreground``**
for the base surface and text pairing; reserve **``$accent``** for highlights,
premium moments, and tertiary actions — not for default UI chrome. Keep color
usage restrained: color should signal state or hierarchy, not decorate.

## Type pairing

Pair **$sans** for all UI text (headings through captions) with **$mono** for
code and tabular/technical values only. Do not introduce a third typeface —
consistency across the type scale is part of the ``Familiar`` value below.

## Spacing rhythm

A 4px base grid drives a calm, predictable rhythm: dense enough for
information-heavy screens, generous enough that touch targets and reading
lines don't feel cramped. Favor the semantic spacing roles over raw scale
values so rhythm stays consistent as components compose.

## Motion character

Motion is quiet by default (normal transitions ~``$normalDuration``, slower
orchestration ~``$slowDuration``) — it confirms cause and effect, it never
performs. Prefer ease-out entrances and avoid gratuitous overshoot outside of
explicitly playful, low-stakes moments.

## Influences

$influenceLines

## Anti-goals

- Do not add reporting/analytics visual language (charts, dashboards,
  funnels) to this direction — that is a reporting concern, not a creative
  direction, and is handled elsewhere.
- Do not introduce a visual language that contradicts
  ``docs/design-context.md``'s named values or influence sources without
  updating that file first — this document is derived from it, not a
  parallel source of truth.
"@

if ($Check) {
    if (-not (Test-Path $OutPath)) {
        Write-Host "::error::AESTHETIC-DIRECTION.md missing — run: pwsh scripts/build-aesthetic-direction.ps1"
        exit 1
    }
    $existing = (Get-Content -LiteralPath $OutPath -Raw) -replace "`r`n","`n"
    $generated = $doc -replace "`r`n","`n"
    $existingFm = ($existing -split '## Overview')[0]
    $generatedFm = ($generated -split '## Overview')[0]
    if ($existingFm.Trim() -ne $generatedFm.Trim()) {
        Write-Host "::error::AESTHETIC-DIRECTION.md front matter is out of date. Run: pwsh scripts/build-aesthetic-direction.ps1"
        exit 1
    }
    Write-Host "build-aesthetic-direction: AESTHETIC-DIRECTION.md front matter OK"
    exit 0
}

$doc | Set-Content -LiteralPath $OutPath -Encoding utf8 -NoNewline
Write-Host "build-aesthetic-direction: wrote AESTHETIC-DIRECTION.md ($Theme theme) -> $OutPath"

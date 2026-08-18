#!/usr/bin/env pwsh
# build-design-md.ps1 — Generate DESIGN.md (Stitch/Google format) from sheen DTCG tokens
#
# Reads the resolved light theme token values and produces a DESIGN.md file
# at the repository root (or specified output path) in the format understood
# by Google Stitch, Cursor, Claude Code, and other AI design agents.
#
# Usage:
#   pwsh scripts/build-design-md.ps1                      # auto-detect paths
#   pwsh scripts/build-design-md.ps1 -Theme dark          # use dark theme
#   pwsh scripts/build-design-md.ps1 -Out path/DESIGN.md  # custom output path
#   pwsh scripts/build-design-md.ps1 -Check               # validate existing file
#
# See: https://stitch.withgoogle.com/docs/design-md

param(
    [string]$Theme  = 'light',
    [string]$Out    = '',
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { throw 'Run this inside a git repository' }

# Auto-detect consumer repo (same logic as validate-tokens.ps1 / warn-rules.ps1)
$IsConsumer = Test-Path (Join-Path $repoRoot '.sheen' 'manifest.json')
$TokensBase = if ($IsConsumer) { Join-Path $repoRoot 'sheen/tokens' } else { Join-Path $repoRoot 'tokens' }
$OutPath    = if ($Out) { $Out } else { Join-Path $repoRoot 'DESIGN.md' }

function Get-TokenFile([string]$RelPath) {
    $full = Join-Path $TokensBase $RelPath
    if (-not (Test-Path $full)) { return $null }
    return (Get-Content -LiteralPath $full -Raw | ConvertFrom-Json)
}

# Load token files
$coreColor  = Get-TokenFile 'core/color.tokens.json'
$coreType   = Get-TokenFile 'core/type.tokens.json'
$coreRadius = Get-TokenFile 'core/radius.tokens.json'
$coreSpace  = Get-TokenFile 'core/space.tokens.json'
$themeFile  = Get-TokenFile "themes/$Theme.tokens.json"

if (-not $themeFile) {
    Write-Warning "build-design-md: theme '$Theme' not found in $TokensBase/themes/; falling back to light"
    $themeFile = Get-TokenFile 'themes/light.tokens.json'
    if (-not $themeFile) { throw "No theme files found in $TokensBase/themes/" }
}

# ── Helper: read a $value from a deep path like 'type.font-family.sans' ──────
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
    # If it's a token node, return its $value
    $val = if ($node -is [System.Collections.IDictionary]) { $node['$value'] }
           else { $node.PSObject.Properties['$value']?.Value }
    return $val
}

# ── Helper: resolve a DTCG alias '{path.to.token}' against the core files ────
function Resolve-Alias([string]$Alias) {
    if ($Alias -notmatch '^\{(.+)\}$') { return $Alias }
    $path = $Matches[1]
    foreach ($root in @($coreColor, $coreType, $coreRadius, $coreSpace)) {
        if ($null -eq $root) { continue }
        $val = Get-CoreValue $root $path
        if ($null -ne $val) { return "$val" }
    }
    return $Alias  # return unresolved if not found
}

# ── Helper: read a theme color value ─────────────────────────────────────────
function Get-ThemeColor([string]$Key) {
    if ($null -eq $themeFile) { return '' }
    $node = $null
    if ($themeFile -is [System.Collections.IDictionary]) { $node = $themeFile['color'] }
    else { $node = $themeFile.PSObject.Properties['color']?.Value }
    if ($null -eq $node) { return '' }
    $entry = if ($node -is [System.Collections.IDictionary]) { $node[$Key] }
             else { $node.PSObject.Properties[$Key]?.Value }
    if ($null -eq $entry) { return '' }
    $val = if ($entry -is [System.Collections.IDictionary]) { $entry['$value'] }
           else { $entry.PSObject.Properties['$value']?.Value }
    if ($null -ne $val) { return Resolve-Alias "$val" }
    return ''
}

# ── Collect values ────────────────────────────────────────────────────────────
$colors = [ordered]@{
    primary    = Get-ThemeColor 'primary'
    secondary  = Get-ThemeColor 'secondary'
    background = Get-ThemeColor 'background'
    foreground = Get-ThemeColor 'foreground'
    muted      = Get-ThemeColor 'muted'
    border     = Get-ThemeColor 'border'
    error      = Get-ThemeColor 'error'
    success    = Get-ThemeColor 'success'
    warning    = Get-ThemeColor 'warning'
    accent     = Get-ThemeColor 'accent'
}

$sans = Resolve-Alias '{type.font-family.sans}'
$mono = Resolve-Alias '{type.font-family.mono}'

# Resolve font sizes from core scale
function Get-Size([string]$Key) { return Resolve-Alias "{type.font-size.$Key}" }

$typography = [ordered]@{
    'h1'       = [ordered]@{ fontFamily = $sans; fontSize = (Get-Size '4xl'); fontWeight = '600' }
    'h2'       = [ordered]@{ fontFamily = $sans; fontSize = (Get-Size '3xl'); fontWeight = '600' }
    'h3'       = [ordered]@{ fontFamily = $sans; fontSize = (Get-Size '2xl'); fontWeight = '600' }
    'body'     = [ordered]@{ fontFamily = $sans; fontSize = (Get-Size 'lg');  fontWeight = '400' }
    'body-sm'  = [ordered]@{ fontFamily = $sans; fontSize = (Get-Size 'md');  fontWeight = '400' }
    'label'    = [ordered]@{ fontFamily = $sans; fontSize = (Get-Size 'md');  fontWeight = '500' }
    'caption'  = [ordered]@{ fontFamily = $sans; fontSize = (Get-Size 'sm');  fontWeight = '400' }
    'code'     = [ordered]@{ fontFamily = $mono; fontSize = (Get-Size 'md');  fontWeight = '400' }
}

$rounded = [ordered]@{
    'none'  = Resolve-Alias '{radius.none}'
    'sm'    = Resolve-Alias '{radius.small}'
    'md'    = Resolve-Alias '{radius.medium}'
    'lg'    = Resolve-Alias '{radius.large}'
    'pill'  = Resolve-Alias '{radius.full}'
}

$spacing = [ordered]@{
    'xs' = Resolve-Alias '{space.1}'
    'sm' = Resolve-Alias '{space.2}'
    'md' = Resolve-Alias '{space.4}'
    'lg' = Resolve-Alias '{space.6}'
    'xl' = Resolve-Alias '{space.8}'
}

# ── Read product name from version.json or PRODUCT.md ────────────────────────
$productName = 'basecoat-sheen'
$versionFile = Join-Path $repoRoot 'version.json'
if (Test-Path $versionFile) {
    $vj = Get-Content $versionFile -Raw | ConvertFrom-Json
    if ($vj.name) { $productName = $vj.name }
}

# ── Render YAML front matter ──────────────────────────────────────────────────
function Write-YamlString([string]$v) {
    if ($v -match '[\s:#\[\]{}|>&*!,]') { return """$v""" }
    return $v
}

$fm = [System.Text.StringBuilder]::new()
[void]$fm.AppendLine("name: $(Write-YamlString $productName)")
[void]$fm.AppendLine("theme: $Theme")
[void]$fm.AppendLine("colors:")
foreach ($k in $colors.Keys) {
    if ($colors[$k]) { [void]$fm.AppendLine("  ${k}: `"$($colors[$k])`"") }
}
[void]$fm.AppendLine("typography:")
foreach ($k in $typography.Keys) {
    [void]$fm.AppendLine("  ${k}:")
    foreach ($p in $typography[$k].Keys) {
        [void]$fm.AppendLine("    ${p}: $(Write-YamlString $typography[$k][$p])")
    }
}
[void]$fm.AppendLine("rounded:")
foreach ($k in $rounded.Keys) {
    if ($rounded[$k]) { [void]$fm.AppendLine("  ${k}: $(Write-YamlString $rounded[$k])") }
}
[void]$fm.AppendLine("spacing:")
foreach ($k in $spacing.Keys) {
    if ($spacing[$k]) { [void]$fm.AppendLine("  ${k}: $(Write-YamlString $spacing[$k])") }
}

# ── Read design overview from PRODUCT.md if present ──────────────────────────
$overview = "Design token system for $productName. Generated from DTCG tokens by basecoat-sheen."
$productMd = Join-Path $repoRoot 'PRODUCT.md'
if (Test-Path $productMd) {
    $lines = Get-Content $productMd
    # Extract "Product Purpose" section intro (first non-empty paragraph after heading)
    $inSection = $false
    foreach ($line in $lines) {
        if ($line -match '^## Product Purpose') { $inSection = $true; continue }
        if ($inSection -and $line -match '^## ') { break }
        if ($inSection -and $line.Trim() -ne '' -and $line -notmatch '^#') {
            $overview = $line.Trim()
            break
        }
    }
}

# ── Build final DESIGN.md content ─────────────────────────────────────────────
$date = (Get-Date -Format 'yyyy-MM-dd')
$designMd = @"
---
$($fm.ToString().TrimEnd())
---

## Overview

$overview

Generated from DTCG tokens by basecoat-sheen on $date. Theme: ``$Theme``.
Do not hand-edit — regenerate with ``pwsh scripts/build-design-md.ps1``.

## Colors

| Role | Value | Use |
|------|-------|-----|
| primary | ``$($colors.primary)`` | Primary actions, links, focus rings |
| secondary | ``$($colors.secondary)`` | Secondary surfaces, cards |
| background | ``$($colors.background)`` | Page / canvas background |
| foreground | ``$($colors.foreground)`` | Primary text, icons |
| muted | ``$($colors.muted)`` | Secondary text, captions, placeholders |
| border | ``$($colors.border)`` | Dividers, input borders |
| error | ``$($colors.error)`` | Error states, destructive actions |
| success | ``$($colors.success)`` | Confirmation, success states |
| warning | ``$($colors.warning)`` | Caution, degraded states |
| accent | ``$($colors.accent)`` | Highlight, premium, tertiary actions |

All pairs validated at WCAG 2.2 AA (4.5:1 text / 3:1 large). Theme: ``$Theme``.

## Typography

| Role | Family | Size | Weight |
|------|--------|------|--------|
| h1 | sans | $($typography.h1.fontSize) | $($typography.h1.fontWeight) |
| h2 | sans | $($typography.h2.fontSize) | $($typography.h2.fontWeight) |
| h3 | sans | $($typography.h3.fontSize) | $($typography.h3.fontWeight) |
| body | sans | $($typography.body.fontSize) | $($typography.body.fontWeight) |
| body-sm | sans | $($typography['body-sm'].fontSize) | $($typography['body-sm'].fontWeight) |
| label | sans | $($typography.label.fontSize) | $($typography.label.fontWeight) |
| caption | sans | $($typography.caption.fontSize) | $($typography.caption.fontWeight) |
| code | mono | $($typography.code.fontSize) | $($typography.code.fontWeight) |

Sans: ``$sans``
Mono: ``$mono``

## Spacing

4px base grid. Use semantic spacing roles in components; raw scale for layout only.

| Token | Value |
|-------|-------|
| xs | $($spacing.xs) |
| sm | $($spacing.sm) |
| md | $($spacing.md) |
| lg | $($spacing.lg) |
| xl | $($spacing.xl) |

## Corner Radius

| Token | Value | Use |
|-------|-------|-----|
| none | $($rounded.none) | Flush elements |
| sm | $($rounded.sm) | Chips, tags, table cells |
| md | $($rounded.md) | Buttons, inputs |
| lg | $($rounded.lg) | Cards, dialogs, menus |
| pill | $($rounded.pill) | Badges, toggles |

## Components

Component-level guidance is defined per-skill in the sheen design system.
See: ``.github/skills/`` for component specifications.
Tokens are applied via CSS custom properties in ``sheen/tokens/`` or ``dist/tokens/sheen.css``.
"@

if ($Check) {
    if (-not (Test-Path $OutPath)) {
        Write-Host "::error::DESIGN.md missing — run: pwsh scripts/build-design-md.ps1"
        exit 1
    }
    $existing = (Get-Content -LiteralPath $OutPath -Raw) -replace "`r`n","`n"
    $generated = $designMd -replace "`r`n","`n"
    # Only compare front matter and color table (date line will differ)
    $existingFm = ($existing -split '## Overview')[0]
    $generatedFm = ($generated -split '## Overview')[0]
    if ($existingFm.Trim() -ne $generatedFm.Trim()) {
        Write-Host "::error::DESIGN.md front matter is out of date. Run: pwsh scripts/build-design-md.ps1"
        exit 1
    }
    Write-Host "build-design-md: DESIGN.md front matter OK"
    exit 0
}

$designMd | Set-Content -LiteralPath $OutPath -Encoding utf8 -NoNewline
Write-Host "build-design-md: wrote DESIGN.md ($Theme theme) → $OutPath"

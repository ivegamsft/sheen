#!/usr/bin/env pwsh
# lint-diagram-skins.ps1 — CI lint for the diagram semantic-role adapter (#118)
#
# Ported/adapted from cathrynlavery/diagram-design's `lint-skin` and
# `verify-skin-polarity` scripts (Python originals) to this repo's PS1
# conventions. Runs AFTER scripts/build-diagram-skins.ps1 has produced
# dist/diagram-skins/*.json.
#
# Checks:
#   1. skin        — every required role is present and is a well-formed
#                     #rrggbb hex string (roles resolve, no stray/malformed
#                     values slipped through the adapter).
#   2. polarity     — light/dark inversion holds: `paper` must be the
#                      *lighter* surface and `ink` the *darker* text colour
#                      in the light theme, and inverted in dark/high-contrast
#                      themes; `paper`/`ink` contrast must clear the theme's
#                      accessibility floor (4.5:1 light/dark, 7:1 high-contrast).
#   3. contrast     — `accent`, `rule-solid`, and every `series.N` colour must
#                      clear 3:1 (WCAG non-text minimum) against `paper`.
#
# Usage: pwsh scripts/lint-diagram-skins.ps1 [-SkinsDir <path>] [-Quiet]
# Exits 0 if every theme skin passes all checks, 1 otherwise (prints every
# failing rule with the offending theme/role so CI output is actionable).

param(
    [string]$SkinsDir,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$IsCI = $env:GITHUB_ACTIONS -eq 'true'

$repoRoot = $null
try { $repoRoot = (git rev-parse --show-toplevel 2>$null).Trim() } catch { $repoRoot = $null }
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

if (-not $SkinsDir) { $SkinsDir = Join-Path $repoRoot 'dist' 'diagram-skins' }

function Log([string]$msg) { if (-not $Quiet) { Write-Host $msg } }
function Fail([string]$msg) {
    if ($IsCI) { Write-Host "::error::$msg" } else { Write-Host "FAIL: $msg" -ForegroundColor Red }
    $script:FailCount++
}

$script:FailCount = 0

if (-not (Test-Path $SkinsDir)) {
    Write-Host "::error::Skins dir '$SkinsDir' not found — run scripts/build-diagram-skins.ps1 first"
    exit 1
}

$RequiredRoles = @('paper', 'paper-2', 'ink', 'muted', 'soft', 'rule', 'rule-solid', 'accent', 'accent-tint', 'link')
$HexPattern    = '^#[0-9a-fA-F]{6}$'

# High-contrast theme files (by naming convention) get the stricter 7:1 floor;
# all other themes get the standard 4.5:1 text floor.
function Get-ContrastFloor([string]$themeName) {
    if ($themeName -match 'high-contrast') { return 7.0 }
    return 4.5
}

function Get-Luminance([string]$hex) {
    $hex = $hex.TrimStart('#')
    $r = [Convert]::ToInt32($hex.Substring(0, 2), 16) / 255.0
    $g = [Convert]::ToInt32($hex.Substring(2, 2), 16) / 255.0
    $b = [Convert]::ToInt32($hex.Substring(4, 2), 16) / 255.0
    $lin = @($r, $g, $b) | ForEach-Object {
        if ($_ -le 0.03928) { $_ / 12.92 } else { [Math]::Pow((($_ + 0.055) / 1.055), 2.4) }
    }
    return 0.2126 * $lin[0] + 0.7152 * $lin[1] + 0.0722 * $lin[2]
}

function Get-Contrast([string]$hexA, [string]$hexB) {
    $lA = Get-Luminance $hexA
    $lB = Get-Luminance $hexB
    $lighter = [Math]::Max($lA, $lB)
    $darker  = [Math]::Min($lA, $lB)
    return ($lighter + 0.05) / ($darker + 0.05)
}

$skinFiles = Get-ChildItem $SkinsDir -Filter '*.json' | Where-Object { $_.Name -ne 'skins.json' } | Sort-Object Name
if ($skinFiles.Count -eq 0) { Write-Host "::error::No per-theme skin files found in '$SkinsDir'"; exit 1 }

foreach ($f in $skinFiles) {
    $themeName = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    $skin = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json

    Log "── $themeName ──"

    # ── 1. skin: roles resolve, well-formed hex ──────────────────────────────
    foreach ($role in $RequiredRoles) {
        if (-not ($skin.PSObject.Properties.Name -contains $role)) {
            Fail "[skin] theme '$themeName' is missing role '$role'"
            continue
        }
        $val = $skin.$role
        if ($val -notmatch $HexPattern) {
            Fail "[skin] theme '$themeName' role '$role' is not a well-formed #rrggbb hex value: '$val'"
        }
    }
    if (-not ($skin.PSObject.Properties.Name -contains 'series') -or $skin.series.Count -ne 8) {
        Fail "[skin] theme '$themeName' must have exactly 8 'series' entries"
    } else {
        for ($i = 0; $i -lt $skin.series.Count; $i++) {
            if ($skin.series[$i] -notmatch $HexPattern) {
                Fail "[skin] theme '$themeName' series[$i] is not a well-formed hex value: '$($skin.series[$i])'"
            }
        }
    }

    if ($script:FailCount -gt 0 -and -not ($skin.PSObject.Properties.Name -contains 'paper' -and $skin.PSObject.Properties.Name -contains 'ink')) {
        # Can't run polarity/contrast without paper+ink — skip the rest for this theme.
        continue
    }

    # ── 2. polarity: paper/ink inversion + accessibility floor ───────────────
    $paperL = Get-Luminance $skin.paper
    $inkL   = Get-Luminance $skin.ink
    $isDarkTheme = $themeName -match 'dark' -or $themeName -eq 'high-contrast'
    if ($isDarkTheme) {
        if ($paperL -ge $inkL) {
            Fail "[polarity] theme '$themeName' is a dark theme but 'paper' ($($skin.paper)) is not darker than 'ink' ($($skin.ink))"
        }
    } else {
        if ($paperL -le $inkL) {
            Fail "[polarity] theme '$themeName' is a light theme but 'paper' ($($skin.paper)) is not lighter than 'ink' ($($skin.ink))"
        }
    }
    $floor = Get-ContrastFloor $themeName
    $paperInkContrast = Get-Contrast $skin.paper $skin.ink
    if ($paperInkContrast -lt $floor) {
        Fail ("[polarity] theme '{0}' paper/ink contrast {1:N2}:1 is below the {2}:1 floor" -f $themeName, $paperInkContrast, $floor)
    } else {
        Log ("  [pass] polarity   paper/ink {0:N2}:1 >= {1}:1" -f $paperInkContrast, $floor)
    }

    # ── 3. contrast: accent / rule-solid / series vs paper >= 3:1 ────────────
    $nonTextFloor = 3.0
    foreach ($role in @('accent', 'rule-solid')) {
        $c = Get-Contrast $skin.paper $skin.$role
        if ($c -lt $nonTextFloor) {
            Fail ("[contrast] theme '{0}' role '{1}' vs paper is {2:N2}:1, below {3}:1" -f $themeName, $role, $c, $nonTextFloor)
        } else {
            Log ("  [pass] contrast   {0,-11} vs paper {1:N2}:1 >= {2}:1" -f $role, $c, $nonTextFloor)
        }
    }
    for ($i = 0; $i -lt $skin.series.Count; $i++) {
        $c = Get-Contrast $skin.paper $skin.series[$i]
        if ($c -lt $nonTextFloor) {
            Fail ("[contrast] theme '{0}' series[{1}] vs paper is {2:N2}:1, below {3}:1" -f $themeName, $i, $c, $nonTextFloor)
        } else {
            Log ("  [pass] contrast   series[{0}] vs paper {1:N2}:1 >= {2}:1" -f $i, $c, $nonTextFloor)
        }
    }
}

if ($script:FailCount -gt 0) {
    Write-Host "lint-diagram-skins: $($script:FailCount) failure(s)."
    exit 1
}
Log "lint-diagram-skins: all checks passed."

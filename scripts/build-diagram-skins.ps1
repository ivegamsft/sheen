#!/usr/bin/env pwsh
# build-diagram-skins.ps1 — DTCG tokens -> diagram semantic-role skins (#116)
#
# "Bridge, don't fork" (epic #110, Position C): diagrams (Mermaid/drawio/the
# documentation-diagram renderer in #113) never hard-code hex. This adapter
# resolves the diagram-design semantic roles used by skills/data-visualisation
# and the diagram renderer FROM tokens/themes/*, so a theme switch changes
# diagram skin with zero per-diagram-type edits and zero hex duplicated
# outside tokens/.
#
# Reads tokens/ (core -> semantic -> themes) and emits, per theme:
#   dist/diagram-skins/<theme>.json — { role: "#hex", ... , series: ["#hex", ...] }
#   dist/diagram-skins/skins.json   — all themes combined, keyed by theme name
#
# Role map (diagram role -> semantic token):
#   paper        -> color.background       (canvas backdrop)
#   paper-2      -> color.surface-raised   (panel / lane backdrop, one step up from paper)
#   ink          -> color.foreground       (primary text/line colour)
#   muted        -> color.muted            (secondary text / de-emphasised nodes)
#   soft         -> color.border-muted     (subtle divider / faint gridline)
#   rule         -> color.border-muted     (default divider — alias of `soft`, kept as a
#                                            distinct role name for diagram-design parity)
#   rule-solid   -> color.muted            (stronger divider / swimlane edge — must clear the
#                                            3:1 non-text contrast floor against `paper`, which
#                                            `color.border` does not in this token set; `muted`
#                                            is the nearest role that both reads as a divider
#                                            and clears the floor. Enforced by
#                                            scripts/lint-diagram-skins.ps1, issue #118.)
#   accent       -> color.accent           (emphasis / active-path colour)
#   accent-tint  -> derived: accent blended 25% into paper (a lighter accent wash for
#                   highlighted regions). Computed at build time, not a token, because
#                   no `accent-subtle` semantic token exists yet — avoids introducing a
#                   new token tier just for one derived tint (still zero new hex on disk).
#   link         -> color.link             (cross-reference / edge-to-doc links)
#   series.N     -> color.data.series.N    (1-8, categorical per-lane/per-actor colour)
#
# Usage: pwsh scripts/build-diagram-skins.ps1 [-OutDir <path>] [-TokensDir <path>] [-Quiet]
# Exits 0 on success, 1 if a required semantic token is missing for any theme.

param(
    [string]$OutDir,
    [string]$TokensDir,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$IsCI = $env:GITHUB_ACTIONS -eq 'true'

$repoRoot = $null
try { $repoRoot = (git rev-parse --show-toplevel 2>$null).Trim() } catch { $repoRoot = $null }
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

# Consumer auto-detect (matches scripts/build-tokens.ps1 convention, #92)
$isConsumer = (Test-Path -LiteralPath (Join-Path $repoRoot '.sheen' 'manifest.json')) -or
    (Test-Path -LiteralPath (Join-Path $repoRoot 'sheen' 'tokens'))
if (-not $TokensDir) {
    $TokensDir = if ($isConsumer) {
        Join-Path $repoRoot 'sheen' 'tokens'
    } else {
        Join-Path $repoRoot 'tokens'
    }
}
if (-not $OutDir) {
    $OutDir = Join-Path $repoRoot 'dist' 'diagram-skins'
}

function Log([string]$msg) { if (-not $Quiet) { Write-Host $msg } }
function Err([string]$msg) {
    if ($IsCI) { Write-Host "::error::$msg" } else { Write-Error $msg }
    exit 1
}

# ── flatten + resolve helpers (same semantics as build-tokens.ps1) ───────────

function Get-FlatTokens {
    param([pscustomobject]$Obj, [string]$Prefix = '')
    $out = [ordered]@{}
    foreach ($key in $Obj.PSObject.Properties.Name) {
        if ($key.StartsWith('$')) { continue }
        $val  = $Obj.$key
        $path = if ($Prefix) { "$Prefix.$key" } else { $key }
        if ($null -ne $val -and $val -is [pscustomobject] -and
            $val.PSObject.Properties.Name -contains '$type') {
            $out[$path] = $val
        } elseif ($val -is [pscustomobject]) {
            $nested = Get-FlatTokens -Obj $val -Prefix $path
            foreach ($kv in $nested.GetEnumerator()) { $out[$kv.Key] = $kv.Value }
        }
    }
    return $out
}

function Resolve-Value {
    param([object]$RawValue, [hashtable]$Lookup, [string]$TokenPath, [System.Collections.Generic.HashSet[string]]$Seen)
    if ($RawValue -is [string] -and $RawValue -match '^\{(.+)\}$') {
        $ref = $Matches[1]
        if ($Seen.Contains($ref)) { Err "Cycle detected resolving '$TokenPath' -> '{$ref}'" }
        if (-not $Lookup.ContainsKey($ref)) { Err "Dangling reference '$TokenPath' -> '{$ref}'" }
        $newSeen = [System.Collections.Generic.HashSet[string]]::new([string[]]$Seen)
        $newSeen.Add($ref) | Out-Null
        return Resolve-Value -RawValue $Lookup[$ref].'$value' -Lookup $Lookup -TokenPath $ref -Seen $newSeen
    }
    return $RawValue
}

function Read-Dir([string]$dir) {
    $flat = [ordered]@{}
    if (-not (Test-Path $dir)) { return $flat }
    foreach ($f in Get-ChildItem $dir -Filter '*.tokens.json' | Sort-Object Name) {
        try {
            $obj = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json
        } catch {
            Err "Invalid JSON in '$($f.FullName)': $_"
        }
        $tokens = Get-FlatTokens -Obj $obj
        foreach ($kv in $tokens.GetEnumerator()) { $flat[$kv.Key] = $kv.Value }
    }
    return $flat
}

# Blend two #rrggbb hex colours: $ratio is the weight of $fg (0..1)
function Blend-Hex([string]$fg, [string]$bg, [double]$ratio) {
    $fg = $fg.TrimStart('#'); $bg = $bg.TrimStart('#')
    $fr = [Convert]::ToInt32($fg.Substring(0, 2), 16); $fgg = [Convert]::ToInt32($fg.Substring(2, 2), 16); $fb = [Convert]::ToInt32($fg.Substring(4, 2), 16)
    $br = [Convert]::ToInt32($bg.Substring(0, 2), 16); $bgg = [Convert]::ToInt32($bg.Substring(2, 2), 16); $bb = [Convert]::ToInt32($bg.Substring(4, 2), 16)
    $r = [Math]::Round(($fr * $ratio) + ($br * (1 - $ratio)))
    $g = [Math]::Round(($fgg * $ratio) + ($bgg * (1 - $ratio)))
    $b = [Math]::Round(($fb * $ratio) + ($bb * (1 - $ratio)))
    return ('#{0:x2}{1:x2}{2:x2}' -f [int]$r, [int]$g, [int]$b)
}

# ── load tokens ───────────────────────────────────────────────────────────────

if (-not (Test-Path $TokensDir)) { Err "tokens/ directory not found at '$TokensDir'" }

$CoreFlat     = Read-Dir (Join-Path $TokensDir 'core')
$SemanticFlat = Read-Dir (Join-Path $TokensDir 'semantic')

$BaseFlat = [ordered]@{}
foreach ($kv in $SemanticFlat.GetEnumerator()) { $BaseFlat[$kv.Key] = $kv.Value }
foreach ($kv in $CoreFlat.GetEnumerator())     { $BaseFlat[$kv.Key] = $kv.Value }

$ThemesDir = Join-Path $TokensDir 'themes'
$Themes    = [ordered]@{}
if (Test-Path $ThemesDir) {
    foreach ($f in Get-ChildItem $ThemesDir -Filter '*.tokens.json' | Sort-Object Name) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($f.BaseName)
        try {
            $obj = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json
        } catch {
            Err "Invalid JSON in '$($f.FullName)': $_"
        }
        $Themes[$name] = Get-FlatTokens -Obj $obj
    }
}

if ($Themes.Count -eq 0) { Err "No theme files found under '$ThemesDir'" }

Log "build-diagram-skins: core=$($CoreFlat.Count) semantic=$($SemanticFlat.Count) themes=$($Themes.Count)"

# ── role map: diagram role -> semantic token path ────────────────────────────

$RoleMap = [ordered]@{
    'paper'      = 'color.background'
    'paper-2'    = 'color.surface-raised'
    'ink'        = 'color.foreground'
    'muted'      = 'color.muted'
    'soft'       = 'color.border-muted'
    'rule'       = 'color.border-muted'
    'rule-solid' = 'color.muted'
    'accent'     = 'color.accent'
    'link'       = 'color.link'
}
$SeriesCount = 8

function Resolve-ForTheme([string]$themeName, [hashtable]$themeFlat) {
    $lookup = [ordered]@{}
    foreach ($kv in $BaseFlat.GetEnumerator()) { $lookup[$kv.Key] = $kv.Value }
    foreach ($kv in $themeFlat.GetEnumerator()) { $lookup[$kv.Key] = $kv.Value }

    $skin = [ordered]@{}
    foreach ($role in $RoleMap.Keys) {
        $semanticKey = $RoleMap[$role]
        if (-not $lookup.Contains($semanticKey)) {
            Err "Theme '$themeName' is missing semantic token '$semanticKey' required for diagram role '$role'"
        }
        $seen = [System.Collections.Generic.HashSet[string]]::new()
        $skin[$role] = [string](Resolve-Value -RawValue $lookup[$semanticKey].'$value' -Lookup $lookup -TokenPath $semanticKey -Seen $seen)
    }

    # accent-tint: derived tint, 25% accent blended into paper — not a token (see header)
    $skin['accent-tint'] = Blend-Hex -fg $skin['accent'] -bg $skin['paper'] -ratio 0.25

    $series = @()
    for ($i = 1; $i -le $SeriesCount; $i++) {
        $key = "color.data.series.$i"
        if (-not $lookup.Contains($key)) { Err "Theme '$themeName' is missing '$key' required for diagram series colours" }
        $seen = [System.Collections.Generic.HashSet[string]]::new()
        $series += [string](Resolve-Value -RawValue $lookup[$key].'$value' -Lookup $lookup -TokenPath $key -Seen $seen)
    }
    $skin['series'] = $series

    return $skin
}

$AllSkins = [ordered]@{}
foreach ($themeName in $Themes.Keys) {
    $AllSkins[$themeName] = Resolve-ForTheme -themeName $themeName -themeFlat $Themes[$themeName]
}

# ── emit ──────────────────────────────────────────────────────────────────────

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

foreach ($themeName in $AllSkins.Keys) {
    $path = Join-Path $OutDir "$themeName.json"
    ($AllSkins[$themeName] | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $path -Encoding utf8NoBOM
    Log "  wrote $path"
}

$combinedPath = Join-Path $OutDir 'skins.json'
($AllSkins | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $combinedPath -Encoding utf8NoBOM
Log "  wrote $combinedPath"

Log "build-diagram-skins: done — $($AllSkins.Count) theme skin(s), $($RoleMap.Count + 2) role(s) each"
Log "build-diagram-skins: outputs in $OutDir"

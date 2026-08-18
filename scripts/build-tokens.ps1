#!/usr/bin/env pwsh
# build-tokens.ps1 — DTCG → CSS custom properties + JS/TS ESM (spec 01 §4)
#
# Reads tokens/ (core → semantic → themes), resolves all aliases, and emits:
#   dist/tokens/sheen.css          — CSS :root vars + per-theme [data-theme] overrides
#   dist/tokens/sheen.js           — CommonJS module (for legacy toolchains)
#   dist/tokens/sheen.esm.js       — ES module (tree-shakeable)
#   dist/tokens/sheen.d.ts         — TypeScript declarations
#
# Usage: pwsh scripts/build-tokens.ps1 [-OutDir <path>] [-TokensDir <path>] [-Quiet]
#
# Exits 0 on success, 1 on failure (unresolved ref, cycle, bad JSON).
# Output is reproducible in CI; no network access required.
#
# Consumer auto-detect (#92): when TokensDir/OutDir are omitted, prefer
# sheen/tokens (and dist/tokens) if .sheen/manifest.json or sheen/tokens exists.

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
    $OutDir = Join-Path $repoRoot 'dist' 'tokens'
}

function Log([string]$msg) { if (-not $Quiet) { Write-Host $msg } }
function Err([string]$msg) {
    if ($IsCI) { Write-Host "::error::$msg" } else { Write-Error $msg }
    exit 1
}

# ── helpers ───────────────────────────────────────────────────────────────────

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
        if ($Seen.Contains($ref)) { Err "Cycle detected resolving '$TokenPath' → '{$ref}'" }
        if (-not $Lookup.ContainsKey($ref)) { Err "Dangling reference '$TokenPath' → '{$ref}'" }
        $newSeen = [System.Collections.Generic.HashSet[string]]::new([string[]]$Seen)
        $newSeen.Add($ref) | Out-Null
        return Resolve-Value -RawValue $Lookup[$ref].'$value' -Lookup $Lookup -TokenPath $ref -Seen $newSeen
    }
    return $RawValue
}

# Convert a token path (dot-separated) to a CSS custom property name
function To-CssVar([string]$path) {
    return '--sheen-' + ($path -replace '\.', '-')
}

# Serialise a resolved $value to a CSS string
function Value-ToCss([object]$val, [string]$type) {
    if ($null -eq $val) { return 'unset' }
    switch ($type) {
        'shadow' {
            if ($val -is [pscustomobject]) {
                $x  = $val.offsetX; $y = $val.offsetY; $b = $val.blur; $s = $val.spread; $c = $val.color
                return "$x $y $b $s $c"
            }
            return [string]$val
        }
        'cubicBezier' {
            if ($val -is [array] -or $val -is [System.Collections.IEnumerable]) {
                $pts = @($val) | ForEach-Object { [string]$_ }
                return "cubic-bezier($($pts -join ', '))"
            }
            return [string]$val
        }
        'typography' {
            if ($val -is [pscustomobject]) {
                # Return just the shorthand font value; individual props use sub-vars (not emitted here)
                $fw = if ($val.fontWeight) { $val.fontWeight } else { '' }
                $fs = if ($val.fontSize)   { $val.fontSize   } else { '' }
                $lh = if ($val.lineHeight) { "/$($val.lineHeight)" } else { '' }
                $ff = if ($val.fontFamily) { $val.fontFamily } else { '' }
                return "$fw $fs$lh $ff".Trim()
            }
            return [string]$val
        }
        default {
            if ($val -is [array]) { return ($val | ForEach-Object { [string]$_ }) -join ', ' }
            return [string]$val
        }
    }
}

# Escape a JS string
function Js-Escape([string]$s) { return $s -replace '\\', '\\' -replace "'", "\'" }

# ── load token files ──────────────────────────────────────────────────────────

if (-not (Test-Path $TokensDir)) { Err "tokens/ directory not found at '$TokensDir'" }

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

$CoreFlat     = Read-Dir (Join-Path $TokensDir 'core')
$SemanticFlat = Read-Dir (Join-Path $TokensDir 'semantic')

# Merged lookup for alias resolution (core wins when duplicated)
$BaseFlat = [ordered]@{}
foreach ($kv in $SemanticFlat.GetEnumerator()) { $BaseFlat[$kv.Key] = $kv.Value }
foreach ($kv in $CoreFlat.GetEnumerator())     { $BaseFlat[$kv.Key] = $kv.Value }

# Read themes
$ThemesDir = Join-Path $TokensDir 'themes'
$Themes    = [ordered]@{}
if (Test-Path $ThemesDir) {
    foreach ($f in Get-ChildItem $ThemesDir -Filter '*.tokens.json' | Sort-Object Name) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($f.BaseName)  # strip .tokens
        try {
            $obj = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json
        } catch {
            Err "Invalid JSON in '$($f.FullName)': $_"
        }
        $Themes[$name] = Get-FlatTokens -Obj $obj
    }
}

Log "build-tokens: core=$($CoreFlat.Count) semantic=$($SemanticFlat.Count) themes=$($Themes.Count)"

# ── resolve all semantic tokens ───────────────────────────────────────────────

# Semantic tokens resolve aliases against core only (prevents same-key cycles)
$Resolved = [ordered]@{}
foreach ($kv in $SemanticFlat.GetEnumerator()) {
    $seen = [System.Collections.Generic.HashSet[string]]::new()
    $cssVal = Value-ToCss (Resolve-Value -RawValue $kv.Value.'$value' -Lookup $CoreFlat -TokenPath $kv.Key -Seen $seen) $kv.Value.'$type'
    $Resolved[$kv.Key] = @{ type = $kv.Value.'$type'; cssValue = $cssVal; rawValue = $kv.Value.'$value' }
}

# Resolve theme overrides
$ResolvedThemes = [ordered]@{}
foreach ($themeName in $Themes.Keys) {
    $themeResolved = [ordered]@{}
    $themeFlat     = $Themes[$themeName]
    # Build merged lookup (theme > semantic > core)
    $themeLookup = [ordered]@{}
    foreach ($kv in $BaseFlat.GetEnumerator()) { $themeLookup[$kv.Key] = $kv.Value }
    foreach ($kv in $themeFlat.GetEnumerator()) { $themeLookup[$kv.Key] = $kv.Value }

    foreach ($kv in $themeFlat.GetEnumerator()) {
        $seen = [System.Collections.Generic.HashSet[string]]::new()
        # Resolve aliases against BaseFlat (core+semantic) only — prevents theme self-reference cycles
        $cssVal = Value-ToCss (Resolve-Value -RawValue $kv.Value.'$value' -Lookup $BaseFlat -TokenPath $kv.Key -Seen $seen) $kv.Value.'$type'
        $themeResolved[$kv.Key] = @{ type = $kv.Value.'$type'; cssValue = $cssVal }
    }
    $ResolvedThemes[$themeName] = $themeResolved
}

# ── emit outputs ──────────────────────────────────────────────────────────────

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# ─ CSS ────────────────────────────────────────────────────────────────────────
$css = [System.Text.StringBuilder]::new()
[void]$css.AppendLine("/* sheen.css — generated by scripts/build-tokens.ps1; do not hand-edit */")
[void]$css.AppendLine("/* spec 01 §4: DTCG source → CSS custom properties */")
[void]$css.AppendLine("")
[void]$css.AppendLine(":root {")
foreach ($kv in $Resolved.GetEnumerator()) {
    [void]$css.AppendLine("  $(To-CssVar $kv.Key): $($kv.Value.cssValue);")
}
[void]$css.AppendLine("}")

foreach ($themeName in $ResolvedThemes.Keys) {
    [void]$css.AppendLine("")
    [void]$css.AppendLine("[data-theme=""$themeName""] {")
    foreach ($kv in $ResolvedThemes[$themeName].GetEnumerator()) {
        [void]$css.AppendLine("  $(To-CssVar $kv.Key): $($kv.Value.cssValue);")
    }
    [void]$css.AppendLine("}")
}

$cssPath = Join-Path $OutDir 'sheen.css'
[System.IO.File]::WriteAllText($cssPath, $css.ToString(), [System.Text.Encoding]::UTF8)
Log "  wrote $cssPath ($($css.Length) chars)"

# ─ JS (CommonJS) ──────────────────────────────────────────────────────────────
$js = [System.Text.StringBuilder]::new()
[void]$js.AppendLine("// sheen.js — generated by scripts/build-tokens.ps1; do not hand-edit")
[void]$js.AppendLine("// spec 01 §4: DTCG source → CommonJS token module")
[void]$js.AppendLine("'use strict';")
[void]$js.AppendLine("")
[void]$js.AppendLine("const tokens = {")
foreach ($kv in $Resolved.GetEnumerator()) {
    $jsKey = "'" + (Js-Escape $kv.Key) + "'"
    $jsVal = "'" + (Js-Escape $kv.Value.cssValue) + "'"
    [void]$js.AppendLine("  ${jsKey}: ${jsVal},")
}
[void]$js.AppendLine("};")
[void]$js.AppendLine("")
[void]$js.AppendLine("const themes = {")
foreach ($themeName in $ResolvedThemes.Keys) {
    [void]$js.AppendLine("  '$themeName': {")
    foreach ($kv in $ResolvedThemes[$themeName].GetEnumerator()) {
        $jsKey = "'" + (Js-Escape $kv.Key) + "'"
        $jsVal = "'" + (Js-Escape $kv.Value.cssValue) + "'"
        [void]$js.AppendLine("    ${jsKey}: ${jsVal},")
    }
    [void]$js.AppendLine("  },")
}
[void]$js.AppendLine("};")
[void]$js.AppendLine("")
[void]$js.AppendLine("module.exports = { tokens, themes };")

$jsPath = Join-Path $OutDir 'sheen.js'
[System.IO.File]::WriteAllText($jsPath, $js.ToString(), [System.Text.Encoding]::UTF8)
Log "  wrote $jsPath"

# ─ ESM ────────────────────────────────────────────────────────────────────────
$esm = [System.Text.StringBuilder]::new()
[void]$esm.AppendLine("// sheen.esm.js — generated by scripts/build-tokens.ps1; do not hand-edit")
[void]$esm.AppendLine("// spec 01 §4: DTCG source → ES module (tree-shakeable)")
[void]$esm.AppendLine("")
[void]$esm.AppendLine("export const tokens = {")
foreach ($kv in $Resolved.GetEnumerator()) {
    $jsKey = "'" + (Js-Escape $kv.Key) + "'"
    $jsVal = "'" + (Js-Escape $kv.Value.cssValue) + "'"
    [void]$esm.AppendLine("  ${jsKey}: ${jsVal},")
}
[void]$esm.AppendLine("};")
[void]$esm.AppendLine("")
[void]$esm.AppendLine("export const themes = {")
foreach ($themeName in $ResolvedThemes.Keys) {
    [void]$esm.AppendLine("  '$themeName': {")
    foreach ($kv in $ResolvedThemes[$themeName].GetEnumerator()) {
        $jsKey = "'" + (Js-Escape $kv.Key) + "'"
        $jsVal = "'" + (Js-Escape $kv.Value.cssValue) + "'"
        [void]$esm.AppendLine("    ${jsKey}: ${jsVal},")
    }
    [void]$esm.AppendLine("  },")
}
[void]$esm.AppendLine("};")

$esmPath = Join-Path $OutDir 'sheen.esm.js'
[System.IO.File]::WriteAllText($esmPath, $esm.ToString(), [System.Text.Encoding]::UTF8)
Log "  wrote $esmPath"

# ─ TypeScript declarations ────────────────────────────────────────────────────
$dts = [System.Text.StringBuilder]::new()
[void]$dts.AppendLine("// sheen.d.ts — generated by scripts/build-tokens.ps1; do not hand-edit")
[void]$dts.AppendLine("")
$tokenKeys = ($Resolved.Keys | ForEach-Object { "  '$_': string" }) -join ";\n"
[void]$dts.AppendLine("export type TokenKey =")
foreach ($key in $Resolved.Keys) {
    [void]$dts.AppendLine("  | '$key'")
}
[void]$dts.AppendLine(";")
[void]$dts.AppendLine("")
[void]$dts.AppendLine("export type ThemeName = $( ($ResolvedThemes.Keys | ForEach-Object { "'$_'" }) -join ' | ' );")
[void]$dts.AppendLine("")
[void]$dts.AppendLine("export declare const tokens: Record<TokenKey, string>;")
[void]$dts.AppendLine("export declare const themes: Record<ThemeName, Record<TokenKey, string>>;")

$dtsPath = Join-Path $OutDir 'sheen.d.ts'
[System.IO.File]::WriteAllText($dtsPath, $dts.ToString(), [System.Text.Encoding]::UTF8)
Log "  wrote $dtsPath"

Log "build-tokens: done — $($Resolved.Count) semantic token(s), $($ResolvedThemes.Count) theme(s)"
Log "build-tokens: outputs in $OutDir"

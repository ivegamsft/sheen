#!/usr/bin/env pwsh
# contrast-check.ps1 — standalone WCAG 2.2 contrast checker (Spec 05 §3)
#
# Usage:
#   pwsh scripts/contrast-check.ps1 -Fg "#0969da" -Bg "#ffffff"
#   pwsh scripts/contrast-check.ps1 -Theme tokens/themes/light.tokens.json
#   pwsh scripts/contrast-check.ps1               (checks all themes)
#
# Exits 0 if all checked pairs pass, 1 if any fail.

param(
    [string]$Fg,
    [string]$Bg,
    [string]$Theme,
    [double]$MinRatio = 4.5
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$IsCI = $env:GITHUB_ACTIONS -eq 'true'
$Status = 0

function ConvertTo-Linear([double]$c) {
    if ($c -le 0.04045) { return $c / 12.92 }
    return [Math]::Pow(($c + 0.055) / 1.055, 2.4)
}
function Get-Luminance([string]$Hex) {
    $h = $Hex.TrimStart('#')
    if ($h.Length -eq 3) { $h = "$($h[0])$($h[0])$($h[1])$($h[1])$($h[2])$($h[2])" }
    if ($h.Length -ne 6) { return $null }
    $r = ConvertTo-Linear ([Convert]::ToInt32($h.Substring(0,2),16) / 255.0)
    $g = ConvertTo-Linear ([Convert]::ToInt32($h.Substring(2,2),16) / 255.0)
    $b = ConvertTo-Linear ([Convert]::ToInt32($h.Substring(4,2),16) / 255.0)
    return 0.2126*$r + 0.7152*$g + 0.0722*$b
}
function Get-Ratio([string]$H1, [string]$H2) {
    $l1 = Get-Luminance $H1; $l2 = Get-Luminance $H2
    if ($null -eq $l1 -or $null -eq $l2) { return $null }
    $li = [Math]::Max($l1,$l2); $dk = [Math]::Min($l1,$l2)
    return ($li + 0.05) / ($dk + 0.05)
}
function Report([string]$Label, [string]$FgH, [string]$BgH, [double]$Min) {
    $r = Get-Ratio $FgH $BgH
    if ($null -eq $r) { Write-Host "[skip] $Label — could not compute ratio"; return }
    $rs = [Math]::Round($r, 2)
    if ($r -ge $Min) {
        Write-Host ("[pass] {0,-40} {1,5}:1  >= {2}:1" -f $Label, $rs, $Min)
    } else {
        $msg = "FAIL $Label : ${FgH} on ${BgH} = ${rs}:1 < ${Min}:1 required"
        if ($IsCI) { Write-Host "::error::$msg" } else { Write-Host "[fail] $msg" }
        $script:Status = 1
    }
}

# --- direct pair mode ---
if ($Fg -and $Bg) {
    Report "$Fg on $Bg" $Fg $Bg $MinRatio
    exit $Status
}

# --- theme file mode ---
$repoRoot = git rev-parse --show-toplevel 2>$null
# Auto-detect consumer repo: if .sheen/manifest.json present, use consumer token paths (#87)
$IsConsumer = Test-Path (Join-Path $repoRoot '.sheen' 'manifest.json')
$TokensBase  = if ($IsConsumer) { Join-Path $repoRoot 'sheen/tokens' } else { Join-Path $repoRoot 'tokens' }
$ThemesDir   = Join-Path $TokensBase 'themes'
$SemanticDir = Join-Path $TokensBase 'semantic'
$CoreDir     = Join-Path $TokensBase 'core'

# Semantic contrast pairs (foreground / background / min-ratio)
$Pairs = @(
    [pscustomobject]@{Fg='color.foreground';  Bg='color.background'; Min=4.5}
    [pscustomobject]@{Fg='color.on-primary';  Bg='color.primary';    Min=4.5}
    [pscustomobject]@{Fg='color.on-secondary';Bg='color.secondary';  Min=4.5}
    [pscustomobject]@{Fg='color.on-success';  Bg='color.success';    Min=4.5}
    [pscustomobject]@{Fg='color.on-warning';  Bg='color.warning';    Min=4.5}
    [pscustomobject]@{Fg='color.on-error';    Bg='color.error';      Min=4.5}
    [pscustomobject]@{Fg='color.on-accent';   Bg='color.accent';     Min=4.5}
)

function Get-FlatTokens([pscustomobject]$Obj, [string]$Prefix='') {
    $out = @{}
    foreach ($k in $Obj.PSObject.Properties.Name) {
        if ($k.StartsWith('$')) { continue }
        $v = $Obj.$k; $p = if ($Prefix) { "$Prefix.$k" } else { $k }
        if ($null -ne $v -and $v -is [pscustomobject] -and $v.PSObject.Properties.Name -contains '$type') { $out[$p] = $v }
        elseif ($v -is [pscustomobject]) { $out += Get-FlatTokens $v $p }
    }
    return $out
}
function Resolve-Hex([string]$Key, [hashtable]$Lookup) {
    $val = if ($Lookup.ContainsKey($Key)) { $Lookup[$Key].'$value' } else { return $null }
    $depth = 0
    while ($val -match '^\{(.+)\}$') {
        $ref = $Matches[1]; if (++$depth -gt 10) { return $null }
        $val = if ($Lookup.ContainsKey($ref)) { $Lookup[$ref].'$value' } else { return $null }
    }
    if ($val -notmatch '^#[0-9a-fA-F]{3,6}$') { return $null }
    return $val
}

# Build base lookup from core + semantic
$BaseLookup = @{}
foreach ($dir in @($CoreDir,$SemanticDir)) {
    if (Test-Path $dir) {
        foreach ($f in Get-ChildItem $dir -Filter '*.tokens.json') {
            $obj = Get-Content -Raw $f.FullName | ConvertFrom-Json
            foreach ($kv in (Get-FlatTokens $obj).GetEnumerator()) { $BaseLookup[$kv.Key] = $kv.Value }
        }
    }
}

$files = if ($Theme) { @(Get-Item $Theme) } else { Get-ChildItem $ThemesDir -Filter '*.tokens.json' }
foreach ($f in $files) {
    $themeName = [IO.Path]::GetFileNameWithoutExtension($f.BaseName)
    $themeFlat = Get-FlatTokens (Get-Content -Raw $f.FullName | ConvertFrom-Json)
    $lookup = @{} + $BaseLookup
    foreach ($kv in $themeFlat.GetEnumerator()) { $lookup[$kv.Key] = $kv.Value }
    $isHC = $themeName -like '*high-contrast*'
    foreach ($pair in $Pairs) {
        $pairMin = $pair.Min; $min = if ($isHC) { 7.0 } else { $pairMin }
        $fgHex = Resolve-Hex $pair.Fg $lookup
        $bgHex = Resolve-Hex $pair.Bg $lookup
        if (-not $fgHex -or -not $bgHex) { Write-Host "[skip] $themeName $($pair.Fg) / $($pair.Bg)"; continue }
        Report "$themeName  $($pair.Fg) / $($pair.Bg)" $fgHex $bgHex $min
    }
}
if ($Status -eq 0) { Write-Host "contrast-check: all pairs passed." }
exit $Status

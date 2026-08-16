#!/usr/bin/env pwsh
# validate-tokens.ps1 --- DTCG token validator (PowerShell)
#
# Implements spec 01 s6 / checks.json token-schema rule. Run from repo root.
# Exits 0 on pass, 1 on any error. Prints GitHub Actions annotations when
# GITHUB_ACTIONS=true; plain text otherwise.
#
# Checks:
#   1. Schema     -- all .tokens.json are valid JSON + DTCG $type in allowed set
#   2. Tier       -- core/ has no {alias} references; themes/ add no new keys
#   3. References -- every alias resolves in core; no dangling refs; no cycles
#   4. Completeness -- every semantic key appears in every theme
#   5. Contrast   -- WCAG 2.2 AA (4.5:1) for light/dark; >=7:1 for high-contrast
#                    on CONTRAST_PAIRS (foreground/background, on-X/X)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$IsCI      = $env:GITHUB_ACTIONS -eq 'true'
$TokensDir = if ($args.Count -gt 0) { $args[0] } else { Join-Path (git rev-parse --show-toplevel) 'tokens' }
$Status    = 0

$AllowedTypes = @('color','dimension','fontFamily','fontWeight','duration','cubicBezier','number','shadow')
# Composite types (DTCG §9; spec 01 §2): typography, elevation, material
$AllowedTypes += @('typography','elevation','material')

# Contrast pairs: [on-token-key, background-token-key, min-ratio]
# min-ratio 4.5 = WCAG AA text; 7.0 = enhanced (high-contrast)
$ContrastPairs = @(
    @{ fg = 'foreground';   bg = 'background';  min = 4.5 }
    @{ fg = 'on-primary';   bg = 'primary';     min = 4.5 }
    @{ fg = 'on-secondary'; bg = 'secondary';   min = 4.5 }
    @{ fg = 'on-success';   bg = 'success';     min = 4.5 }
    @{ fg = 'on-warning';   bg = 'warning';     min = 4.5 }
    @{ fg = 'on-error';     bg = 'error';       min = 4.5 }
    @{ fg = 'on-accent';    bg = 'accent';      min = 4.5 }
)
$HcPairs = $ContrastPairs | ForEach-Object { @{ fg=$_.fg; bg=$_.bg; min=7.0 } }

function Write-Issue { param([string]$Level, [string]$File, [string]$Msg)
    if ($IsCI) { Write-Host "::${Level} file=${File}::${Msg}" }
    else       { Write-Host "[${Level}] $File : $Msg" }
    if ($Level -eq 'error') { $script:Status = 1 }
}

# --- helpers ---

function Get-FlatTokens {
    param([pscustomobject]$Obj, [string]$Prefix = '')
    $tokens = @{}
    foreach ($key in $Obj.PSObject.Properties.Name) {
        if ($key.StartsWith('$')) { continue }
        $val  = $Obj.$key
        $path = if ($Prefix) { "$Prefix.$key" } else { $key }
        if ($null -ne $val -and $val.PSObject.Properties.Name -contains '$type') {
            $tokens[$path] = $val
        } elseif ($val -is [pscustomobject]) {
            $tokens += Get-FlatTokens -Obj $val -Prefix $path
        }
    }
    return $tokens
}

function Resolve-Alias {
    param([string]$Value, [hashtable]$CoreFlat, [hashtable]$Seen)
    if ($Value -notmatch '^\{(.+)\}$') { return $Value }
    $ref = $Matches[1]
    if ($Seen.ContainsKey($ref)) { return $null }  # cycle
    if (-not $CoreFlat.ContainsKey($ref)) { return '__DANGLING__' }
    $Seen[$ref] = $true
    return Resolve-Alias -Value $CoreFlat[$ref].'$value' -CoreFlat $CoreFlat -Seen $Seen
}

# sRGB channel linearisation (IEC 61966-2-1)
function ConvertTo-Linear { param([double]$c)
    if ($c -le 0.04045) { return $c / 12.92 }
    return [Math]::Pow(($c + 0.055) / 1.055, 2.4)
}

# Relative luminance from 6-char hex
function Get-Luminance { param([string]$Hex)
    $Hex = $Hex.TrimStart('#')
    if ($Hex.Length -eq 3) { $Hex = "$($Hex[0])$($Hex[0])$($Hex[1])$($Hex[1])$($Hex[2])$($Hex[2])" }
    if ($Hex.Length -ne 6) { return $null }
    $r = ConvertTo-Linear ([Convert]::ToInt32($Hex.Substring(0,2),16) / 255.0)
    $g = ConvertTo-Linear ([Convert]::ToInt32($Hex.Substring(2,2),16) / 255.0)
    $b = ConvertTo-Linear ([Convert]::ToInt32($Hex.Substring(4,2),16) / 255.0)
    return 0.2126*$r + 0.7152*$g + 0.0722*$b
}

function Get-ContrastRatio { param([string]$Hex1, [string]$Hex2)
    $l1 = Get-Luminance $Hex1
    $l2 = Get-Luminance $Hex2
    if ($null -eq $l1 -or $null -eq $l2) { return $null }
    $lighter  = [Math]::Max($l1, $l2)
    $darker   = [Math]::Min($l1, $l2)
    return ($lighter + 0.05) / ($darker + 0.05)
}

# --- load & parse files ---

$CoreDir     = Join-Path $TokensDir 'core'
$SemanticDir = Join-Path $TokensDir 'semantic'
$ThemesDir   = Join-Path $TokensDir 'themes'

if (-not (Test-Path $TokensDir)) {
    Write-Host "tokens/ not found — skipping (expected in Phase 0)."
    exit 0
}

Write-Host "validate-tokens: scanning $TokensDir"
$errors = 0

# 1. Schema — valid JSON + allowed $type
$AllFiles = Get-ChildItem -Path $TokensDir -Recurse -Filter '*.tokens.json'
$ParsedFiles = @{}
foreach ($f in $AllFiles) {
    try {
        $ParsedFiles[$f.FullName] = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json
    } catch {
        Write-Issue 'error' $f.FullName "Invalid JSON: $_"
        continue
    }
    $flat = Get-FlatTokens -Obj $ParsedFiles[$f.FullName]
    foreach ($kv in $flat.GetEnumerator()) {
        $t = $kv.Value.'$type'
        if ($t -and $AllowedTypes -notcontains $t) {
            Write-Issue 'error' $f.FullName "Unknown `$type '$t' on token '$($kv.Key)'"
        }
    }
}
Write-Host "  Schema: $($AllFiles.Count) file(s) checked."

# 2. Tier discipline — core must not contain alias references
if (Test-Path $CoreDir) {
    foreach ($f in Get-ChildItem $CoreDir -Filter '*.tokens.json') {
        if (-not $ParsedFiles.ContainsKey($f.FullName)) { continue }
        $flat = Get-FlatTokens -Obj $ParsedFiles[$f.FullName]
        foreach ($kv in $flat.GetEnumerator()) {
            if ($kv.Value.'$value' -match '^\{.+\}$') {
                Write-Issue 'error' $f.FullName "Tier violation: core token '$($kv.Key)' contains an alias reference ('$($kv.Value.'$value')'). Core tokens must be literal values."
            }
        }
    }
    Write-Host "  Tier discipline: core/ checked."
}

# Build flattened core dict for reference resolution
$CoreFlat = @{}
if (Test-Path $CoreDir) {
    foreach ($f in Get-ChildItem $CoreDir -Filter '*.tokens.json') {
        if (-not $ParsedFiles.ContainsKey($f.FullName)) { continue }
        $CoreFlat += Get-FlatTokens -Obj $ParsedFiles[$f.FullName]
    }
}

# Build flattened semantic dict
$SemanticFlat = @{}
if (Test-Path $SemanticDir) {
    foreach ($f in Get-ChildItem $SemanticDir -Filter '*.tokens.json') {
        if (-not $ParsedFiles.ContainsKey($f.FullName)) { continue }
        $SemanticFlat += Get-FlatTokens -Obj $ParsedFiles[$f.FullName]
    }
}

# 3. Reference resolution — semantic aliases must resolve in core; no cycles
if ($SemanticFlat.Count -gt 0) {
    foreach ($kv in $SemanticFlat.GetEnumerator()) {
        $val = $kv.Value.'$value'
        if ($val -match '^\{(.+)\}$') {
            $ref = $Matches[1]
            if (-not $CoreFlat.ContainsKey($ref)) {
                Write-Issue 'error' (Join-Path $SemanticDir '*.tokens.json') "Dangling reference: semantic token '$($kv.Key)' -> '{$ref}' not found in core."
            } else {
                $seen = @{}
                $resolved = Resolve-Alias -Value $val -CoreFlat $CoreFlat -Seen $seen
                if ($null -eq $resolved) {
                    Write-Issue 'error' (Join-Path $SemanticDir '*.tokens.json') "Cycle detected resolving '$($kv.Key)' -> '$val'."
                }
            }
        }
    }
    Write-Host "  References: $($SemanticFlat.Count) semantic token(s) checked."
}

# 4. Theme completeness + tier discipline (themes add no new keys)
if ((Test-Path $ThemesDir) -and $SemanticFlat.Count -gt 0) {
    $SemanticKeys = $SemanticFlat.Keys | Sort-Object
    foreach ($f in Get-ChildItem $ThemesDir -Filter '*.tokens.json') {
        if (-not $ParsedFiles.ContainsKey($f.FullName)) { continue }
        $themeFlat = Get-FlatTokens -Obj $ParsedFiles[$f.FullName]
        # Check completeness: every semantic key must have a theme entry
        foreach ($sk in $SemanticKeys) {
            if (-not $themeFlat.ContainsKey($sk)) {
                Write-Issue 'error' $f.FullName "Theme completeness: semantic token '$sk' has no entry in this theme."
            }
        }
        # Check discipline: themes must not introduce new keys absent from semantic
        foreach ($tk in $themeFlat.Keys) {
            if (-not $SemanticFlat.ContainsKey($tk)) {
                Write-Issue 'error' $f.FullName "Tier violation: theme introduces new key '$tk' absent from semantic tier."
            }
        }
    }
    Write-Host "  Theme completeness: checked against $($SemanticKeys.Count) semantic key(s)."
}

# 5. WCAG contrast check
# Resolve a theme token's $value to a literal hex, trying theme-local value first,
# then falling back through semantic->core alias chain.
function Get-ThemeHex {
    param([string]$Key, [hashtable]$ThemeFlat, [hashtable]$SemanticFl, [hashtable]$CoreFl)
    $tv = if ($ThemeFlat.ContainsKey($Key)) { $ThemeFlat[$Key].'$value' } else { $null }
    if (-not $tv -and $SemanticFl.ContainsKey($Key)) { $tv = $SemanticFl[$Key].'$value' }
    if (-not $tv) { return $null }
    if ($tv -match '^\{(.+)\}$') {
        $seen = @{}
        $tv = Resolve-Alias -Value $tv -CoreFlat $CoreFl -Seen $seen
    }
    return $tv
}

if (Test-Path $ThemesDir) {
    foreach ($f in Get-ChildItem $ThemesDir -Filter '*.tokens.json') {
        if (-not $ParsedFiles.ContainsKey($f.FullName)) { continue }
        $themeFlat = Get-FlatTokens -Obj $ParsedFiles[$f.FullName]
        $themeName = [System.IO.Path]::GetFileNameWithoutExtension($f.BaseName)  # strips .tokens
        $isHC      = $themeName -like '*high-contrast*'
        $pairs     = if ($isHC) { $HcPairs } else { $ContrastPairs }
        foreach ($pair in $pairs) {
            $fgHex = Get-ThemeHex -Key "color.$($pair.fg)" -ThemeFlat $themeFlat -SemanticFl $SemanticFlat -CoreFl $CoreFlat
            $bgHex = Get-ThemeHex -Key "color.$($pair.bg)" -ThemeFlat $themeFlat -SemanticFl $SemanticFlat -CoreFl $CoreFlat
            if (-not $fgHex -or -not $bgHex) {
                Write-Host "  [skip] $themeName $($pair.fg)/$($pair.bg) — could not resolve hex"
                continue
            }
            # Skip non-hex values (rgba, etc.) gracefully
            if ($fgHex -notmatch '^#[0-9a-fA-F]{3,6}$' -or $bgHex -notmatch '^#[0-9a-fA-F]{3,6}$') {
                Write-Host "  [skip] $themeName $($pair.fg)/$($pair.bg) — non-hex value ($fgHex / $bgHex)"
                continue
            }
            $ratio = Get-ContrastRatio $fgHex $bgHex
            if ($null -eq $ratio) { continue }
            $ratioStr = [Math]::Round($ratio, 2)
            if ($ratio -lt $pair.min) {
                Write-Issue 'error' $f.FullName ("WCAG contrast FAIL [$themeName] $($pair.fg) ($fgHex) on $($pair.bg) ($bgHex): {0}:1 < {1}:1 required" -f $ratioStr, $pair.min)
            } else {
                Write-Host ("  [pass] {0,-16} {1,-18} on {2,-18} {3,5}:1  >= {4}:1" -f $themeName, $($pair.fg), $($pair.bg), $ratioStr, $pair.min)
            }
        }
    }
}

if ($Status -eq 0) { Write-Host "validate-tokens: all checks passed." }
else               { Write-Host "validate-tokens: $Status error(s) found." }
exit $Status

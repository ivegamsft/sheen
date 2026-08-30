#!/usr/bin/env pwsh
# audit-diagram-slop.ps1 — enforceable diagram "anti-slop" checks (#115)
#
# Ports cathrynlavery/diagram-design's editorial anti-slop guidance into
# concrete, rule-id'd, auto-failing checks (not prose) for the design-audit
# skill and the documentation-diagram renderer (#113). Runs against a single
# self-contained SVG file.
#
# Rule IDs:
#   DENSITY        node count exceeds the density budget (target ~4/10;
#                   >9 nodes on one diagram is an auto-fail — split into
#                   smaller diagrams or a hierarchy instead).
#   SHADOW          any element references an SVG filter that contains a
#                   drop-shadow/blur primitive. Sheen diagrams are flat:
#                   borders only, no shadows.
#   RADIUS          any <rect> corner radius (rx/ry) exceeds the max
#                   (default 10px). Sheen diagrams use sharp or subtly
#                   rounded corners, never pill/heavily-rounded shapes.
#   ACCENT-BUDGET   more than 1-2 elements use the theme's `accent` or
#                   `accent-tint` colour. Accent is for focal emphasis, not
#                   a decoration applied everywhere.
#   STRAY-HEX       a fill/stroke hex value is used that is not present in
#                   the resolved theme skin (dist/diagram-skins/<theme>.json)
#                   — catches both hand-picked one-off hex and "neon" colours
#                   that were never part of the approved palette.
#   MONO-FONT       every <text> element in the diagram shares one monospace
#                   font-family with no hierarchy — diagrams need at least
#                   one non-mono role (e.g. headings) unless the whole
#                   diagram IS code (a class-diagram code block is exempt
#                   via -AllowMonoFont).
#   SLANT, SHARED-ATTACH, OVERLAP-PATH, LABEL-UNMASKED, CLIPPED-LABEL,
#   TRANSIT-BEHIND
#                   the six connector rules — delegated to
#                   scripts/lint-diagram-geometry.ps1 (#118) so there is one
#                   implementation, not two.
#
# Usage:
#   pwsh scripts/audit-diagram-slop.ps1 -SvgPath <file> -Theme <name>
#        [-MaxNodes 9] [-MaxAccentElements 2] [-MaxCornerRadius 10]
#        [-SkinsDir <path>] [-AllowMonoFont] [-Quiet]
#
# Exits 0 if the file passes every rule, 1 otherwise (each failure prints the
# rule id and a short explanation so findings map directly onto a
# design-audit backlog item).

param(
    [Parameter(Mandatory = $true)]
    [string]$SvgPath,
    [string]$Theme = 'light',
    [int]$MaxNodes = 9,
    [int]$MaxAccentElements = 2,
    [int]$MaxCornerRadius = 10,
    [string]$SkinsDir,
    [switch]$AllowMonoFont,
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
function Fail([string]$rule, [string]$msg) {
    $line = "[$rule] $msg"
    if ($IsCI) { Write-Host "::error::$line" } else { Write-Host "FAIL: $line" -ForegroundColor Red }
    $script:FailCount++
}

$script:FailCount = 0

if (-not (Test-Path -LiteralPath $SvgPath)) { Write-Host "::error::SVG file not found: '$SvgPath'"; exit 1 }

[xml]$svg = Get-Content -LiteralPath $SvgPath -Raw
$ns = New-Object System.Xml.XmlNamespaceManager($svg.NameTable)
$ns.AddNamespace('svg', 'http://www.w3.org/2000/svg')

$nodes      = @($svg.SelectNodes('//svg:rect[@id]', $ns)) + @($svg.SelectNodes('//svg:circle[@id]', $ns))
$allRects   = @($svg.SelectNodes('//svg:rect', $ns))
$allShapes  = @($svg.SelectNodes('//svg:rect | //svg:circle | //svg:path | //svg:polygon | //svg:ellipse', $ns))
$allText    = @($svg.SelectNodes('//svg:text', $ns))
$filterDefs = @($svg.SelectNodes('//svg:filter', $ns))

Log "audit-diagram-slop: $($nodes.Count) node(s), $($allShapes.Count) shape(s), $($allText.Count) text element(s)"

# ── DENSITY ───────────────────────────────────────────────────────────────────
if ($nodes.Count -gt $MaxNodes) {
    Fail 'DENSITY' "diagram has $($nodes.Count) nodes, over the $MaxNodes-node auto-fail threshold (target density ~4/10) — split into smaller diagrams or a drill-down hierarchy"
} else {
    Log "  [pass] DENSITY $($nodes.Count)/$MaxNodes nodes"
}

# ── SHADOW ────────────────────────────────────────────────────────────────────
$shadowFilterIds = @{}
foreach ($f in $filterDefs) {
    $hasShadowPrimitive = $f.SelectNodes('.//svg:feDropShadow | .//svg:feGaussianBlur', $ns).Count -gt 0
    if ($hasShadowPrimitive) { $shadowFilterIds[$f.GetAttribute('id')] = $true }
}
foreach ($el in $allShapes) {
    $filterAttr = $el.GetAttribute('filter')
    if ($filterAttr -match 'url\(#([^)]+)\)') {
        $id = $Matches[1]
        if ($shadowFilterIds.ContainsKey($id)) {
            Fail 'SHADOW' "element uses filter '#$id' which contains a drop-shadow/blur primitive — sheen diagrams are flat (borders only, no shadows)"
        }
    }
}

# ── RADIUS ────────────────────────────────────────────────────────────────────
foreach ($r in $allRects) {
    foreach ($attr in @('rx', 'ry')) {
        $v = $r.GetAttribute($attr)
        if ($v -and [double]$v -gt $MaxCornerRadius) {
            Fail 'RADIUS' "rect '$($r.GetAttribute('id'))' has $attr=$v, over the ${MaxCornerRadius}px max corner radius"
        }
    }
}

# ── ACCENT-BUDGET / STRAY-HEX ──────────────────────────────────────────────────
$skinPath = Join-Path $SkinsDir "$Theme.json"
if (Test-Path -LiteralPath $skinPath) {
    $skin = Get-Content -LiteralPath $skinPath -Raw | ConvertFrom-Json
    $allowedHex = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($p in $skin.PSObject.Properties) {
        if ($p.Name -eq 'series') { foreach ($s in $p.Value) { [void]$allowedHex.Add($s) } }
        else { [void]$allowedHex.Add([string]$p.Value) }
    }
    $accentHex = @([string]$skin.accent, [string]$skin.'accent-tint')

    $accentCount = 0
    foreach ($el in $allShapes) {
        foreach ($attr in @('fill', 'stroke')) {
            $v = $el.GetAttribute($attr)
            if (-not $v -or $v -eq 'none') { continue }
            if ($accentHex -contains $v) { $accentCount++ }
            elseif ($v -match '^#[0-9a-fA-F]{6}$' -and -not $allowedHex.Contains($v)) {
                Fail 'STRAY-HEX' "element uses '$v' ($attr), which is not in the resolved '$Theme' theme skin ($skinPath)"
            }
        }
    }
    if ($accentCount -gt $MaxAccentElements) {
        Fail 'ACCENT-BUDGET' "$accentCount elements use accent/accent-tint colour, over the $MaxAccentElements-element focal-emphasis budget"
    } else {
        Log "  [pass] ACCENT-BUDGET $accentCount/$MaxAccentElements accent element(s)"
    }
} else {
    Log "  [skip] ACCENT-BUDGET / STRAY-HEX — no skin file at '$skinPath' (run scripts/build-diagram-skins.ps1 first)"
}

# ── MONO-FONT ──────────────────────────────────────────────────────────────────
if (-not $AllowMonoFont -and $allText.Count -gt 1) {
    $fonts = @($allText | ForEach-Object { $_.GetAttribute('font-family') } | Where-Object { $_ })
    if ($fonts.Count -eq $allText.Count) {
        $monoFonts = @($fonts | Where-Object { $_ -match '(?i)mono|consolas|courier' })
        if ($monoFonts.Count -eq $fonts.Count) {
            Fail 'MONO-FONT' "all $($allText.Count) text elements use a monospace font-family with no non-mono role for hierarchy (pass -AllowMonoFont for diagrams that are intentionally all-code)"
        }
    }
}

# ── connector rules (delegated to lint-diagram-geometry.ps1, #118) ───────────
$geometryScript = Join-Path $repoRoot 'scripts' 'lint-diagram-geometry.ps1'
if (Test-Path -LiteralPath $geometryScript) {
    & pwsh -NonInteractive -File $geometryScript -SvgPath $SvgPath -Quiet:$Quiet
    if ($LASTEXITCODE -ne 0) { $script:FailCount++ }
} else {
    Log "  [skip] connector rules — scripts/lint-diagram-geometry.ps1 not found"
}

if ($script:FailCount -gt 0) {
    Write-Host "audit-diagram-slop: $($script:FailCount) failure(s) in '$SvgPath'."
    exit 1
}
Log "audit-diagram-slop: '$SvgPath' passed all anti-slop checks."

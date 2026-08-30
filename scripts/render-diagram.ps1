#!/usr/bin/env pwsh
# render-diagram.ps1 — documentation-diagram renderer (#113, epic #110)
#
# Emits a self-contained HTML+SVG file (no runtime deps, no Mermaid, no CDN
# fonts) for one of the 16 diagram types kept under epic #110's scope
# decision (docs/decisions/adr-006-diagram-scope.md):
#
#   Bar, Line, Sankey, Treemap, Gantt, Kanban, Story map, User journey,
#   Quadrant, Fishbone, Pyramid/funnel, Org chart, Loop/flywheel, Timeline,
#   Venn, DP security matrix.
#
# Every colour used is read from dist/diagram-skins/<theme>.json (built by
# scripts/build-diagram-skins.ps1, #116) — never a hand-picked hex (ADR-005).
# Output is static by default, per ADR-003 — no <animate>, no CSS transition,
# nothing that would need a prefers-reduced-motion fallback because there is
# no motion to reduce. Output satisfies the accessibility contract already
# established by skills/data-visualisation (ARIA role="img" + <title>/<desc>,
# a <table> data fallback per WCAG 1.3.1, no colour-only encoding) and is
# designed to pass scripts/lint-diagram-geometry.ps1 (#118) and
# scripts/audit-diagram-slop.ps1 (#115) unmodified.
#
# Excluded types (Scatter, Polar/Radar, Wardley map, and any live/reporting
# dashboard) are NOT rendered here — they route out with a clear message to
# skills/data-visualisation, per ADR-006 and this issue's acceptance
# criteria.
#
# Usage:
#   pwsh scripts/render-diagram.ps1 -Type <type> -SpecPath <spec.json> `
#        -OutPath <out.html> [-Theme light|dark|high-contrast] [-Quiet]
#
# Spec schemas (one per type) are documented in
# skills/documentation-diagram/SKILL.md, with a runnable sample per type in
# skills/documentation-diagram/samples/.

param(
    [Parameter(Mandatory = $true)]
    [string]$Type,

    [string]$SpecPath,

    [Parameter(Mandatory = $true)]
    [string]$OutPath,

    [ValidateSet('light', 'dark', 'high-contrast')]
    [string]$Theme = 'light',

    [string]$SkinsDir,
    [string]$IconsDir,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

function Log([string]$msg) { if (-not $Quiet) { Write-Host $msg } }
function Err([string]$msg) { Write-Host "::error::$msg"; exit 1 }

$repoRoot = $null
try { $repoRoot = (git rev-parse --show-toplevel 2>$null).Trim() } catch { $repoRoot = $null }
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

if (-not $SkinsDir) { $SkinsDir = Join-Path $repoRoot 'dist' 'diagram-skins' }
if (-not $IconsDir) { $IconsDir = Join-Path $repoRoot 'dist' 'icons' }

# ── included / excluded type routing (ADR-006) ───────────────────────────────

$IncludedTypes = @(
    'bar', 'line', 'sankey', 'treemap', 'gantt', 'kanban', 'story-map',
    'user-journey', 'quadrant', 'fishbone', 'funnel', 'org-chart', 'loop',
    'timeline', 'venn', 'security-matrix'
)
$ExcludedTypes = @{
    'scatter'  = 'Scatter plots report measured/live data — use skills/data-visualisation/chart-spec-template.md instead.'
    'polar'    = 'Polar charts report measured/live data — use skills/data-visualisation/chart-spec-template.md instead.'
    'radar'    = 'Radar/spider charts report measured/live data — use skills/data-visualisation/chart-spec-template.md instead.'
    'wardley'  = 'Wardley maps are out of scope for this epic (see docs/decisions/adr-006-diagram-scope.md) — not currently supported by any sheen skill.'
    'dashboard' = 'Live/reporting dashboards are out of scope for the documentation-diagram renderer — use skills/data-visualisation/dashboard-layout-template.md instead.'
}

$TypeKey = $Type.ToLowerInvariant()
if ($ExcludedTypes.ContainsKey($TypeKey)) {
    Err "Diagram type '$Type' is explicitly excluded from the documentation-diagram renderer. $($ExcludedTypes[$TypeKey])"
}
if ($IncludedTypes -notcontains $TypeKey) {
    Err "Unknown diagram type '$Type'. Included types: $($IncludedTypes -join ', '). If this is a reporting/measurement chart (scatter, polar, radar, live dashboard), it belongs in skills/data-visualisation/ instead — see docs/decisions/adr-006-diagram-scope.md."
}

if (-not $SpecPath) { Err "Missing -SpecPath (a JSON spec file for type '$Type'; see skills/documentation-diagram/samples/)." }
if (-not (Test-Path -LiteralPath $SpecPath)) { Err "Spec file not found: '$SpecPath'" }

$skinPath = Join-Path $SkinsDir "$Theme.json"
if (-not (Test-Path -LiteralPath $skinPath)) {
    Err "Skin file not found: '$skinPath' — run scripts/build-diagram-skins.ps1 first."
}
$Skin = @{}
(Get-Content -LiteralPath $skinPath -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object {
    $Skin[$_.Name] = $_.Value
}

$Spec = Get-Content -LiteralPath $SpecPath -Raw | ConvertFrom-Json

$FontFamily = "'Segoe UI', system-ui, -apple-system, Helvetica, Arial, sans-serif"

function Get-Icon([string]$name) {
    $path = Join-Path $IconsDir "$name.svg"
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    $raw = Get-Content -LiteralPath $path -Raw
    # Strip the outer <svg ...>...</svg> wrapper, keep only inner <path> markup,
    # so it can be embedded inside a positioned <g> in the diagram canvas.
    $inner = [regex]::Match($raw, '(?s)<svg[^>]*>(.*)</svg>').Groups[1].Value.Trim()
    return $inner
}

function XmlEscape([string]$s) {
    if ($null -eq $s) { return '' }
    return [System.Security.SecurityElement]::Escape([string]$s)
}

# ── low-level SVG element builders ───────────────────────────────────────────

function Svg-Rect {
    param([double]$X, [double]$Y, [double]$W, [double]$H, [string]$Fill, [string]$Stroke = $null,
          [double]$StrokeWidth = 1, [string]$Id = $null, [double]$Rx = 0)
    $attrs = @("x=`"$X`"", "y=`"$Y`"", "width=`"$W`"", "height=`"$H`"", "fill=`"$Fill`"")
    if ($Stroke) { $attrs += "stroke=`"$Stroke`""; $attrs += "stroke-width=`"$StrokeWidth`"" }
    if ($Id) { $attrs += "id=`"$Id`"" }
    if ($Rx -gt 0) { $attrs += "rx=`"$Rx`""; $attrs += "ry=`"$Rx`"" }
    return "<rect $($attrs -join ' ') />"
}

function Svg-Text {
    param([double]$X, [double]$Y, [string]$Content, [string]$Fill, [int]$Size = 12,
          [string]$Anchor = 'start', [string]$Class = $null, [string]$Weight = 'normal')
    $classAttr = if ($Class) { "class=`"$Class`" " } else { "" }
    return "<text $classAttr x=`"$X`" y=`"$Y`" fill=`"$Fill`" font-family=`"$FontFamily`" font-size=`"$Size`" font-weight=`"$Weight`" text-anchor=`"$Anchor`">$(XmlEscape $Content)</text>"
}

function Svg-Line {
    param([double]$X1, [double]$Y1, [double]$X2, [double]$Y2, [string]$Stroke, [double]$StrokeWidth = 1, [string]$DashArray = $null)
    $dash = if ($DashArray) { "stroke-dasharray=`"$DashArray`"" } else { "" }
    return "<line x1=`"$X1`" y1=`"$Y1`" x2=`"$X2`" y2=`"$Y2`" stroke=`"$Stroke`" stroke-width=`"$StrokeWidth`" $dash />"
}

function Svg-Circle {
    param([double]$Cx, [double]$Cy, [double]$R, [string]$Fill, [string]$Stroke = $null, [double]$StrokeWidth = 1, [string]$Id = $null, [double]$Opacity = 1)
    $attrs = @("cx=`"$Cx`"", "cy=`"$Cy`"", "r=`"$R`"", "fill=`"$Fill`"", "fill-opacity=`"$Opacity`"")
    if ($Stroke) { $attrs += "stroke=`"$Stroke`""; $attrs += "stroke-width=`"$StrokeWidth`"" }
    if ($Id) { $attrs += "id=`"$Id`"" }
    return "<circle $($attrs -join ' ') />"
}

function Svg-Polygon {
    param([string]$Points, [string]$Fill, [string]$Stroke = $null, [double]$StrokeWidth = 1, [string]$Id = $null)
    $attrs = @("points=`"$Points`"", "fill=`"$Fill`"")
    if ($Stroke) { $attrs += "stroke=`"$Stroke`""; $attrs += "stroke-width=`"$StrokeWidth`"" }
    if ($Id) { $attrs += "id=`"$Id`"" }
    return "<polygon $($attrs -join ' ') />"
}

function Svg-Path {
    param([string]$D, [string]$Fill = 'none', [string]$Stroke = $null, [double]$StrokeWidth = 1, [string]$Class = $null)
    $classAttr = if ($Class) { "class=`"$Class`" " } else { "" }
    return "<path ${classAttr}d=`"$D`" fill=`"$Fill`" stroke=`"$Stroke`" stroke-width=`"$StrokeWidth`" />"
}

# A connector is a <path class="connector"> with an orthogonal or 45deg-only
# route (SLANT rule), unique per attach point (SHARED-ATTACH), unique 'd'
# (OVERLAP-PATH) — callers are responsible for the geometry; this helper only
# emits the required markup/attributes.
function Svg-Connector {
    param([string]$FromId, [string]$ToId, [string]$D, [string]$Stroke, [double]$StrokeWidth = 2)
    return "<path class=`"connector`" data-from=`"$FromId`" data-to=`"$ToId`" d=`"$D`" fill=`"none`" stroke=`"$Stroke`" stroke-width=`"$StrokeWidth`" />"
}

# An edge label MUST sit over a background rect with no `id` (LABEL-UNMASKED) —
# emits both the mask rect and the label text together.
function Svg-EdgeLabel {
    param([double]$X, [double]$Y, [string]$Content, [string]$BgFill, [string]$TextFill, [int]$Size = 11)
    $w = [Math]::Max(20, $Content.Length * $Size * 0.62)
    $h = $Size + 6
    $rect = Svg-Rect -X ($X - $w / 2) -Y ($Y - $h + 2) -W $w -H $h -Fill $BgFill
    $text = "<text class=`"edge-label`" x=`"$X`" y=`"$Y`" fill=`"$TextFill`" font-family=`"$FontFamily`" font-size=`"$Size`" text-anchor=`"middle`">$(XmlEscape $Content)</text>"
    return "$rect`n$text"
}

function Svg-Icon {
    param([string]$Name, [double]$X, [double]$Y, [double]$Size, [string]$Color)
    $inner = Get-Icon $Name
    if (-not $inner) { return '' }
    $scale = $Size / 24.0
    return "<g transform=`"translate($X,$Y) scale($scale)`" style=`"color:$Color`">$inner</g>"
}

# ── document wrapper (accessibility contract + ADR-003 static-by-default) ───

function Build-Document {
    param(
        [string]$Title,
        [string]$Description,
        [int]$Width,
        [int]$Height,
        [string]$SvgBody,
        [string[]]$TableHeaders,
        [string[][]]$TableRows
    )
    $paper = $Skin['paper']; $ink = $Skin['ink']

    $tableHead = "<tr>" + (($TableHeaders | ForEach-Object { "<th>$(XmlEscape $_)</th>" }) -join '') + "</tr>"
    $tableBody = ($TableRows | ForEach-Object {
        $row = $_
        "<tr>" + (($row | ForEach-Object { "<td>$(XmlEscape $_)</td>" }) -join '') + "</tr>"
    }) -join "`n"

    return @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>$(XmlEscape $Title)</title>
<style>
  /* Static by default (ADR-003): no @keyframes, no transition, no animate. */
  body { margin: 0; padding: 16px; background: $paper; font-family: $FontFamily; }
  figure { margin: 0; }
  figcaption { color: $ink; font-family: $FontFamily; font-size: 13px; margin-top: 8px; }
  svg { max-width: 100%; height: auto; display: block; }
  /* Visually hidden but screen-reader-accessible fallback table (WCAG 1.3.1) */
  .sr-fallback {
    position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px;
    overflow: hidden; clip: rect(0,0,0,0); white-space: nowrap; border: 0;
  }
  table { border-collapse: collapse; }
  th, td { border: 1px solid #888; padding: 4px 8px; text-align: left; }
</style>
</head>
<body>
<figure>
  <svg viewBox="0 0 $Width $Height" width="$Width" height="$Height" role="img"
       aria-labelledby="diagram-title diagram-desc"
       xmlns="http://www.w3.org/2000/svg">
    <title id="diagram-title">$(XmlEscape $Title)</title>
    <desc id="diagram-desc">$(XmlEscape $Description)</desc>
    <rect x="0" y="0" width="$Width" height="$Height" fill="$paper" />
$SvgBody
  </svg>
  <figcaption>$(XmlEscape $Title)</figcaption>
  <table class="sr-fallback" aria-label="$(XmlEscape $Title) — data table fallback">
    <thead>$tableHead</thead>
    <tbody>
$tableBody
    </tbody>
  </table>
</figure>
</body>
</html>
"@
}

# Renderer functions live in render-diagram-types.ps1 (dot-sourced) to keep
# this file focused on the shared contract (routing, skin/icon loading, SVG
# primitives, document wrapper) versus the sixteen per-type layout algorithms.
. (Join-Path $PSScriptRoot 'render-diagram-types.ps1')

$RenderDispatch = @{
    'bar'             = { Render-Bar $Spec $Skin }
    'line'            = { Render-Line $Spec $Skin }
    'sankey'          = { Render-Sankey $Spec $Skin }
    'treemap'         = { Render-Treemap $Spec $Skin }
    'gantt'           = { Render-Gantt $Spec $Skin }
    'kanban'          = { Render-Kanban $Spec $Skin }
    'story-map'       = { Render-StoryMap $Spec $Skin }
    'user-journey'    = { Render-UserJourney $Spec $Skin }
    'quadrant'        = { Render-Quadrant $Spec $Skin }
    'fishbone'        = { Render-Fishbone $Spec $Skin }
    'funnel'          = { Render-Funnel $Spec $Skin }
    'org-chart'       = { Render-OrgChart $Spec $Skin }
    'loop'            = { Render-Loop $Spec $Skin }
    'timeline'        = { Render-Timeline $Spec $Skin }
    'venn'            = { Render-Venn $Spec $Skin }
    'security-matrix' = { Render-SecurityMatrix $Spec $Skin }
}

$result = & $RenderDispatch[$TypeKey]

$html = Build-Document -Title $result.Title -Description $result.Description `
    -Width $result.Width -Height $result.Height -SvgBody $result.Svg `
    -TableHeaders $result.TableHeaders -TableRows $result.TableRows

$outDir = Split-Path -Parent $OutPath
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
Set-Content -LiteralPath $OutPath -Value $html -NoNewline -Encoding utf8NoBOM

Log "render-diagram: wrote '$OutPath' ($Type, theme=$Theme, $($result.Width)x$($result.Height))"

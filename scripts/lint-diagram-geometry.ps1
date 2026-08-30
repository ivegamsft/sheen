#!/usr/bin/env pwsh
# lint-diagram-geometry.ps1 — static SVG connector/label geometry lint (#118)
#
# Ported/adapted (as heuristics, not a full geometry engine) from
# cathrynlavery/diagram-design's connector rules. Runs against a single
# self-contained SVG file (the output format chosen for the documentation-
# diagram renderer, #113) and checks the six connector/label rules from
# issue #115's anti-slop list that are mechanically checkable without a full
# layout engine:
#
#   SLANT            no diagonal-only connector angles outside {0, 45, 90} deg
#   SHARED-ATTACH     no two connectors sharing the exact same endpoint coordinate
#   OVERLAP-PATH      no two connector paths with an identical `d` attribute
#   LABEL-UNMASKED    every <text class="edge-label"> must sit over a background
#                     rect (mask) so it isn't rendered directly on a stroke
#   CLIPPED-LABEL     no <text> element may carry a `clip-path` attribute
#   TRANSIT-BEHIND    a connector's bounding box may not intersect a non-endpoint
#                     box's bounding box (approximated via bounding-box overlap;
#                     a box is exempted if its `id` matches one of the
#                     connector's `data-from`/`data-to` endpoint ids)
#
# These are conservative, static heuristics over the SVG markup — not a
# rendering/geometry solver — documented as such so failures are always
# inspectable in the raw SVG.
#
# Conventions expected of generated SVGs (documented for #113's renderer):
#   - connectors: <path class="connector" data-from="<id>" data-to="<id>" d="...">
#   - boxes:      <rect id="<id>" ...> or <g id="<id>">...<rect>...</g>
#   - edge labels: <text class="edge-label" ...>
#
# Usage: pwsh scripts/lint-diagram-geometry.ps1 -SvgPath <file> [-Quiet]
# Exits 0 if the file passes every rule, 1 otherwise (each failure prints the
# rule id and the offending element).

param(
    [Parameter(Mandatory = $true)]
    [string]$SvgPath,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$IsCI = $env:GITHUB_ACTIONS -eq 'true'

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

$connectors = @($svg.SelectNodes('//svg:path[contains(concat(" ", @class, " "), " connector ")]', $ns))
$boxes      = @($svg.SelectNodes('//svg:rect[@id]', $ns))
$labels     = @($svg.SelectNodes('//svg:text[contains(concat(" ", @class, " "), " edge-label ")]', $ns))
$allText    = @($svg.SelectNodes('//svg:text', $ns))
$allRects   = @($svg.SelectNodes('//svg:rect', $ns))

Log "lint-diagram-geometry: $($connectors.Count) connector(s), $($boxes.Count) box(es), $($labels.Count) edge-label(s)"

# Parse a path 'd' attribute's first/last on-path coordinate pair (M...  ... last x,y)
function Get-PathEndpoints([string]$d) {
    $coords = [regex]::Matches($d, '(-?\d+(\.\d+)?)[,\s]+(-?\d+(\.\d+)?)') | ForEach-Object {
        [pscustomobject]@{ X = [double]$_.Groups[1].Value; Y = [double]$_.Groups[3].Value }
    }
    if ($coords.Count -lt 2) { return $null }
    return @{ Start = $coords[0]; End = $coords[-1] }
}

function Get-PathAngleDeg($start, $end) {
    $dx = $end.X - $start.X
    $dy = $end.Y - $start.Y
    if ($dx -eq 0 -and $dy -eq 0) { return 0 }
    $deg = [Math]::Atan2($dy, $dx) * 180.0 / [Math]::PI
    $deg = (($deg % 90) + 90) % 90   # normalise to nearest 0-90 slice
    return [Math]::Min($deg, 90 - $deg)  # distance from nearest 0/90 axis
}

# ── SLANT ─────────────────────────────────────────────────────────────────────
$AllowedTolerance = 1.0  # degrees of slack for 0/45/90-aligned connectors
foreach ($c in $connectors) {
    $d = $c.GetAttribute('d')
    $pts = Get-PathEndpoints $d
    if (-not $pts) { continue }
    $distFromAxis = Get-PathAngleDeg $pts.Start $pts.End
    # distFromAxis is 0 at a 0/90 aligned line, 45 at a 45deg aligned line, and
    # peaks at other values for arbitrary diagonals — flag anything that is
    # not close to 0 or 45.
    if ($distFromAxis -gt $AllowedTolerance -and [Math]::Abs($distFromAxis - 45) -gt $AllowedTolerance) {
        Fail 'SLANT' "connector '$($c.GetAttribute('data-from'))->$($c.GetAttribute('data-to'))' has a non-orthogonal, non-45deg angle ($([Math]::Round($distFromAxis,1))deg off-axis)"
    }
}

# ── SHARED-ATTACH ─────────────────────────────────────────────────────────────
$endpointSeen = @{}
foreach ($c in $connectors) {
    $pts = Get-PathEndpoints $c.GetAttribute('d')
    if (-not $pts) { continue }
    foreach ($p in @($pts.Start, $pts.End)) {
        $key = "{0:F1},{1:F1}" -f $p.X, $p.Y
        if ($endpointSeen.ContainsKey($key)) {
            Fail 'SHARED-ATTACH' "two connectors share the exact attach point ($key)"
        }
        $endpointSeen[$key] = $true
    }
}

# ── OVERLAP-PATH ──────────────────────────────────────────────────────────────
$dSeen = @{}
foreach ($c in $connectors) {
    $d = $c.GetAttribute('d').Trim()
    if ($dSeen.ContainsKey($d)) {
        Fail 'OVERLAP-PATH' "two connectors have an identical 'd' attribute (duplicate/overlapping path)"
    }
    $dSeen[$d] = $true
}

# ── LABEL-UNMASKED ─────────────────────────────────────────────────────────────
function Get-Xy($el) {
    $x = $el.GetAttribute('x'); $y = $el.GetAttribute('y')
    if (-not $x -or -not $y) { return $null }
    return @{ X = [double]$x; Y = [double]$y }
}
foreach ($lbl in $labels) {
    $pos = Get-Xy $lbl
    if (-not $pos) { Fail 'LABEL-UNMASKED' "edge-label has no x/y position to verify masking"; continue }
    $masked = $false
    foreach ($r in $allRects) {
        if ($r.GetAttribute('id')) { continue }  # box/node rects don't count as label masks
        $rx = $r.GetAttribute('x'); $ry = $r.GetAttribute('y')
        $rw = $r.GetAttribute('width'); $rh = $r.GetAttribute('height')
        if (-not $rx -or -not $ry -or -not $rw -or -not $rh) { continue }
        $rx = [double]$rx; $ry = [double]$ry; $rw = [double]$rw; $rh = [double]$rh
        if ($pos.X -ge $rx -and $pos.X -le ($rx + $rw) -and $pos.Y -ge $ry -and $pos.Y -le ($ry + $rh)) {
            $masked = $true
            break
        }
    }
    if (-not $masked) {
        Fail 'LABEL-UNMASKED' "edge-label at ($($pos.X),$($pos.Y)) has no background rect beneath it — it will render directly over any crossing stroke"
    }
}

# ── CLIPPED-LABEL ──────────────────────────────────────────────────────────────
foreach ($t in $allText) {
    if ($t.GetAttribute('clip-path')) {
        Fail 'CLIPPED-LABEL' "text element '$($t.InnerText)' carries a clip-path attribute"
    }
}

# ── TRANSIT-BEHIND ─────────────────────────────────────────────────────────────
function Get-PathBBox($d) {
    $coords = [regex]::Matches($d, '(-?\d+(\.\d+)?)[,\s]+(-?\d+(\.\d+)?)') | ForEach-Object {
        [pscustomobject]@{ X = [double]$_.Groups[1].Value; Y = [double]$_.Groups[3].Value }
    }
    if ($coords.Count -eq 0) { return $null }
    return @{
        MinX = ($coords.X | Measure-Object -Minimum).Minimum
        MaxX = ($coords.X | Measure-Object -Maximum).Maximum
        MinY = ($coords.Y | Measure-Object -Minimum).Minimum
        MaxY = ($coords.Y | Measure-Object -Maximum).Maximum
    }
}
foreach ($c in $connectors) {
    $bbox = Get-PathBBox $c.GetAttribute('d')
    if (-not $bbox) { continue }
    $fromId = $c.GetAttribute('data-from'); $toId = $c.GetAttribute('data-to')
    foreach ($b in $boxes) {
        $id = $b.GetAttribute('id')
        if ($id -eq $fromId -or $id -eq $toId) { continue }  # endpoints are allowed to touch
        $bx = [double]$b.GetAttribute('x'); $by = [double]$b.GetAttribute('y')
        $bw = [double]$b.GetAttribute('width'); $bh = [double]$b.GetAttribute('height')
        $overlapsX = $bbox.MinX -lt ($bx + $bw) -and $bbox.MaxX -gt $bx
        $overlapsY = $bbox.MinY -lt ($by + $bh) -and $bbox.MaxY -gt $by
        if ($overlapsX -and $overlapsY) {
            Fail 'TRANSIT-BEHIND' "connector '$fromId->$toId' passes through non-endpoint box '$id'"
        }
    }
}

if ($script:FailCount -gt 0) {
    Write-Host "lint-diagram-geometry: $($script:FailCount) failure(s) in '$SvgPath'."
    exit 1
}
Log "lint-diagram-geometry: '$SvgPath' passed all checks."

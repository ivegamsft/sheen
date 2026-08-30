#!/usr/bin/env pwsh
# build-icons.ps1 — vendor-icon build step for the documentation-diagram
# renderer (#111, part of epic #110).
#
# Reads the curated Tabler Icons subset in vendor/tabler-icons/icons/outline/
# and emits:
#   dist/icons/<name>.svg   — normalized copy (24x24, stroke="currentColor")
#                              ready to inline into diagram SVG output; the
#                              diagram-skin adapter (#116) supplies the
#                              `color` value via CSS, so no hex is ever
#                              baked into an icon file (ADR-005).
#   dist/icons/manifest.json — { name, file, sourceCommit } per icon, so the
#                              renderer (#113) and any consumer can resolve
#                              an icon by name without re-scanning the tree.
#   docs/foundations/icon-gallery.md — generated reference gallery (name,
#                              preview, diagram-type usage) — regenerated on
#                              every run, never hand-edited.
#
# -Add <name> fetches one additional icon from the pinned upstream commit
# (vendor/tabler-icons/VENDOR.md) into vendor/tabler-icons/icons/outline/
# and re-runs the normal build. This is how new icons should be vendored —
# never hand-copy an SVG into vendor/tabler-icons/.
#
# dist/ is git-ignored and rebuilt fresh in CI on every run (same convention
# as dist/tokens/* and dist/diagram-skins/*).

param(
    [string]$Add,
    [switch]$Check
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$vendorDir = Join-Path $repoRoot "vendor\tabler-icons\icons\outline"
$vendorMetaPath = Join-Path $repoRoot "vendor\tabler-icons\VENDOR.md"
$distDir = Join-Path $repoRoot "dist\icons"
$galleryPath = Join-Path $repoRoot "docs\foundations\icon-gallery.md"

# Diagram-type usage map — mirrors the table in vendor/tabler-icons/VENDOR.md.
# Keyed by icon file name (no extension).
$UsageMap = [ordered]@{
    "chart-bar"      = "Bar"
    "chart-line"     = "Line"
    "chart-sankey"   = "Sankey"
    "chart-treemap"  = "Treemap"
    "calendar-time"  = "Gantt"
    "layout-kanban"  = "Kanban"
    "route"          = "Story map"
    "map"            = "User journey"
    "grid-dots"      = "Quadrant"
    "category"       = "Fishbone"
    "chart-funnel"   = "Pyramid/funnel"
    "hierarchy-2"    = "Org chart"
    "refresh"        = "Loop/flywheel"
    "timeline"       = "Timeline"
    "circles"        = "Venn"
    "shield-lock"    = "DP security matrix"
    "users"          = "(support) generic person/role node"
    "database"       = "(support) generic data-store node"
    "lock"           = "(support) generic access-control annotation"
}

function Get-PinnedCommit {
    if (-not (Test-Path $vendorMetaPath)) {
        throw "Cannot resolve pinned commit: $vendorMetaPath not found."
    }
    $line = Select-String -Path $vendorMetaPath -Pattern '^\| Commit \| `([0-9a-f]{40})`' | Select-Object -First 1
    if (-not $line) {
        throw "Cannot find a pinned commit SHA in $vendorMetaPath."
    }
    return $line.Matches[0].Groups[1].Value
}

if ($Add) {
    $commit = Get-PinnedCommit
    $url = "https://raw.githubusercontent.com/tabler/tabler-icons/$commit/icons/outline/$Add.svg"
    $dest = Join-Path $vendorDir "$Add.svg"
    Write-Host "Fetching $Add.svg from tabler-icons@$commit ..."
    Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $dest
    Write-Host "Vendored: $dest"
    Write-Host "Remember to: (1) add a row to vendor/tabler-icons/VENDOR.md's table, (2) add a `$UsageMap entry in this script if it maps to a diagram type."
}

if (-not (Test-Path $vendorDir)) {
    throw "Vendor icon source not found: $vendorDir"
}

$sourceIcons = Get-ChildItem -Path $vendorDir -Filter "*.svg" | Sort-Object Name
if (@($sourceIcons).Count -eq 0) {
    throw "No vendored icons found in $vendorDir"
}

$commit = Get-PinnedCommit
$manifest = @()

if (-not $Check) {
    New-Item -ItemType Directory -Force -Path $distDir | Out-Null
}

foreach ($icon in $sourceIcons) {
    $name = [IO.Path]::GetFileNameWithoutExtension($icon.Name)
    $raw = Get-Content -Path $icon.FullName -Raw

    # Strip the upstream `<!-- tags/category/version/unicode -->` metadata
    # comment block (if present) — it is not needed at runtime and keeps
    # dist/ output minimal.
    $normalized = [regex]::Replace($raw, '(?s)^\s*<!--.*?-->\s*', '')
    $normalized = $normalized.Trim() + "`n"

    if (-not $normalized.Contains('stroke="currentColor"')) {
        throw "$($icon.Name): expected stroke=`"currentColor`" (skin-adapter compatibility, ADR-005) but it was not found."
    }

    if (-not $Check) {
        Set-Content -Path (Join-Path $distDir "$name.svg") -Value $normalized -NoNewline
    }

    $manifest += [ordered]@{
        name         = $name
        file         = "$name.svg"
        usage        = $(if ($UsageMap.Contains($name)) { $UsageMap[$name] } else { "(unmapped — add to `$UsageMap in build-icons.ps1)" })
        sourceCommit = $commit
    }
}

if (-not $Check) {
    $manifestJson = ($manifest | ConvertTo-Json -Depth 4)
    Set-Content -Path (Join-Path $distDir "manifest.json") -Value $manifestJson -NoNewline

    # Icons are inlined as raw SVG markup (not <img src="dist/...">) so the
    # gallery page renders correctly in the published mkdocs site without
    # depending on the git-ignored dist/ build artifact being present at
    # `mkdocs build` time — docs.yml builds the site independently of the
    # tokens/icons CI job.
    $galleryLines = @(
        "---"
        "title: Diagram Icon Gallery"
        "description: Generated reference of the vendored icon subset used by the documentation-diagram renderer."
        "---"
        ""
        "# Diagram Icon Gallery"
        ""
        '> Generated by `scripts/build-icons.ps1`. Do not hand-edit — re-run the'
        '> script after changing the vendored icon set or the usage map.'
        ""
        "Source: [Tabler Icons](https://github.com/tabler/tabler-icons) (MIT),"
        "pinned commit ``$commit``. Full attribution in"
        '[`THIRD_PARTY_LICENSES.md`](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/THIRD_PARTY_LICENSES.md) and'
        '[`vendor/tabler-icons/VENDOR.md`](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/vendor/tabler-icons/VENDOR.md).'
        ""
        'All icons use `stroke="currentColor"` so they inherit their color'
        "from the diagram-skin adapter (#116) — never a hard-coded hex. At"
        'runtime, consumers should resolve icons from `dist/icons/manifest.json`'
        "(built fresh in CI); the previews below are inlined directly so this"
        "page renders without a build step."
        ""
        "<table>"
        "<thead><tr><th>Icon</th><th>Name</th><th>Used by</th></tr></thead>"
        "<tbody>"
    )
    foreach ($m in $manifest) {
        $svgPath = Join-Path $vendorDir "$($m.name).svg"
        $svgRaw = Get-Content -Path $svgPath -Raw
        $svgInline = [regex]::Replace($svgRaw, '(?s)^\s*<!--.*?-->\s*', '').Trim()
        # Force a small, consistent preview size regardless of the source width/height attrs.
        $svgInline = $svgInline -replace 'width="24"', 'width="28"' -replace 'height="24"', 'height="28"'
        $galleryLines += "<tr><td>$svgInline</td><td><code>$($m.name)</code></td><td>$($m.usage)</td></tr>"
    }
    $galleryLines += @(
        "</tbody>"
        "</table>"
    )
    Set-Content -Path $galleryPath -Value ($galleryLines -join "`n") -NoNewline
    Write-Host "build-icons: wrote $($manifest.Count) icons to dist\icons\ and regenerated $galleryPath"
} else {
    Write-Host "build-icons --check: OK ($($manifest.Count) icons validated, all stroke=`"currentColor`")"
}

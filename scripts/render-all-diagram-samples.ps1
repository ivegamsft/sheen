#!/usr/bin/env pwsh
# render-all-diagram-samples.ps1 — batch-render every documentation-diagram
# sample to static HTML for visual-regression screenshotting (#129).
#
# Wraps scripts/render-diagram.ps1 (#113) in a loop over
# skills/documentation-diagram/samples/*.json so both CI and local dev share
# one source of truth for "what gets rendered before Playwright runs".
#
# Usage:
#   pwsh scripts/render-all-diagram-samples.ps1 [-OutDir <dir>] [-Theme light|dark|high-contrast]

param(
    [string]$OutDir = (Join-Path $PSScriptRoot '..' 'dist' 'documentation-diagram-out'),
    [string]$Theme = 'light'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$samplesDir = Join-Path $repoRoot 'skills' 'documentation-diagram' 'samples'
$renderScript = Join-Path $PSScriptRoot 'render-diagram.ps1'

if (-not (Test-Path $samplesDir)) {
    throw "Samples directory not found: $samplesDir"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = Resolve-Path $OutDir

$samples = Get-ChildItem -Path $samplesDir -Filter '*.json' | Sort-Object Name
if ($samples.Count -eq 0) {
    throw "No sample specs found under $samplesDir"
}

foreach ($sample in $samples) {
    $name = $sample.BaseName
    $outPath = Join-Path $OutDir "$name.html"
    Write-Host "Rendering $name -> $outPath"
    & pwsh -NonInteractive -File $renderScript -Type $name -SpecPath $sample.FullName -OutPath $outPath -Theme $Theme
    if ($LASTEXITCODE -ne 0) {
        throw "render-diagram.ps1 failed for sample '$name' (exit $LASTEXITCODE)"
    }
}

Write-Host "Rendered $($samples.Count) documentation-diagram samples to $OutDir (theme=$Theme)."

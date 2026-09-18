#!/usr/bin/env pwsh
# Refresh CLI (spec 14 section 5.3 "Refresh"). CURRENT guides are a no-op.
# STALE/UNKNOWN guides return PARTIAL and perform no write until a separately
# authorized regenerator updates owned content and provenance evidence.
# Bundled skill-local; no top-level repository script is required (H14, H21).
param(
    [Parameter(Mandatory)][string]$GuidePath,
    [Parameter(Mandatory)][string]$ManifestPath,
    [string]$RepoRoot = (Get-Location).Path,
    [switch]$Apply,
    [switch]$Force,
    [switch]$Quiet
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3
Import-Module (Join-Path $PSScriptRoot 'GuideInputs.psm1') -Force

$result = Invoke-GuideRefresh -GuidePath $GuidePath -ManifestPath $ManifestPath -RepoRoot $RepoRoot -Apply:$Apply -Force:$Force
if (-not $Quiet) { $result | ConvertTo-Json -Depth 10 }
if ($result.Result -in @('BLOCKED', 'PARTIAL')) { exit 1 } else { exit 0 }
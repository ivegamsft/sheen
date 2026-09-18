#!/usr/bin/env pwsh
# Read-only freshness check CLI for a single guide (spec 14 section 5.3
# "Check"). Never writes the guide, its sources or any metadata/timestamp;
# see references/guide-contract.md. Bundled skill-local; no top-level
# repository script is required (H14, H21).
param(
    [Parameter(Mandatory)][string]$GuidePath,
    [Parameter(Mandatory)][string]$ManifestPath,
    [string]$RepoRoot = (Get-Location).Path,
    [switch]$Quiet
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3
Import-Module (Join-Path $PSScriptRoot 'GuideInputs.psm1') -Force

$result = Test-GuideFreshness -GuidePath $GuidePath -ManifestPath $ManifestPath -RepoRoot $RepoRoot
if (-not $Quiet) {
    [pscustomobject]@{
        overall = $result.Overall
        modules = $result.Modules
        reasons = $result.Reasons
        actions = $result.Actions
    } | ConvertTo-Json -Depth 10
}
if ($result.Overall -eq 'CURRENT') { exit 0 } else { exit 1 }
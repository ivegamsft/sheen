#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory)][string]$MarkdownPath,
    [Parameter(Mandatory)][string]$OutputPath,
    [ValidateSet('self-contained', 'local-bundle')][string]$Packaging = 'self-contained',
    [ValidateSet('reference-manual', 'presentation-inspired', 'quick-reference')][string]$Profile = 'reference-manual',
    [string]$AssetManifestPath,
    [string]$RepoRoot = (Get-Location).Path,
    [int]$BudgetBytes = 0,
    [string]$OverrideRationale,
    [string]$OverrideAuthorizer,
    [ValidatePattern('^[A-Za-z]{2,8}(-[A-Za-z0-9]{1,8})*$')][string]$Language = 'en',
    [switch]$Quiet
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3
Import-Module (Join-Path $PSScriptRoot 'GuideHtml.psm1') -Force

$result = New-StyleGuideHtml `
    -MarkdownPath $MarkdownPath `
    -OutputPath $OutputPath `
    -Packaging $Packaging `
    -Profile $Profile `
    -AssetManifestPath $AssetManifestPath `
    -RepoRoot $RepoRoot `
    -BudgetBytes $BudgetBytes `
    -OverrideRationale $OverrideRationale `
    -OverrideAuthorizer $OverrideAuthorizer `
    -Language $Language

if (-not $Quiet) { $result | ConvertTo-Json -Depth 10 }
if ($result.State -eq 'BLOCKED') { exit 1 } else { exit 0 }

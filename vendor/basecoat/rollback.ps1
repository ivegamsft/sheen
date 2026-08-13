#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Rolls a consumer repo back to a specific BaseCoat release tag.

.DESCRIPTION
    Re-syncs .github/base-coat/ from any tagged BaseCoat release.
    The prior version is read from .github/base-coat/version.json before overwriting.
    Run from the root of a consumer repository.

.PARAMETER Tag
    The BaseCoat release tag to roll back to (e.g. v3.25.0).
    If omitted, shows the current version and the 5 most-recent release tags.

.PARAMETER Repo
    The BaseCoat GitHub repository (HTTPS clone URL).
    Defaults to the BASECOAT_REPO env var, then 'https://github.com/YOUR-ORG/basecoat.git'.

.PARAMETER TargetDir
    Directory in the consumer repo where BaseCoat assets live.
    Defaults to '.github/base-coat'.

.EXAMPLE
    pwsh rollback.ps1 -Tag v3.25.0
    pwsh rollback.ps1 -Tag v3.24.1 -Repo https://github.com/my-org/basecoat.git
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Tag = '',
    [string]$Repo = '',
    [string]$TargetDir = ''
)

$ErrorActionPreference = 'Stop'

$sourceRepo = if ($Repo)      { $Repo }      `
  elseif ($env:BASECOAT_REPO) { $env:BASECOAT_REPO } `
  else                        { 'https://github.com/YOUR-ORG/basecoat.git' }

$targetDir = if ($TargetDir)        { $TargetDir }        `
  elseif ($env:BASECOAT_TARGET_DIR) { $env:BASECOAT_TARGET_DIR } `
  else                              { '.github/base-coat' }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git is required'
}

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    throw 'Run this inside a git repository'
}

$fullTargetDir = Join-Path $repoRoot $targetDir

# ── Show current version and available tags if no tag given ──────────────────

if (-not $Tag) {
    $versionFile = Join-Path $fullTargetDir 'version.json'
    $currentVersion = if (Test-Path $versionFile) {
        (Get-Content $versionFile -Raw | ConvertFrom-Json).version
    } else {
        'unknown'
    }
    Write-Host "Current BaseCoat version : v$currentVersion"
    Write-Host ""
    Write-Host "Recent release tags:"
    git ls-remote --tags --sort='-version:refname' $sourceRepo 'v*' 2>$null |
        Select-String 'refs/tags/(v[\d\.]+)$' |
        ForEach-Object { "  " + $_.Matches[0].Groups[1].Value } |
        Select-Object -First 10
    Write-Host ""
    Write-Host "Usage: pwsh rollback.ps1 -Tag <tag>"
    exit 0
}

# ── Normalise tag ─────────────────────────────────────────────────────────────

if (-not $Tag.StartsWith('v')) { $Tag = "v$Tag" }

# ── Confirm rollback ──────────────────────────────────────────────────────────

$versionFile = Join-Path $fullTargetDir 'version.json'
$priorVersion = if (Test-Path $versionFile) {
    (Get-Content $versionFile -Raw | ConvertFrom-Json).version
} else {
    'unknown'
}

Write-Host "Rolling back BaseCoat: v$priorVersion  →  $Tag"
Write-Host "Source : $sourceRepo"
Write-Host "Target : $fullTargetDir"
Write-Host ""

if (-not $PSCmdlet.ShouldProcess($fullTargetDir, "rollback to $Tag")) {
    exit 0
}

# ── Clone the target tag ──────────────────────────────────────────────────────

$tempRoot   = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
$sourcePath = Join-Path $tempRoot 'source'

try {
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
    Write-Host "Cloning $Tag from $sourceRepo ..."
    git clone --quiet --depth 1 --branch $Tag $sourceRepo $sourcePath

    # ── Sync assets ─────────────────────────────────────────────────────────

    New-Item -ItemType Directory -Force -Path $fullTargetDir | Out-Null

    foreach ($item in @('README.md', 'CHANGELOG.md', 'version.json',
                         'basecoat-metadata.json', 'instructions',
                         'skills', 'prompts', 'agents', 'docs')) {
        $src = Join-Path $sourcePath $item
        if (-not (Test-Path $src)) { continue }
        $dst = Join-Path $fullTargetDir $item
        if (Test-Path $dst) { Remove-Item -Path $dst -Recurse -Force }
        Copy-Item -Path $src -Destination $dst -Recurse -Force
    }

    # Backwards-compat: copy INVENTORY.md to target root
    $inventorySrc = Join-Path $sourcePath 'docs/reference/INVENTORY.md'
    if (Test-Path $inventorySrc) {
        Copy-Item -Path $inventorySrc -Destination (Join-Path $fullTargetDir 'INVENTORY.md') -Force
    }

    Write-Host ""
    Write-Host "✓ Rolled back to $Tag successfully."
    Write-Host "  Run 'git diff --stat' to review changes before committing."
} finally {
    if (Test-Path $tempRoot) {
        Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

#!/usr/bin/env pwsh
# rollback.ps1 --- basecoat-sheen consumer rollback (PowerShell)
#
# Reverts the last sync by removing exactly the files/directories recorded in
# .sheen/manifest.json. Consumer-authored files outside the manifest are never
# touched. Behavior-equivalent to rollback.sh.
#
# Usage:
#   ./rollback.ps1                  # revert the last sync (.sheen/manifest.json)
#   ./rollback.ps1 -Manifest path   # revert a specific manifest
#
# See specs/06-consumption-sync.spec.md §3.

param([string]$Manifest)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is required' }
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { throw 'Run this inside a git repository' }

if (-not $Manifest) { $Manifest = Join-Path $repoRoot '.sheen/manifest.json' }
if (-not (Test-Path -LiteralPath $Manifest)) { throw "No manifest found at $Manifest --- nothing to roll back." }

$data = Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json
if (-not $data.files) { Write-Host 'rollback: manifest lists no files.'; return }

$removed = 0
foreach ($rel in $data.files) {
    $path = Join-Path $repoRoot $rel
    if (Test-Path -LiteralPath $path) {
        # New manifests record files only. For compatibility with older manifests that
        # recorded directories, do not recursively delete directory trees here — that
        # can remove consumer-authored files created after sync.
        if ((Get-Item -LiteralPath $path).PSIsContainer) {
            if (-not (Get-ChildItem -LiteralPath $path -Force)) {
                Remove-Item -LiteralPath $path -Force
            }
            continue
        }

        Remove-Item -LiteralPath $path -Force
        $removed++

        # Prune now-empty parent directories up to (but not including) repo root.
        $parent = Split-Path -Parent $path
        while ($parent -and ($parent -ne $repoRoot) -and (Test-Path -LiteralPath $parent) -and
               -not (Get-ChildItem -LiteralPath $parent -Force)) {
            Remove-Item -LiteralPath $parent -Force
            $parent = Split-Path -Parent $parent
        }
    }
}

Remove-Item -LiteralPath $Manifest -Force -ErrorAction SilentlyContinue
$sheenDir = Join-Path $repoRoot '.sheen'
if ((Test-Path -LiteralPath $sheenDir) -and -not (Get-ChildItem -LiteralPath $sheenDir -Force)) {
    Remove-Item -LiteralPath $sheenDir -Force
}
Write-Host ("rollback: removed {0} item(s)." -f $removed)

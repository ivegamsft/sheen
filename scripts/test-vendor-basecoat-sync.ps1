#!/usr/bin/env pwsh
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$syncPs1Path = Join-Path $repoRoot 'vendor/basecoat/sync.ps1'
$syncShPath = Join-Path $repoRoot 'vendor/basecoat/sync.sh'

function Assert-FileExists([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "ASSERTION FAILED: required vendored BaseCoat sync file is missing: $Path"
    }
}

function Assert-Contains([string]$Text, [string]$Needle, [string]$Message) {
    if (-not $Text.Contains($Needle)) {
        throw "ASSERTION FAILED: $Message"
    }
}

function Assert-NoLineMatches([string]$Text, [string]$Pattern, [string]$Message) {
    $lines = $Text -split "`r?`n"
    $matches = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $Pattern) {
            $matches += ('line {0}: {1}' -f ($i + 1), $lines[$i])
        }
    }
    if ($matches.Count -gt 0) {
        throw "ASSERTION FAILED: $Message`n$($matches -join "`n")"
    }
}

Assert-FileExists $syncPs1Path
Assert-FileExists $syncShPath

$syncPs1 = Get-Content -LiteralPath $syncPs1Path -Raw
$syncSh = Get-Content -LiteralPath $syncShPath -Raw

Assert-Contains $syncPs1 'Copy-ManagedOverlayTree' 'vendored sync.ps1 must contain BaseCoat #3415 per-file shared-overlay copy logic'
Assert-Contains $syncPs1 '$staleOverlayFiles = $prevOverlayFiles | Where-Object { $overlayManagedFiles -notcontains $_ }' 'vendored sync.ps1 must prune only previously managed shared-overlay files'
Assert-Contains $syncPs1 'Removed stale BaseCoat-managed overlay file' 'vendored sync.ps1 must report managed stale-overlay pruning'
Assert-Contains $syncPs1 '.overlay-managed-files' 'vendored sync.ps1 must persist shared-overlay ownership state'
Assert-Contains $syncPs1 'BaseCoat must never wipe the destination directory wholesale' 'vendored sync.ps1 must document the shared-overlay no-wholesale-wipe invariant'

Assert-Contains $syncSh 'copy_managed_overlay_tree' 'vendored sync.sh must contain BaseCoat #3415 per-file shared-overlay copy logic'
Assert-Contains $syncSh 'comm -23 "$prev_overlay_file" "$new_overlay_file"' 'vendored sync.sh must prune only previously managed shared-overlay files'
Assert-Contains $syncSh 'Removed stale BaseCoat-managed overlay file' 'vendored sync.sh must report managed stale-overlay pruning'
Assert-Contains $syncSh '.overlay-managed-files' 'vendored sync.sh must persist shared-overlay ownership state'
Assert-Contains $syncSh 'BaseCoat must never wipe the destination directory wholesale' 'vendored sync.sh must document the shared-overlay no-wholesale-wipe invariant'

Assert-NoLineMatches $syncPs1 'Remove-Item\s+.*-Recurse\s+.*-Force\s+.*\.(github|agents)[\\/]' 'vendored sync.ps1 must not wholesale-delete shared Copilot overlay paths'
Assert-NoLineMatches $syncSh 'rm\s+-rf\s+"\$REPO_ROOT/\.(github|agents)(/|")' 'vendored sync.sh must not wholesale-delete shared Copilot overlay paths'

Write-Host 'Vendored BaseCoat sync overlay guard passed.'

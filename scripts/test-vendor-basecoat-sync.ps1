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

Assert-Contains $syncPs1 'Copy-ManagedOverlayTree' 'vendored sync.ps1 must contain per-file shared-overlay copy logic'
Assert-Contains $syncPs1 'GUIDANCE_CONTENT_MODIFIED' 'vendored sync.ps1 must refuse to prune modified guidance files'
Assert-Contains $syncPs1 'Removed stale BaseCoat-managed guidance file' 'vendored sync.ps1 must report hash-owned stale guidance pruning'
Assert-Contains $syncPs1 '.overlay-managed-files' 'vendored sync.ps1 must migrate legacy shared-overlay ownership state'

Assert-Contains $syncSh 'add_guidance_plan_tree' 'vendored sync.sh must contain per-file shared-overlay planning logic'
Assert-Contains $syncSh 'GUIDANCE_CONTENT_MODIFIED' 'vendored sync.sh must refuse to prune modified guidance files'
Assert-Contains $syncSh 'Removed stale BaseCoat-managed guidance file' 'vendored sync.sh must report hash-owned stale guidance pruning'
Assert-Contains $syncSh '.overlay-managed-files' 'vendored sync.sh must migrate legacy shared-overlay ownership state'
Assert-Contains $syncSh 'BaseCoat must never wipe the destination directory wholesale' 'vendored sync.sh must document the shared-overlay no-wholesale-wipe invariant'
Assert-NoLineMatches $syncPs1 'Remove-Item\s+.*-Recurse\s+.*-Force\s+.*\.(github|agents)[\\/]' 'vendored sync.ps1 must not wholesale-delete shared Copilot overlay paths'
Assert-NoLineMatches $syncSh 'rm\s+-rf\s+"\$REPO_ROOT/\.(github|agents)(/|")' 'vendored sync.sh must not wholesale-delete shared Copilot overlay paths'

$preflightPath = Join-Path $repoRoot 'vendor/basecoat/scripts/validate-pr-intake-preflight.cjs'
$evaluatorPath = Join-Path $repoRoot 'vendor/basecoat/.github/base-coat/scripts/pr-decomposition-evaluator.cjs'
if ((Test-Path -LiteralPath $preflightPath) -or (Test-Path -LiteralPath $evaluatorPath)) {
    throw 'ASSERTION FAILED: upstream-only PR control-plane entrypoint and evaluator must remain excluded together'
}

Write-Host 'Vendored BaseCoat sync overlay guard passed.'

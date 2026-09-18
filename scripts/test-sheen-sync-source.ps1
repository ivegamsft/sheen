#!/usr/bin/env pwsh
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

function Read-RepoText([string]$RelativePath) {
    return Get-Content -LiteralPath (Join-Path $repoRoot $RelativePath) -Raw
}

function Assert-Contains([string]$Text, [string]$Needle, [string]$Message) {
    if (-not $Text.Contains($Needle)) { throw "ASSERTION FAILED: $Message" }
}

function Assert-NotContains([string]$Text, [string]$Needle, [string]$Message) {
    if ($Text.Contains($Needle)) { throw "ASSERTION FAILED: $Message" }
}

Write-Host '[1/5] standalone sync defaults use the public mirror'
$syncSh = Read-RepoText 'sync.sh'
$syncPs1 = Read-RepoText 'sync.ps1'
Assert-Contains $syncSh 'DEFAULT_SOURCE="https://github.com/ivegamsft/sheen.git"' 'sync.sh must not require private source credentials by default'
Assert-Contains $syncPs1 '$DefaultSource = ''https://github.com/ivegamsft/sheen.git''' 'sync.ps1 must not require private source credentials by default'
Assert-Contains $syncSh "grep -Fq 'source_repo: IBuySpy-Shared/basecoat-sheen'" 'sync.sh must migrate managed workflows that still point at the private source'
Assert-Contains $syncPs1 '$existingWorkflow.Contains(''source_repo: IBuySpy-Shared/basecoat-sheen'')' 'sync.ps1 must migrate managed workflows that still point at the private source'

Write-Host '[2/5] bootstrap-generated .sheen.yml defaults use the public mirror'
$bootstrapSh = Read-RepoText 'bootstrap.sh'
$bootstrapPs1 = Read-RepoText 'bootstrap.ps1'
Assert-Contains $bootstrapSh 'SOURCE="${SHEEN_SOURCE:-https://github.com/ivegamsft/sheen.git}"' 'bootstrap.sh must generate public mirror source by default'
Assert-Contains $bootstrapPs1 '[string]$Source = ''https://github.com/ivegamsft/sheen.git''' 'bootstrap.ps1 must generate public mirror source by default'
Assert-Contains (Read-RepoText '.sheen.yml.example') 'source: https://github.com/ivegamsft/sheen.git' '.sheen.yml.example must scaffold the public mirror source'
Assert-Contains (Read-RepoText 'docs/getting-started/quick-start.md') 'source: https://github.com/ivegamsft/sheen.git' 'quick-start guide must scaffold the public mirror source'

Write-Host '[3/5] scheduled sync template uses internal callable but public asset source'
$template = Read-RepoText 'templates/sheen-sync.yml'
Assert-Contains $template 'uses: IBuySpy-Shared/basecoat-sheen/.github/workflows/check-sheen-version-callable.yml@' 'scheduled sync must keep using the internal callable workflow host'
Assert-Contains $template 'source_repo: ivegamsft/sheen' 'scheduled sync must use public mirror assets by default'
Assert-NotContains $template 'source_repo: IBuySpy-Shared/basecoat-sheen' 'scheduled sync template must not clone the private source by default'
Assert-Contains $template 'Not required for the default public ivegamsft/sheen mirror.' 'template must document that fetch_token is optional for the default source'

Write-Host '[4/5] callable workflow falls back from private source to public mirror when no fetch token is provided'
$callable = Read-RepoText '.github/workflows/check-sheen-version-callable.yml'
Assert-Contains $callable 'default: ivegamsft/sheen' 'callable source_repo default must be public'
Assert-Contains $callable 'SHEEN_FETCH_TOKEN: ${{ secrets.fetch_token }}' 'callable must evaluate fetch token availability without logging token values'
Assert-Contains $callable 'NORMALIZED_SOURCE="${SOURCE#https://github.com/}"' 'callable must normalize URL-style .sheen.yml source values'
Assert-Contains $callable 'if [[ "$NORMALIZED_SOURCE" == "IBuySpy-Shared/basecoat-sheen" && -z "${SHEEN_FETCH_TOKEN:-}" ]]; then' 'callable must detect private source without fetch token'
Assert-Contains $callable 'SOURCE="ivegamsft/sheen"' 'callable must fall back to public mirror for private source without fetch token'
Assert-Contains $callable 'Using public Sheen mirror' 'callable must emit an actionable fallback notice'

Write-Host '[5/5] production publication preserves the internal callable workflow host'
$publish = Read-RepoText '.github/workflows/publish-to-production.yml'
Assert-Contains $publish 'templates/sheen-sync.yml' 'publish workflow must explicitly handle the generated sync template'
Assert-Contains $publish 'uses: IBuySpy-Shared/basecoat-sheen/.github/workflows/check-sheen-version-callable.yml@' 'publish workflow must restore the internal callable host after public mirror sanitization'

Write-Host 'Sheen sync source/token fallback contract passed.'

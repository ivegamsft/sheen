#!/usr/bin/env pwsh
param(
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { throw 'Run this inside a git repository' }
Set-Location $repoRoot

$outPath = Join-Path $repoRoot 'sheen-metadata.json'
$version = if (Test-Path 'version.json') { (Get-Content version.json -Raw | ConvertFrom-Json).version } else { '0.0.0' }

function Get-FrontmatterLines([string]$path) {
    $lines = Get-Content -LiteralPath $path
    if ($lines.Count -lt 3 -or $lines[0].Trim() -ne '---') { return @() }
    $end = -1
    for ($i = 1; $i -lt [Math]::Min(80, $lines.Count); $i++) {
        if ($lines[$i].Trim() -eq '---') { $end = $i; break }
    }
    if ($end -lt 0) { return @() }
    return $lines[1..($end-1)]
}

function Get-FMValue([string[]]$fm, [string]$key) {
    foreach ($line in $fm) {
        if ($line -match "^\s*$([regex]::Escape($key)):\s*(.+?)\s*$") {
            return $Matches[1].Trim().Trim("'`"")
        }
    }
    return $null
}

function Get-Rel([string]$path) {
    return [System.IO.Path]::GetRelativePath($repoRoot, $path).Replace('\','/')
}

function Get-Hash([string]$path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
}

$skillItems = @()
Get-ChildItem skills -Directory -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
    $skillFile = Join-Path $_.FullName 'SKILL.md'
    if (-not (Test-Path $skillFile)) { return }
    $fm = Get-FrontmatterLines $skillFile
    $skillItems += [ordered]@{
        name        = $_.Name
        path        = Get-Rel $skillFile
        folder      = Get-Rel $_.FullName
        category    = Get-FMValue $fm 'category'
        pillar      = Get-FMValue $fm 'pillar'
        maturity    = Get-FMValue $fm 'maturity'
        description = Get-FMValue $fm 'description'
        hash        = Get-Hash $skillFile
    }
}

$agentItems = @()
Get-ChildItem agents -Filter '*.agent.md' -File -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
    $fm = Get-FrontmatterLines $_.FullName
    $agentItems += [ordered]@{
        name        = $_.BaseName -replace '\.agent$',''
        path        = Get-Rel $_.FullName
        pillar      = Get-FMValue $fm 'pillar'
        maturity    = Get-FMValue $fm 'maturity'
        description = Get-FMValue $fm 'description'
        hash        = Get-Hash $_.FullName
    }
}

$instructionItems = @()
Get-ChildItem instructions -Filter '*.instructions.md' -File -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
    $fm = Get-FrontmatterLines $_.FullName
    $instructionItems += [ordered]@{
        name        = $_.BaseName -replace '\.instructions$',''
        path        = Get-Rel $_.FullName
        band        = Get-FMValue $fm 'band'
        layer       = Get-FMValue $fm 'layer'
        description = Get-FMValue $fm 'description'
        hash        = Get-Hash $_.FullName
    }
}

$themes = @()
Get-ChildItem tokens\themes -Filter '*.tokens.json' -File -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
    $themes += [ordered]@{
        name = $_.BaseName -replace '\.tokens$',''
        path = Get-Rel $_.FullName
        hash = Get-Hash $_.FullName
    }
}

$coreCount = (Get-ChildItem tokens\core -Filter '*.tokens.json' -File -ErrorAction SilentlyContinue | Measure-Object).Count
$semanticCount = (Get-ChildItem tokens\semantic -Filter '*.tokens.json' -File -ErrorAction SilentlyContinue | Measure-Object).Count
$themeCount = $themes.Count
$promptNames = @(
    Get-ChildItem prompts -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne '.gitkeep' } |
    Sort-Object Name |
    ForEach-Object { $_.BaseName }
)
$templateNames = @(
    Get-ChildItem templates -File -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne '.gitkeep' } |
    Sort-Object FullName |
    ForEach-Object { $_.BaseName }
)

$obj = [ordered]@{
    '$comment' = 'GENERATED FILE — do not hand-edit. Produced by scripts/build-metadata.ps1 from repo-root assets (vendor/ excluded).'
    schema   = 'sheen-metadata/v1'
    name     = 'basecoat-sheen'
    version  = $version
    generated = $null
    source = [ordered]@{
        excluded = @('vendor/')
    }
    counts = [ordered]@{
        skills = $skillItems.Count
        agents = $agentItems.Count
        instructions = $instructionItems.Count
        prompts = $promptNames.Count
        templates = $templateNames.Count
        tokens = [ordered]@{
            core = $coreCount
            semantic = $semanticCount
            themes = $themeCount
        }
    }
    assets = [ordered]@{
        skills = @($skillItems | ForEach-Object { $_.name })
        agents = @($agentItems | ForEach-Object { $_.name })
        instructions = @($instructionItems | ForEach-Object { $_.name })
        prompts = $promptNames
        templates = $templateNames
        themes = @($themes | ForEach-Object { $_.name })
    }
    inventory = [ordered]@{
        skills = $skillItems
        agents = $agentItems
        instructions = $instructionItems
        themes = $themes
    }
}

$newJson = ($obj | ConvertTo-Json -Depth 10)
function Normalize-JsonText([string]$text) {
    return (($text -replace "^\uFEFF", '') -replace "`r`n", "`n").TrimEnd()
}

if ($Check) {
    if (-not (Test-Path $outPath)) {
        Write-Host "::error::sheen-metadata.json missing"
        exit 1
    }
    $oldJson = Get-Content $outPath -Raw
    if ((Normalize-JsonText $oldJson) -ne (Normalize-JsonText $newJson)) {
        Write-Host "::error::sheen-metadata.json is out of date. Run scripts/build-metadata.ps1"
        exit 1
    }
    Write-Host "build-metadata --check: OK"
    exit 0
}

Set-Content -LiteralPath $outPath -Value $newJson -Encoding utf8NoBOM
Write-Host "build-metadata: wrote sheen-metadata.json"
exit 0

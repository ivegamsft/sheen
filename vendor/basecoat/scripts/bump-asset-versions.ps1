#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [string]$BaseRef = "origin/main",
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

function Get-NextPatchVersion {
    param([string]$Current)
    if ($Current -notmatch '^([0-9]+)\.([0-9]+)\.([0-9]+)$') { return "1.0.0" }
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3] + 1
    return "$major.$minor.$patch"
}

function Update-AssetVersion {
    param(
        [string]$Path,
        [switch]$ApplyChange
    )

    $content = Get-Content -Path $Path -Raw
    if ($content -notmatch '^---\r?\n([\s\S]+?)\r?\n---') {
        return $null
    }
    $frontmatter = $matches[1]
    $newContent = $content
    $oldVersion = $null
    $newVersion = $null

    if ($frontmatter -match '(?m)^version:\s*["'']?([0-9]+\.[0-9]+\.[0-9]+)["'']?\s*$') {
        $oldVersion = $matches[1]
        $newVersion = Get-NextPatchVersion $oldVersion
        $newFrontmatter = [regex]::Replace(
            $frontmatter,
            '(?m)^version:\s*["'']?[0-9]+\.[0-9]+\.[0-9]+["'']?\s*$',
            "version: $newVersion"
        )
        $newContent = $content -replace [regex]::Escape($frontmatter), [System.Text.RegularExpressions.Regex]::Escape($newFrontmatter)
        # Rebuild content safely to avoid regex-escape artifacts
        $newContent = "---`n$newFrontmatter`n---" + ($content -replace '^---\r?\n[\s\S]+?\r?\n---', '')
    }
    else {
        $oldVersion = $null
        $newVersion = "1.0.0"
        # insert version after description if possible; otherwise after name
        if ($frontmatter -match '(?m)^description:\s*.+$') {
            $newFrontmatter = [regex]::Replace(
                $frontmatter,
                '(?m)^(description:\s*.+)$',
                "`$1`nversion: $newVersion"
            )
        }
        else {
            $newFrontmatter = $frontmatter + "`nversion: $newVersion"
        }
        $newContent = "---`n$newFrontmatter`n---" + ($content -replace '^---\r?\n[\s\S]+?\r?\n---', '')
    }

    if ($ApplyChange) {
        Set-Content -Path $Path -Value $newContent -Encoding utf8
    }

    return [PSCustomObject]@{
        path = $Path
        oldVersion = $oldVersion
        newVersion = $newVersion
    }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

$changed = git diff --name-only "$BaseRef...HEAD" | Where-Object {
    $_ -match '^agents/.+\.agent\.md$' -or
    $_ -match '^instructions/.+\.instructions\.md$' -or
    $_ -match '^prompts/.+\.prompt\.md$' -or
    $_ -match '^skills/.+/SKILL\.md$'
}

if (-not $changed) {
    Write-Host "No changed versionable assets found against $BaseRef"
    exit 0
}

$updates = @()
foreach ($file in $changed) {
    $u = Update-AssetVersion -Path $file -ApplyChange:$Apply
    if ($u) { $updates += $u }
}

if (-not $updates) {
    Write-Host "No assets updated"
    exit 0
}

Write-Host "Asset version bumps:"
$updates | ForEach-Object {
    $from = if ($_.oldVersion) { $_.oldVersion } else { "(none)" }
    Write-Host "  $($_.path): $from -> $($_.newVersion)"
}

if (-not $Apply) {
    Write-Host ""
    Write-Host "Dry run only. Re-run with -Apply to write changes."
}

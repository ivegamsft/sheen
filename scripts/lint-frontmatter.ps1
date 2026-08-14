#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { throw 'Run this inside a git repository' }
Set-Location $repoRoot

$errors = New-Object System.Collections.Generic.List[string]

function Add-Err([string]$msg) { $errors.Add($msg) | Out-Null }

function Get-FrontmatterLines([string]$path) {
    $lines = Get-Content -LiteralPath $path
    if ($lines.Count -lt 3 -or $lines[0].Trim() -ne '---') { return @() }
    $end = -1
    for ($i = 1; $i -lt [Math]::Min(60, $lines.Count); $i++) {
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

function Get-EvalCounts([string]$evalPath) {
    $txt = Get-Content -LiteralPath $evalPath -Raw
    $pos = ([regex]::Matches($txt, 'expect_activation:\s*true')).Count
    $neg = ([regex]::Matches($txt, 'expect_activation:\s*false')).Count
    return @{ pos = $pos; neg = $neg }
}

# --- skills ---
$skillDirs = Get-ChildItem skills -Directory -ErrorAction SilentlyContinue
foreach ($dir in $skillDirs) {
    $skillPath = Join-Path $dir.FullName 'SKILL.md'
    $evalPath = Join-Path $dir.FullName 'eval.yaml'
    if (-not (Test-Path $skillPath)) { Add-Err "skills/$($dir.Name): missing SKILL.md"; continue }
    if (-not (Test-Path $evalPath)) { Add-Err "skills/$($dir.Name): missing eval.yaml" }

    $fm = Get-FrontmatterLines $skillPath
    if ($fm.Count -eq 0) { Add-Err "skills/$($dir.Name)/SKILL.md: missing valid frontmatter"; continue }

    $name = Get-FMValue $fm 'name'
    if (-not $name) { Add-Err "skills/$($dir.Name)/SKILL.md: missing frontmatter name" }
    elseif ($name -ne $dir.Name) { Add-Err "skills/$($dir.Name)/SKILL.md: name '$name' must match folder '$($dir.Name)'" }

    $desc = Get-FMValue $fm 'description'
    if (-not $desc) { Add-Err "skills/$($dir.Name)/SKILL.md: missing description" }
    else {
        if ($desc -notmatch 'USE FOR:') { Add-Err "skills/$($dir.Name): description missing 'USE FOR:'" }
        if ($desc -notmatch 'DO NOT USE FOR:') { Add-Err "skills/$($dir.Name): description missing 'DO NOT USE FOR:'" }
        if ($desc -match 'USE FOR:\s*([^\.]+)') {
            $triggers = @($Matches[1].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            if ($triggers.Count -lt 3) { Add-Err "skills/$($dir.Name): USE FOR must include >=3 triggers" }
        }
        if ($desc -match 'DO NOT USE FOR:\s*([^\.]+)') {
            $anti = @($Matches[1].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            if ($anti.Count -lt 2) { Add-Err "skills/$($dir.Name): DO NOT USE FOR must include >=2 anti-triggers" }
        }
    }

    if (Test-Path $evalPath) {
        $counts = Get-EvalCounts $evalPath
        if ($counts.pos -lt 3 -or $counts.neg -lt 2) {
            Add-Err "skills/$($dir.Name)/eval.yaml: requires >=3 positive and >=2 negative scenarios"
        }
    }
}

# --- agents ---
$agentFiles = Get-ChildItem agents -Filter '*.agent.md' -File -ErrorAction SilentlyContinue
foreach ($agent in $agentFiles) {
    $fm = Get-FrontmatterLines $agent.FullName
    if ($fm.Count -eq 0) { Add-Err "agents/$($agent.Name): missing valid frontmatter"; continue }
    $desc = Get-FMValue $fm 'description'
    if (-not $desc) { Add-Err "agents/$($agent.Name): missing description" }
    $eval = Join-Path $agent.DirectoryName (($agent.BaseName -replace '\.agent$','') + '.agent.eval.yaml')
    if (-not (Test-Path $eval)) { Add-Err "agents/$($agent.Name): missing eval file" }
}

# --- instructions ---
$instructionFiles = Get-ChildItem instructions -Filter '*.instructions.md' -File -ErrorAction SilentlyContinue
foreach ($ins in $instructionFiles) {
    if ($ins.Name -notmatch '^sheen-[0-9]{2}-[a-z0-9-]+\.instructions\.md$') {
        Add-Err "instructions/$($ins.Name): invalid naming"
    }
}

# --- reference integrity ---
$knownSkills = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
(Get-ChildItem skills -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) | ForEach-Object { $knownSkills.Add($_) | Out-Null }

# agent composes.skills
foreach ($agent in $agentFiles) {
    $txt = Get-Content -LiteralPath $agent.FullName -Raw
    $inSkills = $false
    foreach ($line in ($txt -split "`r?`n")) {
        if ($line -match '^\s*skills:\s*$') { $inSkills = $true; continue }
        if ($inSkills -and $line -match '^\s{0,2}[a-zA-Z]') { $inSkills = $false } # next top-level
        if ($inSkills -and $line -match '^\s*-\s*([a-z0-9-]+)\s*$') {
            $ref = $Matches[1]
            if (-not $knownSkills.Contains($ref)) { Add-Err "agents/$($agent.Name): composes.skills references missing skill '$ref'" }
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($e in $errors) { Write-Host "::error::$e" }
    Write-Host "lint-frontmatter: FAILED ($($errors.Count) error(s))"
    exit 1
}

Write-Host "lint-frontmatter: OK"
exit 0

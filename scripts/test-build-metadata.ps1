#!/usr/bin/env pwsh
# Exercise the actual builder and -Check in independent git repositories.
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$builder = Join-Path $PSScriptRoot 'build-metadata.ps1'
$fixtureRoot = Join-Path (Split-Path -Parent $PSScriptRoot) "dist/metadata-tests-$([guid]::NewGuid().ToString('N'))"
$assertions = 0
$checks = 0

function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
    $script:assertions++
}

function Write-Text([string]$Path, [string]$Text) {
    New-Item -ItemType Directory -Force (Split-Path -Parent $Path) | Out-Null
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

function Invoke-Builder(
    [string]$Root,
    [switch]$Check,
    [int]$Expected = 0,
    [string]$Diagnostic = 'sheen-metadata.json is out of date'
) {
    Push-Location $Root
    try {
        $arguments = @('-NoProfile', '-File', $builder)
        if ($Check) { $arguments += '-Check'; $script:checks++ }
        $output = & pwsh @arguments 2>&1
        $code = $LASTEXITCODE
        Assert ($code -eq $Expected) "Builder Check=$Check expected $Expected, got ${code}:`n$($output -join "`n")"
        if ($Check -and $Expected -eq 1) {
            Assert (($output -join "`n") -match [regex]::Escape($Diagnostic)) "Expected diagnostic: $Diagnostic"
        }
    } finally { Pop-Location }
}

function Read-Skill([string]$Root) {
    $metadata = Get-Content -LiteralPath (Join-Path $Root 'sheen-metadata.json') -Raw | ConvertFrom-Json
    Assert ($metadata.schema -eq 'sheen-metadata/v1') 'Additive inventory must retain v1 compatibility'
    Assert ($metadata.counts.skills -eq 1) 'Only the active source/consumer skill root should be inventoried'
    return $metadata.inventory.skills[0]
}

function Assert-DriftAndRegenerate([string]$Root, [string]$OriginalHash) {
    Invoke-Builder $Root -Check -Expected 1
    Invoke-Builder $Root
    Invoke-Builder $Root -Check
    $skill = Read-Skill $Root
    Assert ($skill.hash -eq $OriginalHash) 'Supporting-file changes must retain legacy SKILL.md hash'
}

try {
    foreach ($consumer in @($false, $true)) {
        $root = Join-Path $fixtureRoot $(if ($consumer) { 'consumer' } else { 'source' })
        New-Item -ItemType Directory -Force $root | Out-Null
        & git -C $root init --quiet
        Assert ($LASTEXITCODE -eq 0) 'Fixture git init failed'
        $prefix = if ($consumer) { '.github/skills' } else { 'skills' }
        $skillRoot = Join-Path $root "$prefix/fixture"
        if ($consumer) {
            Write-Text (Join-Path $root '.sheen/manifest.json') '{"schema":"sheen-manifest/v1","files":[]}'
        }
        $skillBody = "---`nname: fixture`ndescription: `"USE FOR: design. DO NOT USE FOR: backend.`"`n---`n# Fixture`n"
        Write-Text (Join-Path $skillRoot 'SKILL.md') $skillBody
        Write-Text (Join-Path $skillRoot 'eval.yaml') "name: fixture`n"
        Write-Text (Join-Path $skillRoot 'references/guide.md') "First line`nSecond line`n"
        Write-Text (Join-Path $skillRoot 'references/z-last.md') "Last`n"
        Write-Text (Join-Path $skillRoot 'references/A-first.md') "First`n"
        Write-Text (Join-Path $skillRoot 'references/.hidden.md') "Bundled hidden contract`n"
        Write-Text (Join-Path $skillRoot 'templates/entry.md') "Starter`n"
        Write-Text (Join-Path $skillRoot 'samples/example.json') "{}`n"
        Write-Text (Join-Path $skillRoot 'scripts/contract.ps1') "Write-Output 'contract'`n"
        Write-Text (Join-Path $skillRoot 'root-contract.md') "Root material`n"
        Write-Text (Join-Path $skillRoot 'references/empty.txt') ''
        $binary = Join-Path $skillRoot 'samples/image.bin'
        $binaryBytes = [byte[]]@(0, 255, 13, 10, 239, 187, 191, 65)
        [IO.File]::WriteAllBytes($binary, $binaryBytes)
        $inactivePrefix = if ($consumer) { 'skills' } else { '.github/skills' }
        Write-Text (Join-Path $root "$inactivePrefix/unrelated/SKILL.md") $skillBody
        Invoke-Builder $root
        Invoke-Builder $root -Check
        $skill = Read-Skill $root
        $originalHash = $skill.hash
        Assert ($skill.folder -eq "$prefix/fixture") 'Wrong source/consumer path'
        Assert ($skill.files.Count -eq 12) 'Entire bundled payload must be hashed, including eval, root files, scripts and hidden files'
        $expectedPaths = [string[]]@(
            'SKILL.md', 'eval.yaml', 'references/.hidden.md', 'references/A-first.md',
            'references/empty.txt', 'references/guide.md', 'references/z-last.md',
            'root-contract.md', 'samples/example.json', 'samples/image.bin',
            'scripts/contract.ps1', 'templates/entry.md'
        )
        Assert (($skill.files.path -join '|') -ceq ($expectedPaths -join '|')) 'Payload paths must use ordinal ordering and portable separators'
        $binaryRecord = @($skill.files | Where-Object path -EQ 'samples/image.bin')[0]
        Assert ($binaryRecord.hash_mode -eq 'bytes') 'Binary hash mode'
        Assert ($binaryRecord.hash -eq (Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash.ToLowerInvariant()) 'Binary content must hash exact bytes'
        $skillRecord = @($skill.files | Where-Object path -EQ 'SKILL.md')[0]
        Assert ($skillRecord.hash -eq $originalHash) 'Legacy hash remains normalized SKILL.md-only hash'
        Assert (@($skill.files | Where-Object hash_mode -EQ 'text-lf').Count -eq 11) 'Known textual contracts use text normalization'
        $metadataPath = Join-Path $root 'sheen-metadata.json'
        $initialMetadata = [IO.File]::ReadAllText($metadataPath)
        Invoke-Builder $root
        Assert ([IO.File]::ReadAllText($metadataPath) -ceq $initialMetadata) 'Repeated generation must be byte-stable'

        # Semantically identical CRLF/BOM text must not produce drift.
        $guide = Join-Path $skillRoot 'references/guide.md'
        [IO.File]::WriteAllText($guide, "First line`r`nSecond line`r`n", [Text.UTF8Encoding]::new($true))
        [IO.File]::WriteAllText((Join-Path $skillRoot 'SKILL.md'), $skillBody.Replace("`n", "`r`n"), [Text.UTF8Encoding]::new($true))
        Invoke-Builder $root -Check
        Write-Text $guide "First line`nSecond line`n"
        Write-Text (Join-Path $skillRoot 'SKILL.md') $skillBody
        Invoke-Builder $root -Check

        # Deleted/re-created files have different discovery order but identical inventory.
        $last = Join-Path $skillRoot 'references/z-last.md'
        Remove-Item -LiteralPath $last
        Write-Text $last "Last`n"
        Invoke-Builder $root -Check

        Write-Text $guide "Edited operative rule`n"
        Assert-DriftAndRegenerate $root $originalHash
        $added = Join-Path $skillRoot 'references/new.md'
        Write-Text $added "New operative rule`n"
        Assert-DriftAndRegenerate $root $originalHash
        Remove-Item -LiteralPath $added
        Assert-DriftAndRegenerate $root $originalHash
        Rename-Item -LiteralPath $guide -NewName 'renamed.md'
        Assert-DriftAndRegenerate $root $originalHash
        foreach ($relative in @('templates/entry.md', 'samples/example.json', 'scripts/contract.ps1', 'root-contract.md', 'eval.yaml')) {
            Write-Text (Join-Path $skillRoot $relative) "Changed payload`n"
            Assert-DriftAndRegenerate $root $originalHash
        }
        # A filename-only case change also changes ordinal, case-sensitive path evidence.
        Rename-Item -LiteralPath (Join-Path $skillRoot 'references/A-first.md') -NewName 'rename-stage.md'
        Rename-Item -LiteralPath (Join-Path $skillRoot 'references/rename-stage.md') -NewName 'a-first.md'
        Assert-DriftAndRegenerate $root $originalHash
        [IO.File]::WriteAllBytes($binary, [byte[]]@(0, 255, 10, 239, 187, 191, 65))
        Assert-DriftAndRegenerate $root $originalHash

        foreach ($directory in @('.git', 'node_modules', 'dist', 'build', '.venv', 'venv', '__pycache__', '.cache', '.pytest_cache', '.mypy_cache', '.ruff_cache', 'coverage', 'site', 'test-results', 'playwright-report')) {
            Write-Text (Join-Path $skillRoot "references/$directory/noise.md") "Ignored`n"
        }
        foreach ($file in @('.gitkeep', '.DS_Store', 'Thumbs.db', '.env', '.env.local', 'notes.local', 'notes.local.md', 'debug.log', 'scratch.tmp', 'backup.bak', 'module.pyc')) {
            Write-Text (Join-Path $skillRoot "templates/$file") "Ignored`n"
        }
        Write-Text (Join-Path $root 'node_modules/dependency/contract.md') "Unrelated external dependency`n"
        Write-Text (Join-Path $root 'dist/external.md') "Build output`n"
        Write-Text (Join-Path $root 'vendor/skills/external/SKILL.md') $skillBody
        Invoke-Builder $root -Check

        $outside = Join-Path $root 'external-contract'
        Write-Text (Join-Path $outside 'rule.md') "External dependency`n"
        $link = Join-Path $skillRoot 'references/external-link'
        $linkType = if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }
        New-Item -ItemType $linkType -Path $link -Target $outside | Out-Null
        try {
            Invoke-Builder $root -Check -Expected 1 -Diagnostic 'Skill payload must not contain symbolic links or reparse points'
        } finally { Remove-Item -LiteralPath $link -Force }
        Invoke-Builder $root -Check
        Write-Text (Join-Path $outside 'SKILL.md') $skillBody
        $rootLink = Join-Path $root "$prefix/linked-skill"
        New-Item -ItemType $linkType -Path $rootLink -Target $outside | Out-Null
        try {
            Invoke-Builder $root -Check -Expected 1 -Diagnostic 'Skill payload must not contain symbolic links or reparse points'
        } finally { Remove-Item -LiteralPath $rootLink -Force }
        Invoke-Builder $root -Check
    }
    Write-Host "test-build-metadata: OK (2 source/consumer roots; $checks real -Check runs; $assertions assertions)."
} finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}

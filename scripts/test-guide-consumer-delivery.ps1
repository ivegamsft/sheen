#!/usr/bin/env pwsh
# Consumer-delivery evidence for style-guide-authoring (#230). Exercises the
# shipped complete skill folder after a real sync into a scratch consumer repo.
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = Split-Path $PSScriptRoot

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "ASSERTION FAILED: $Message" } }
function Assert-Equal { param($Expected, $Actual, [string]$Message) Assert-True ($Expected -eq $Actual) "$Message (expected '$Expected', got '$Actual')" }

function Get-TextLfHash {
    param([Parameter(Mandatory)][string]$Path)
    $text = [string](Get-Content -LiteralPath $Path -Raw)
    $normalized = (($text -replace "^\uFEFF", '') -replace "`r`n", "`n")
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Get-JsonFromCli {
    param([Parameter(Mandatory)][string]$File, [Parameter(Mandatory)][string[]]$Arguments)
    $output = & pwsh -NoProfile -File $File @Arguments
    return $output | ConvertFrom-Json
}

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("sga-230-consumer-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch -Force | Out-Null
try {
    Write-Host '[1/6] metadata records complete style-guide-authoring payload'
    $metadata = Get-Content -LiteralPath (Join-Path $repoRoot 'sheen-metadata.json') -Raw | ConvertFrom-Json
    $skill = @($metadata.inventory.skills | Where-Object { $_.name -eq 'style-guide-authoring' })[0]
    Assert-True ($null -ne $skill) 'style-guide-authoring must be present in metadata inventory'
    $requiredSkillFiles = @(
        'SKILL.md',
        'eval.yaml',
        'references/guide-contract.md',
        'references/input-provenance.md',
        'references/module-recipes.md',
        'scripts/GuideHtml.psm1',
        'scripts/GuideInputs.psm1',
        'scripts/check-guide-freshness.ps1',
        'scripts/refresh-guide.ps1',
        'scripts/render-html-guide.ps1',
        'templates/guide-outline.md'
    )
    $metadataPaths = @($skill.files | ForEach-Object { [string]$_.path })
    foreach ($relative in $requiredSkillFiles) {
        Assert-True ($metadataPaths -contains $relative) "Metadata must include complete skill payload file: $relative"
        $entry = @($skill.files | Where-Object { $_.path -eq $relative })[0]
        $sourceFile = Join-Path (Join-Path $repoRoot 'skills' -AdditionalChildPath 'style-guide-authoring') ($relative -replace '/', '\')
        Assert-Equal 'text-lf' $entry.hash_mode "Skill payload hash mode must be portable text-lf for $relative"
        Assert-Equal (Get-TextLfHash -Path $sourceFile) $entry.hash "Metadata hash must match current source payload for $relative"
    }
    Assert-True (-not ($metadata.assets.skills -contains 'brand-guide-html')) 'Catalog must not expose a duplicate brand-guide-html skill'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'skills' -AdditionalChildPath 'brand-guide-html'))) 'Repository must not contain a duplicate brand-guide-html skill folder'

    Write-Host '[2/6] routing eval covers Spec 14 positive and negative scenarios'
    $evalPath = Join-Path $repoRoot 'skills' -AdditionalChildPath 'style-guide-authoring', 'eval.yaml'
    $eval = Get-Content -LiteralPath $evalPath -Raw
    Assert-True (([regex]::Matches($eval, 'expect_activation:\s*true')).Count -ge 7) 'Routing eval must include at least seven positive guide-authoring scenarios'
    Assert-True (([regex]::Matches($eval, 'expect_activation:\s*false')).Count -ge 5) 'Routing eval must include at least five negative handoff scenarios'
    foreach ($needle in @('offline HTML guide', 'quick-reference', 'stale', 'without writing files', 'pixel-identical slide viewer', 'revenue dashboard')) {
        Assert-True ($eval.Contains($needle)) "Routing eval must cover scenario text: $needle"
    }
    $agent = Get-Content -LiteralPath (Join-Path $repoRoot 'agents' -AdditionalChildPath 'design-reviewer.agent.md') -Raw
    Assert-True ($agent -match '(?m)^\s+- style-guide-authoring\s*$') 'design-reviewer must compose style-guide-authoring by its existing stable name'

    Write-Host '[3/6] sync delivers copied complete skill folder into a consumer repo'
    $sourceFixture = Join-Path $scratch 'source'
    New-Item -ItemType Directory -Path $sourceFixture -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $sourceFixture 'skills') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $sourceFixture 'agents') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $sourceFixture 'templates') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'skills' -AdditionalChildPath 'style-guide-authoring') -Destination (Join-Path $sourceFixture 'skills' -AdditionalChildPath 'style-guide-authoring') -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'agents' -AdditionalChildPath 'design-reviewer.agent.md') -Destination (Join-Path $sourceFixture 'agents' -AdditionalChildPath 'design-reviewer.agent.md') -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'templates' -AdditionalChildPath 'style-guide') -Destination (Join-Path $sourceFixture 'templates' -AdditionalChildPath 'style-guide') -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'templates' -AdditionalChildPath 'sheen-sync.yml') -Destination (Join-Path $sourceFixture 'templates' -AdditionalChildPath 'sheen-sync.yml') -Force
    git -C $sourceFixture init --quiet --initial-branch main
    if ($LASTEXITCODE -ne 0) { throw 'git init failed for source fixture' }
    git -C $sourceFixture config user.name 'Copilot Test'
    git -C $sourceFixture config user.email 'copilot@example.invalid'
    git -C $sourceFixture add .
    git -C $sourceFixture commit --quiet -m 'source fixture'
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed for source fixture' }

    $consumer = Join-Path $scratch 'consumer'
    New-Item -ItemType Directory -Path $consumer -Force | Out-Null
    git -C $consumer init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'git init failed for consumer fixture' }
    $sourcePath = (Resolve-Path $sourceFixture).Path.Replace("'", "''")
    Set-Content -LiteralPath (Join-Path $consumer '.sheen.yml') -Value @"
source: '$sourcePath'
ref: main
skills:
  - style-guide-authoring
agents:
  - design-reviewer
templates:
  - style-guide
"@ -NoNewline
    Push-Location $consumer
    try {
        & (Join-Path $repoRoot 'sync.ps1') | Out-Host
    } finally {
        Pop-Location
    }
    $consumerSkillRoot = Join-Path $consumer '.github' -AdditionalChildPath 'skills', 'style-guide-authoring'
    foreach ($relative in $requiredSkillFiles) {
        Assert-True (Test-Path -LiteralPath (Join-Path $consumerSkillRoot ($relative -replace '/', '\'))) "Consumer sync must deliver $relative"
    }
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $consumer '.github' -AdditionalChildPath 'skills', 'brand-guide-html'))) 'Consumer sync must not deliver a duplicate brand-guide-html skill'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $consumer 'scripts' -AdditionalChildPath 'build-design-md.ps1'))) 'Copied skill folder must not require source-only top-level DESIGN.md generator scripts'
    $manifest = Get-Content -LiteralPath (Join-Path $consumer '.sheen' -AdditionalChildPath 'manifest.json') -Raw | ConvertFrom-Json
    foreach ($relative in @('SKILL.md', 'references/guide-contract.md', 'scripts/render-html-guide.ps1', 'scripts/check-guide-freshness.ps1', 'templates/guide-outline.md')) {
        $manifestPath = ".github/skills/style-guide-authoring/$relative"
        Assert-True (@($manifest.files) -contains $manifestPath) "Consumer manifest must record $manifestPath"
    }

    Write-Host '[4/6] copied HTML profile renders all delivered guide profiles'
    $consumerGuide = Join-Path $consumer 'consumer-guide.md'
    Set-Content -LiteralPath $consumerGuide -Value @'
# Consumer Guide

> State: DRAFT
> Scope: synthetic-consumer

## Orientation

Approved synthetic content with `inline-code` and a [fragment](#resources).

1. Keep restrictions visible.
2. Keep unresolved states visible.

## Resources

| Resource | State |
|---|---|
| Approved swatch | Available |
'@ -NoNewline
    $asset = Join-Path $consumer 'swatch.png'
    [System.IO.File]::WriteAllBytes($asset, [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII='))
    $embedManifest = Join-Path $consumer 'assets-embed.json'
    @{ assets = @(@{ id = 'approved-swatch'; path = 'swatch.png'; mediaType = 'image/png'; alt = 'Approved swatch'; permission = 'embed' }) } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $embedManifest -NoNewline
    $renderCli = Join-Path $consumerSkillRoot 'scripts' -AdditionalChildPath 'render-html-guide.ps1'
    foreach ($profile in @('reference-manual', 'presentation-inspired', 'quick-reference')) {
        $out = Join-Path $consumer "$profile.html"
        $result = Get-JsonFromCli -File $renderCli -Arguments @('-MarkdownPath', $consumerGuide, '-OutputPath', $out, '-AssetManifestPath', $embedManifest, '-RepoRoot', $consumer, '-Profile', $profile)
        Assert-Equal 'DRAFT' $result.State "Copied HTML helper must render $profile as DRAFT, not READY"
        Assert-Equal $profile $result.Profile "Copied HTML helper must preserve requested profile $profile"
        $html = Get-Content -LiteralPath $out -Raw
        Assert-True ($html -match '<blockquote>State: DRAFT</blockquote>') "$profile must preserve blockquote status"
        Assert-True ($html -match '<code>inline-code</code>') "$profile must preserve inline code"
        Assert-True ($html -match '<ol>') "$profile must preserve ordered lists"
        Assert-True ($html -match "sga-profile-$profile") "$profile must expose its layout hook"
        Assert-True ($html -notmatch '<script\b') "$profile must not require JavaScript"
    }

    Write-Host '[5/6] copied local-bundle profile resolves relative resources'
    $copyManifest = Join-Path $consumer 'assets-copy.json'
    @{ assets = @(@{ id = 'approved-swatch'; path = 'swatch.png'; mediaType = 'image/png'; alt = 'Approved swatch'; permission = 'copy' }) } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $copyManifest -NoNewline
    $bundleOutput = Join-Path $consumer 'bundle' -AdditionalChildPath 'index.html'
    $bundle = Get-JsonFromCli -File $renderCli -Arguments @('-MarkdownPath', $consumerGuide, '-OutputPath', $bundleOutput, '-Packaging', 'local-bundle', '-AssetManifestPath', $copyManifest, '-RepoRoot', $consumer)
    Assert-Equal 'DRAFT' $bundle.State 'Copied local-bundle profile must produce a draft artifact'
    Assert-True ($bundle.AssetBytes -gt 0) 'Copied local-bundle profile must report delivered asset bytes'
    $bundleHtml = Get-Content -LiteralPath $bundleOutput -Raw
    $assetHref = [regex]::Match($bundleHtml, 'src="(?<path>assets/[^"]+)"').Groups['path'].Value
    Assert-True (-not [string]::IsNullOrWhiteSpace($assetHref)) 'Local bundle HTML must include a relative asset path'
    Assert-True (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $bundleOutput) ($assetHref -replace '/', '\'))) 'Local bundle relative asset path must resolve on disk'

    Write-Host '[6/6] copied freshness/check helpers run without source-only tooling'
    $inputsModule = Join-Path $consumerSkillRoot 'scripts' -AdditionalChildPath 'GuideInputs.psm1'
    Import-Module $inputsModule -Force
    $ownedBody = "`nApproved synthetic orientation guidance.`n"
    $ownedDigest = Get-TextDigest -Text $ownedBody
    $sourceDigest = 'sha256:' + ('a' * 64)
    $freshGuide = Join-Path $consumer 'fresh-guide.md'
    Set-Content -LiteralPath $freshGuide -Value @"
# Freshness Guide

### Approved inputs

| Source ID | Revision or digest | Approval state | Supported module or rule |
|---|---|---|---|
| guide:orientation | $sourceDigest | APPROVED | orientation |

<!-- guide-owned:orientation sources="guide:orientation" revision="$ownedDigest" -->$ownedBody<!-- /guide-owned:orientation -->
"@ -NoNewline
    $freshManifest = Join-Path $consumer 'fresh-inputs.json'
    @{ sources = @(@{ id = 'guide:orientation'; kind = 'approved-guide'; scope = 'orientation'; status = 'APPROVED'; digest = $sourceDigest }) } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $freshManifest -NoNewline
    $checkCli = Join-Path $consumerSkillRoot 'scripts' -AdditionalChildPath 'check-guide-freshness.ps1'
    $fresh = Get-JsonFromCli -File $checkCli -Arguments @('-GuidePath', $freshGuide, '-ManifestPath', $freshManifest, '-RepoRoot', $consumer)
    Assert-Equal 'CURRENT' $fresh.overall 'Copied freshness helper must assess unchanged synthetic evidence as CURRENT'

    Write-Host 'All style-guide-authoring consumer delivery scenarios passed (6 scenarios).'
    exit 0
} finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

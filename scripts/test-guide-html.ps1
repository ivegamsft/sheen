#!/usr/bin/env pwsh
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = Split-Path $PSScriptRoot
$modulePath = Join-Path $repoRoot 'skills' -AdditionalChildPath 'style-guide-authoring', 'scripts', 'GuideHtml.psm1'
Import-Module $modulePath -Force

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "ASSERTION FAILED: $Message" } }
function Assert-Equal { param($Expected, $Actual, [string]$Message) Assert-True ($Expected -eq $Actual) "$Message (expected '$Expected', got '$Actual')" }
function Assert-Throws {
    param([scriptblock]$Script, [string]$Message, [string]$ExpectedSubstring = $null)
    $threw = $false
    $errMsg = $null
    try { & $Script } catch { $threw = $true; $errMsg = $_.Exception.Message }
    Assert-True $threw "$Message (expected an exception, none thrown)"
    if ($ExpectedSubstring) { Assert-True ($errMsg -like "*$ExpectedSubstring*") "$Message (exception '$errMsg' did not contain '$ExpectedSubstring')" }
}

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("sga-229-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch -Force | Out-Null
try {
    $guide = Join-Path $scratch 'guide.md'
    Set-Content -LiteralPath $guide -Value @'
# Fixture Style Guide

## Orientation

Approved scope and audience.

## Visual foundations

- Semantic role evidence is recorded.
- Missing inputs remain visible.
'@ -NoNewline

    $asset = Join-Path $scratch 'swatch.svg'
    Set-Content -LiteralPath $asset -Value '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><title>Swatch</title><rect width="10" height="10"/></svg>' -NoNewline
    $manifest = Join-Path $scratch 'assets.json'
    @{ assets = @(@{ id = 'approved-swatch'; path = 'swatch.svg'; mediaType = 'image/svg+xml'; alt = 'Approved swatch'; permission = 'embed' }) } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifest -NoNewline

    Write-Host '[1/8] self-contained HTML is offline, semantic and JavaScript-free'
    $html = Join-Path $scratch 'index.html'
    $result = New-StyleGuideHtml -MarkdownPath $guide -OutputPath $html -AssetManifestPath $manifest -RepoRoot $scratch
    Assert-Equal 'DRAFT' $result.State 'Default self-contained output must pass under the default budget without implying READY'
    $content = Get-Content -LiteralPath $html -Raw
    Assert-True ($content -match '<nav aria-label="Guide sections">') 'Generated HTML must include navigation landmark'
    Assert-True ($content -match '<main id="sga-main">') 'Generated HTML must include main content landmark'
    Assert-True ($content -match '@media print') 'Generated HTML must include print styles'
    Assert-True ($content -notmatch '<script\b') 'Generated HTML must not require JavaScript'
    Assert-True ($content -match 'data:image/svg\+xml;base64,') 'Self-contained output must embed permitted assets'

    Write-Host '[2/8] exact budget passes and one byte over fails'
    $exact = New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'exact.html') -AssetManifestPath $manifest -RepoRoot $scratch -BudgetBytes $result.Bytes -OverrideRationale 'Fixture exact limit' -OverrideAuthorizer 'test'
    Assert-Equal 'DRAFT' $exact.State 'An artifact exactly at the effective byte limit must pass without implying READY'
    $over = New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'over.html') -AssetManifestPath $manifest -RepoRoot $scratch -BudgetBytes ($result.Bytes - 1) -OverrideRationale 'Fixture over limit' -OverrideAuthorizer 'test'
    Assert-Equal 'BLOCKED' $over.State 'An artifact one byte over the effective limit must fail'

    Write-Host '[3/8] invalid budget overrides are rejected'
    Assert-Throws { New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'bad-budget.html') -BudgetBytes -1 } 'Negative budget overrides must be rejected' 'BudgetBytes'
    Assert-Throws { New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'missing-auth.html') -BudgetBytes 100 } 'Budget overrides require rationale and authorizer' 'requires rationale'

    Write-Host '[4/8] local bundle requires explicit selection and counts copied duplicates'
    $bundleManifest = Join-Path $scratch 'bundle-assets.json'
    @{ assets = @(
        @{ id = 'swatch-a'; path = 'swatch.svg'; mediaType = 'image/svg+xml'; alt = 'A'; permission = 'copy' },
        @{ id = 'swatch-b'; path = 'swatch.svg'; mediaType = 'image/svg+xml'; alt = 'B'; permission = 'copy' }
    ) } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $bundleManifest -NoNewline
    Assert-Throws { New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'wrong-package.html') -AssetManifestPath $bundleManifest -RepoRoot $scratch } 'Copy-only assets must not silently switch packaging' 'local-bundle'
    $bundle = New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'bundle' -AdditionalChildPath 'index.html') -Packaging local-bundle -AssetManifestPath $bundleManifest -RepoRoot $scratch
    Assert-Equal 'DRAFT' $bundle.State 'Explicit local bundle packaging must pass when in budget without implying READY'
    Assert-Equal ((Get-Item -LiteralPath $asset).Length * 2) $bundle.AssetBytes 'Local bundle budget must count each delivered duplicate copy'
    Assert-True (Test-Path -LiteralPath (Join-Path $scratch 'bundle' -AdditionalChildPath 'assets', 'swatch-a.svg')) 'Local bundle must copy relative asset dependency'

    Write-Host '[5/8] unsafe URLs and raw executable markup fail visibly'
    $unsafe = Join-Path $scratch 'unsafe.md'
    Set-Content -LiteralPath $unsafe -Value '# Unsafe guide' -NoNewline
    Assert-Throws { Assert-SafeGuideMarkdown -Markdown '[bad](javascript:alert(1))' } 'Executable guide links must be rejected' 'Unsafe'
    Assert-Throws { Assert-SafeGuideMarkdown -Markdown '<script>alert(1)</script>' } 'Raw script markup must be rejected' 'Unsafe'

    Write-Host '[6/8] path traversal and remote dependencies are rejected'
    Assert-Throws { Resolve-GuideHtmlPath -RepoRoot $scratch -Path '..\outside.svg' } 'Asset paths must not traverse outside RepoRoot' 'traversal'
    Assert-Throws { Resolve-GuideHtmlPath -RepoRoot $scratch -Path 'https://example.com/asset.svg' } 'Remote asset dependencies must not be fetched' 'Remote'

    Write-Host '[7/8] unsafe SVG is rejected before embedding'
    $badSvg = Join-Path $scratch 'bad.svg'
    Set-Content -LiteralPath $badSvg -Value '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>' -NoNewline
    $badManifest = Join-Path $scratch 'bad-assets.json'
    @{ assets = @(@{ id = 'bad'; path = 'bad.svg'; mediaType = 'image/svg+xml'; alt = 'Bad'; permission = 'embed' }) } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $badManifest -NoNewline
    Assert-Throws { New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'bad-svg.html') -AssetManifestPath $badManifest -RepoRoot $scratch } 'Unsafe SVG must fail before output is represented as usable' 'unsafe SVG'

    Write-Host '[8/8] CLI emits JSON and returns nonzero for budget failure'
    $cli = Join-Path $repoRoot 'skills' -AdditionalChildPath 'style-guide-authoring', 'scripts', 'render-html-guide.ps1'
    $cliOut = Join-Path $scratch 'cli-over.html'
    $json = & $cli -MarkdownPath $guide -OutputPath $cliOut -AssetManifestPath $manifest -RepoRoot $scratch -BudgetBytes 1 -OverrideRationale 'Fixture' -OverrideAuthorizer 'test' 2>$null
    Assert-True ($LASTEXITCODE -ne 0) 'CLI must exit nonzero for a blocked over-budget artifact'
    $parsed = $json | ConvertFrom-Json
    Assert-Equal 'BLOCKED' $parsed.State 'CLI JSON must report BLOCKED for over-budget output'

    Write-Host 'All style-guide-authoring HTML packaging scenarios passed (8 scenarios).'
    exit 0
} finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

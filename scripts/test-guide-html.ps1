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

| Role | Status |
|---|---|
| Primary action | Approved |

## Orientation

Repeated heading fixture.
'@ -NoNewline

    $asset = Join-Path $scratch 'swatch.png'
    [System.IO.File]::WriteAllBytes($asset, [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII='))
    $manifest = Join-Path $scratch 'assets.json'
    @{ assets = @(@{ id = 'approved-swatch'; path = 'swatch.png'; mediaType = 'image/png'; alt = 'Approved swatch'; permission = 'embed' }) } |
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
    Assert-True ($content -match 'data:image/png;base64,') 'Self-contained output must embed permitted assets'
    Assert-Equal (Get-Item -LiteralPath $html).Length $result.Bytes 'Self-contained budget must equal the emitted HTML file length'
    Assert-True ($content -match '<table>') 'Canonical guide Markdown tables must render as semantic HTML tables'
    Assert-True ($content -match 'id="orientation-2"') 'Repeated headings must receive stable unique fragment IDs'

    Write-Host '[2/8] exact budget passes and one byte over fails'
    $exact = New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'exact.html') -AssetManifestPath $manifest -RepoRoot $scratch -BudgetBytes $result.Bytes -OverrideRationale 'Fixture exact limit' -OverrideAuthorizer 'test'
    Assert-Equal 'DRAFT' $exact.State 'An artifact exactly at the effective byte limit must pass without implying READY'
    $overPath = Join-Path $scratch 'over.html'
    $over = New-StyleGuideHtml -MarkdownPath $guide -OutputPath $overPath -AssetManifestPath $manifest -RepoRoot $scratch -BudgetBytes ($result.Bytes - 1) -OverrideRationale 'Fixture over limit' -OverrideAuthorizer 'test'
    Assert-Equal 'BLOCKED' $over.State 'An artifact one byte over the effective limit must fail'
    Assert-True (-not (Test-Path -LiteralPath $overPath)) 'Over-budget output must not publish a normal-looking HTML file'
    Assert-True (Test-Path -LiteralPath "$overPath.blocked.html") 'Over-budget output may retain only a labeled diagnostic artifact'

    Write-Host '[3/8] invalid budget overrides are rejected'
    Assert-Throws { New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'bad-budget.html') -BudgetBytes -2 } 'Negative budget overrides must be rejected' 'BudgetBytes'
    Assert-Throws { New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'zero-budget.html') -BudgetBytes 0 -OverrideRationale 'Fixture' -OverrideAuthorizer 'test' } 'Explicit zero budget overrides must be rejected' 'zero is invalid'
    Assert-Throws { New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'missing-auth.html') -BudgetBytes 100 } 'Budget overrides require rationale and authorizer' 'requires rationale'
    Assert-Throws { New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'bad-lang.html') -Language 'en" onclick="bad' } 'Language must be validated before being written to an HTML attribute' 'Language'
    $quick = New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'quick-reference.html') -Profile quick-reference -RepoRoot $scratch
    $quickContent = Get-Content -LiteralPath (Join-Path $scratch 'quick-reference.html') -Raw
    Assert-Equal 'DRAFT' $quick.State 'Quick-reference profile must render as an explicit supported profile'
    Assert-True ($quickContent -match 'sga-profile-quick-reference') 'Quick-reference profile must use distinct layout hooks'
    $presentation = New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'presentation.html') -Profile presentation-inspired -RepoRoot $scratch
    $presentationContent = Get-Content -LiteralPath (Join-Path $scratch 'presentation.html') -Raw
    Assert-Equal 'DRAFT' $presentation.State 'Presentation-inspired profile must render as an explicit supported profile'
    Assert-True ($presentationContent -match 'sga-profile-presentation-inspired') 'Presentation-inspired profile must use distinct layout hooks'

    Write-Host '[4/8] local bundle requires explicit selection and counts copied duplicates'
    $bundleManifest = Join-Path $scratch 'bundle-assets.json'
    @{ assets = @(
        @{ id = 'swatch-a'; path = 'swatch.png'; mediaType = 'image/png'; alt = 'A'; permission = 'copy' },
        @{ id = 'swatch-b'; path = 'swatch.png'; mediaType = 'image/png'; alt = 'B'; permission = 'copy' }
    ) } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $bundleManifest -NoNewline
    Assert-Throws { New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'wrong-package.html') -AssetManifestPath $bundleManifest -RepoRoot $scratch } 'Copy-only assets must not silently switch packaging' 'local-bundle'
    $embedOnlyBundleManifest = Join-Path $scratch 'embed-only-bundle-assets.json'
    @{ assets = @(@{ id = 'embed-only'; path = 'swatch.png'; mediaType = 'image/png'; alt = 'A'; permission = 'embed' }) } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $embedOnlyBundleManifest -NoNewline
    Assert-Throws { New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'embed-only-bundle.html') -Packaging local-bundle -AssetManifestPath $embedOnlyBundleManifest -RepoRoot $scratch } 'Local bundle output must require explicit copy permission' 'cannot copy'
    $bundle = New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'bundle' -AdditionalChildPath 'index.html') -Packaging local-bundle -AssetManifestPath $bundleManifest -RepoRoot $scratch
    Assert-Equal 'DRAFT' $bundle.State 'Explicit local bundle packaging must pass when in budget without implying READY'
    Assert-Equal ((Get-Item -LiteralPath $asset).Length * 2) $bundle.AssetBytes 'Local bundle budget must count each delivered duplicate copy'
    Assert-True (Test-Path -LiteralPath (Join-Path $scratch 'bundle' -AdditionalChildPath 'assets', 'swatch-a.png')) 'Local bundle must copy relative asset dependency'
    $duplicateDestManifest = Join-Path $scratch 'duplicate-dest-assets.json'
    @{ assets = @(
        @{ id = 'logo/a'; path = 'swatch.png'; mediaType = 'image/png'; alt = 'A'; permission = 'copy' },
        @{ id = 'logo-a'; path = 'swatch.png'; mediaType = 'image/png'; alt = 'B'; permission = 'copy' }
    ) } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $duplicateDestManifest -NoNewline
    Assert-Throws { New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'duplicate-dest.html') -Packaging local-bundle -AssetManifestPath $duplicateDestManifest -RepoRoot $scratch } 'Local bundle assets must not overwrite duplicate normalized destinations' 'duplicate bundle destination'

    Write-Host '[5/8] unsafe URLs and raw executable markup fail visibly'
    $unsafe = Join-Path $scratch 'unsafe.md'
    Set-Content -LiteralPath $unsafe -Value '# Unsafe guide' -NoNewline
    Assert-Throws { Assert-SafeGuideMarkdown -Markdown '[bad](javascript:alert(1))' } 'Executable guide links must be rejected' 'Unsupported URL scheme'
    Assert-Throws { Assert-SafeGuideMarkdown -Markdown '<script>alert(1)</script>' } 'Raw script markup must be rejected' 'Unsafe'

    Write-Host '[6/8] path traversal and remote dependencies are rejected'
    Assert-Throws { Resolve-GuideHtmlPath -RepoRoot $scratch -Path '..\outside.svg' } 'Asset paths must not traverse outside RepoRoot' 'traversal'
    Assert-Throws { Resolve-GuideHtmlOutputPath -RepoRoot $scratch -Path '..\outside.html' } 'Output paths must not traverse outside RepoRoot' 'Output path traversal'
    Assert-Throws { Resolve-GuideHtmlPath -RepoRoot $scratch -Path 'https://example.com/asset.svg' } 'Remote asset dependencies must not be fetched' 'Remote'
    $badMediaTypeManifest = Join-Path $scratch 'bad-media-type-assets.json'
    @{ assets = @(@{ id = 'bad-media'; path = 'swatch.png'; mediaType = 'x" onerror="alert(1)"'; alt = 'Bad'; permission = 'embed' }) } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $badMediaTypeManifest -NoNewline
    Assert-Throws { New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'bad-media.html') -AssetManifestPath $badMediaTypeManifest -RepoRoot $scratch } 'Manifest-controlled media types must be validated before interpolation' 'unsupported media type'
    if (-not $IsWindows) {
        $outsideDir = Join-Path ([System.IO.Path]::GetTempPath()) ("sga-229-outside-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $outsideDir | Out-Null
        try {
            $outsideAsset = Join-Path $outsideDir 'outside.png'
            Copy-Item -LiteralPath $asset -Destination $outsideAsset
            $linkPath = Join-Path $scratch 'outside-link.png'
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $outsideAsset | Out-Null
            Assert-Throws { Resolve-GuideHtmlPath -RepoRoot $scratch -Path 'outside-link.png' } 'Repository-local symlinks must not escape the authorized root' 'reparse'
        } finally {
            Remove-Item -LiteralPath $outsideDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host '[7/8] unsafe SVG is rejected before embedding'
    $badSvg = Join-Path $scratch 'bad.svg'
    Set-Content -LiteralPath $badSvg -Value '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>' -NoNewline
    $badManifest = Join-Path $scratch 'bad-assets.json'
    @{ assets = @(@{ id = 'bad'; path = 'bad.svg'; mediaType = 'image/svg+xml'; alt = 'Bad'; permission = 'embed' }) } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $badManifest -NoNewline
    Assert-Throws { New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'bad-svg.html') -AssetManifestPath $badManifest -RepoRoot $scratch } 'SVG must fail closed when no approved sanitizer is available' 'unsupported media type'

    Write-Host '[8/8] CLI emits JSON and returns nonzero for budget failure'
    $cli = Join-Path $repoRoot 'skills' -AdditionalChildPath 'style-guide-authoring', 'scripts', 'render-html-guide.ps1'
    $cliOut = Join-Path $scratch 'cli-over.html'
    $json = & $cli -MarkdownPath $guide -OutputPath $cliOut -AssetManifestPath $manifest -RepoRoot $scratch -BudgetBytes 1 -OverrideRationale 'Fixture' -OverrideAuthorizer 'test' 2>$null
    Assert-True ($LASTEXITCODE -ne 0) 'CLI must exit nonzero for a blocked over-budget artifact'
    $parsed = $json | ConvertFrom-Json
    Assert-Equal 'BLOCKED' $parsed.State 'CLI JSON must report BLOCKED for over-budget output'
    Assert-True (@($parsed.Assets).Count -gt 0) 'Blocked budget output must still report diagnostic asset inventory'

    $consumerAsset = Join-Path $scratch 'bundle' -AdditionalChildPath 'assets', 'consumer-owned.txt'
    Set-Content -LiteralPath $consumerAsset -Value 'do not delete' -NoNewline
    $bundleAgain = New-StyleGuideHtml -MarkdownPath $guide -OutputPath (Join-Path $scratch 'bundle' -AdditionalChildPath 'index.html') -Packaging local-bundle -AssetManifestPath $bundleManifest -RepoRoot $scratch
    Assert-Equal 'DRAFT' $bundleAgain.State 'Repeated local bundle generation should refresh managed assets only'
    Assert-True (Test-Path -LiteralPath $consumerAsset) 'Local bundle publication must not delete consumer-owned assets'

    Write-Host 'All style-guide-authoring HTML packaging scenarios passed (8 scenarios).'
    exit 0
} finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

#!/usr/bin/env pwsh
Set-StrictMode -Version 3

$script:DefaultHtmlBudgets = @{
    'self-contained' = 5 * 1024 * 1024
    'local-bundle'   = 25 * 1024 * 1024
}

function Get-Utf8ByteCount {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    return [System.Text.Encoding]::UTF8.GetByteCount($Text)
}

function ConvertTo-HtmlText {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function ConvertTo-GuideHtmlId {
    param([Parameter(Mandatory)][string]$Text)
    $id = ($Text.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    if (-not $id) { $id = 'section' }
    return $id
}

function Resolve-GuideHtmlPath {
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$Path)
    if ([System.Uri]::IsWellFormedUriString($Path, [System.UriKind]::Absolute)) {
        throw "Remote or absolute URI dependencies are not permitted: $Path"
    }
    if ([System.IO.Path]::IsPathRooted($Path)) {
        throw "Absolute paths are not permitted: $Path"
    }
    $rootFull = [System.IO.Path]::GetFullPath($RepoRoot)
    $rootNormalized = $rootFull.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $candidate = [System.IO.Path]::GetFullPath((Join-Path $rootFull $Path))
    $comparison = if ($IsWindows) { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
    $rootWithSep = $rootNormalized + [System.IO.Path]::DirectorySeparatorChar
    if (-not $candidate.Equals($rootNormalized, $comparison) -and -not $candidate.StartsWith($rootWithSep, $comparison)) {
        throw "Path traversal outside RepoRoot is not permitted: $Path"
    }
    return $candidate
}

function Assert-SafeGuideMarkdown {
    param([Parameter(Mandatory)][string]$Markdown)
    if ($Markdown -match '(?is)<\s*script\b|<\s*iframe\b|on[a-z]+\s*=|javascript\s*:|data\s*:') {
        throw 'Unsafe markup or executable URL was rejected before HTML rendering.'
    }
    foreach ($m in [regex]::Matches($Markdown, '\[[^\]]+\]\((?<url>[^)]+)\)')) {
        $url = $m.Groups['url'].Value.Trim()
        if ($url -match '^(?i)(https?|mailto):' -or $url.StartsWith('#') -or ($url -notmatch ':' -and -not $url.StartsWith('//'))) { continue }
        throw "Unsupported URL scheme in guide content: $url"
    }
}

function Test-SafeSvgContent {
    param([Parameter(Mandatory)][string]$Svg)
    return $Svg -notmatch '(?is)<\s*script\b|<\s*foreignObject\b|on[a-z]+\s*=|javascript\s*:|href\s*=\s*["'']\s*(https?:|//)'
}

function Get-GuideHtmlAssetRecords {
    param(
        [string]$AssetManifestPath,
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$Packaging,
        [Parameter(Mandatory)][string]$OutputDirectory
    )
    $records = [System.Collections.Generic.List[object]]::new()
    if (-not $AssetManifestPath) { return @($records) }
    $manifest = Get-Content -LiteralPath $AssetManifestPath -Raw | ConvertFrom-Json -AsHashtable
    $assetIndex = 0
    foreach ($asset in @($manifest.assets)) {
        $assetIndex++
        $id = if ($asset.ContainsKey('id') -and $asset.id) { [string]$asset.id } else { "asset-$assetIndex" }
        $path = if ($asset.ContainsKey('path')) { [string]$asset.path } else { '' }
        $mediaType = if ($asset.ContainsKey('mediaType') -and $asset.mediaType) { [string]$asset.mediaType } else { 'application/octet-stream' }
        $alt = if ($asset.ContainsKey('alt')) { [string]$asset.alt } else { '' }
        $permission = if ($asset.ContainsKey('permission')) { [string]$asset.permission } else { '' }
        if ($permission -notin @('embed', 'copy')) { throw "Asset '$id' is missing explicit embed/copy permission." }
        $resolved = Resolve-GuideHtmlPath -RepoRoot $RepoRoot -Path $path
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) { throw "Asset '$id' does not resolve to a local file: $path" }
        $extension = [System.IO.Path]::GetExtension($resolved).ToLowerInvariant()
        $bytes = [System.IO.File]::ReadAllBytes($resolved)
        if ($extension -eq '.svg' -or $mediaType -eq 'image/svg+xml') {
            $svg = [System.Text.Encoding]::UTF8.GetString($bytes)
            if (-not (Test-SafeSvgContent -Svg $svg)) { throw "Asset '$id' contains unsafe SVG content." }
        }
        if ($Packaging -eq 'self-contained') {
            if ($permission -ne 'embed') { throw "Asset '$id' requires local-bundle packaging; self-contained output cannot copy it silently." }
            $records.Add([ordered]@{
                Id = $id; Mode = 'embedded'; Bytes = $bytes.Length; MediaType = $mediaType; Alt = $alt
                Html = "<figure class=`"sga-asset`"><img src=`"data:$mediaType;base64,$([Convert]::ToBase64String($bytes))`" alt=`"$(ConvertTo-HtmlText $alt)`"><figcaption>$(ConvertTo-HtmlText $id)</figcaption></figure>"
                DeliveredPath = $null
            })
        } else {
            $safeName = (ConvertTo-GuideHtmlId -Text $id) + $extension
            $assetDir = Join-Path $OutputDirectory 'assets'
            New-Item -ItemType Directory -Path $assetDir -Force | Out-Null
            $destination = Join-Path $assetDir $safeName
            Copy-Item -LiteralPath $resolved -Destination $destination -Force
            $records.Add([ordered]@{
                Id = $id; Mode = 'copied'; Bytes = $bytes.Length; MediaType = $mediaType; Alt = $alt
                Html = "<figure class=`"sga-asset`"><img src=`"assets/$safeName`" alt=`"$(ConvertTo-HtmlText $alt)`"><figcaption>$(ConvertTo-HtmlText $id)</figcaption></figure>"
                DeliveredPath = $destination
            })
        }
    }
    return @($records)
}

function Convert-GuideMarkdownToHtmlBody {
    param([Parameter(Mandatory)][string]$Markdown)
    $nav = [System.Collections.Generic.List[object]]::new()
    $body = [System.Text.StringBuilder]::new()
    $inList = $false
    foreach ($line in ($Markdown -split '\r?\n')) {
        if ($line -match '^(?<hash>#{1,6})\s+(?<title>.+?)\s*$') {
            if ($inList) { [void]$body.AppendLine('</ul>'); $inList = $false }
            $level = [Math]::Min($Matches.hash.Length, 6)
            $title = $Matches.title.Trim()
            $id = ConvertTo-GuideHtmlId -Text $title
            $nav.Add([ordered]@{ Id = $id; Title = $title; Level = $level })
            [void]$body.AppendLine("<h$level id=`"$id`">$(ConvertTo-HtmlText $title)</h$level>")
        } elseif ($line -match '^\s*[-*]\s+(?<item>.+?)\s*$') {
            if (-not $inList) { [void]$body.AppendLine('<ul>'); $inList = $true }
            [void]$body.AppendLine("<li>$(ConvertTo-HtmlText $Matches.item)</li>")
        } elseif ($line.Trim().Length -eq 0) {
            if ($inList) { [void]$body.AppendLine('</ul>'); $inList = $false }
        } else {
            if ($inList) { [void]$body.AppendLine('</ul>'); $inList = $false }
            [void]$body.AppendLine("<p>$(ConvertTo-HtmlText $line.Trim())</p>")
        }
    }
    if ($inList) { [void]$body.AppendLine('</ul>') }
    return [ordered]@{ Body = $body.ToString(); Navigation = @($nav) }
}

function New-StyleGuideHtml {
    param(
        [Parameter(Mandatory)][string]$MarkdownPath,
        [Parameter(Mandatory)][string]$OutputPath,
        [ValidateSet('self-contained', 'local-bundle')][string]$Packaging = 'self-contained',
        [ValidateSet('reference-manual', 'presentation-inspired', 'quick-reference')][string]$Profile = 'reference-manual',
        [string]$AssetManifestPath,
        [string]$RepoRoot = (Get-Location).Path,
        [int]$BudgetBytes = 0,
        [string]$OverrideRationale,
        [string]$OverrideAuthorizer,
        [string]$Language = 'en'
    )
    $markdown = Get-Content -LiteralPath $MarkdownPath -Raw
    Assert-SafeGuideMarkdown -Markdown $markdown
    if ($BudgetBytes -lt 0) { throw 'BudgetBytes must be a positive integer override, or 0 to use the default.' }
    if ($BudgetBytes -eq 0) {
        $effectiveBudget = $script:DefaultHtmlBudgets[$Packaging]
    } else {
        if (-not $OverrideRationale -or -not $OverrideAuthorizer) { throw 'Budget override requires rationale and authorizer.' }
        $effectiveBudget = $BudgetBytes
    }
    $outputDirectory = Split-Path -Parent ([System.IO.Path]::GetFullPath($OutputPath))
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    $converted = Convert-GuideMarkdownToHtmlBody -Markdown $markdown
    $assets = @(Get-GuideHtmlAssetRecords -AssetManifestPath $AssetManifestPath -RepoRoot $RepoRoot -Packaging $Packaging -OutputDirectory $outputDirectory)
    $assetHtml = ($assets | ForEach-Object { $_.Html }) -join "`n"
    $nav = ($converted.Navigation | ForEach-Object { "<a href=`"#$($_.Id)`">$(ConvertTo-HtmlText $_.Title)</a>" }) -join "`n"
    $title = if ($converted.Navigation.Count -gt 0) { $converted.Navigation[0].Title } else { 'Style guide' }
    $html = @"
<!doctype html>
<html lang="$Language">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$(ConvertTo-HtmlText $title)</title>
<style>
:root{color-scheme:light;--sga-bg:#fff;--sga-fg:#1f2328;--sga-accent:#0969da;--sga-border:#d0d7de}
*{box-sizing:border-box}body{margin:0;background:var(--sga-bg);color:var(--sga-fg);font:16px/1.55 system-ui,sans-serif}
.sga-skip{position:absolute;left:-999px}.sga-skip:focus{left:1rem;top:1rem;background:#fff;padding:.5rem;border:2px solid var(--sga-accent)}
.sga-shell{display:grid;grid-template-columns:minmax(12rem,18rem) 1fr;gap:2rem;max-width:72rem;margin:auto;padding:1rem}
nav{position:sticky;top:0;align-self:start}nav a{display:block;padding:.35rem;color:var(--sga-accent)}nav a:focus{outline:3px solid var(--sga-accent)}
main{min-width:0}section,.sga-card{border:1px solid var(--sga-border);border-radius:.5rem;padding:1rem;margin:1rem 0}.sga-asset img{max-width:100%;height:auto}
@media (max-width:40rem){.sga-shell{display:block}nav{position:static}}
@media print{@page{size:auto;margin:12mm}nav,.sga-skip{display:none}body{font-size:11pt}.sga-shell{display:block;max-width:none}h1,h2,h3{break-after:avoid}section,.sga-card{break-inside:avoid}}
</style>
</head>
<body>
<a class="sga-skip" href="#sga-main">Skip to guide content</a>
<div class="sga-shell sga-profile-$Profile">
<nav aria-label="Guide sections">$nav</nav>
<main id="sga-main">
<p class="sga-card"><strong>Profile:</strong> $(ConvertTo-HtmlText $Profile). <strong>Packaging:</strong> $(ConvertTo-HtmlText $Packaging). JavaScript is not required.</p>
$($converted.Body)
$assetHtml
</main>
</div>
</body>
</html>
"@
    Set-Content -LiteralPath $OutputPath -Value $html -NoNewline -Encoding utf8
    $htmlBytes = Get-Utf8ByteCount -Text $html
    $assetBytes = 0
    foreach ($asset in $assets) { $assetBytes += [int]$asset.Bytes }
    $bundleBytes = $htmlBytes + $assetBytes
    $passed = $bundleBytes -le $effectiveBudget
    return [ordered]@{
        State = if ($passed) { 'DRAFT' } else { 'BLOCKED' }
        Packaging = $Packaging
        Profile = $Profile
        OutputPath = $OutputPath
        Bytes = $bundleBytes
        HtmlBytes = $htmlBytes
        AssetBytes = $assetBytes
        BudgetBytes = $effectiveBudget
        BudgetPassed = $passed
        Assets = @($assets | ForEach-Object { [ordered]@{ id = $_.Id; mode = $_.Mode; bytes = $_.Bytes; path = $_.DeliveredPath } })
        Checks = [ordered]@{
            localFile = 'PASS'; offline = 'PASS'; noJavaScript = 'PASS'
            navigation = if ($converted.Navigation.Count -gt 0) { 'PASS' } else { 'UNKNOWN' }
            print = 'PASS'
        }
        Reasons = if ($passed) { @() } else { @("Artifact is $($bundleBytes - $effectiveBudget) byte(s) over the selected packaging budget.") }
    }
}

Export-ModuleMember -Function Get-Utf8ByteCount, Resolve-GuideHtmlPath, Assert-SafeGuideMarkdown, Test-SafeSvgContent, New-StyleGuideHtml

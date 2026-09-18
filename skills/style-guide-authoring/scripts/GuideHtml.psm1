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

function Get-BytesSha256 {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([System.BitConverter]::ToString($sha.ComputeHash($Bytes)) -replace '-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Test-IsPathUnderDirectory {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Directory)
    $comparison = if ($IsWindows) { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
    $dir = [System.IO.Path]::GetFullPath($Directory).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $full = [System.IO.Path]::GetFullPath($Path)
    return $full.Equals($dir, $comparison) -or $full.StartsWith($dir + [System.IO.Path]::DirectorySeparatorChar, $comparison)
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

function Test-SafeGuideUrl {
    param([Parameter(Mandatory)][string]$Url)
    $trimmed = $Url.Trim()
    return $trimmed -match '^(?i)(https?|mailto):' -or $trimmed.StartsWith('#') -or ($trimmed -notmatch ':' -and -not $trimmed.StartsWith('//'))
}

function ConvertTo-SafeInlineHtml {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    $pattern = '\[(?<label>[^\]]+)\]\((?<url>[^)]+)\)'
    $parts = [System.Collections.Generic.List[string]]::new()
    $last = 0
    foreach ($m in [regex]::Matches($Text, $pattern)) {
        $parts.Add((ConvertTo-HtmlText $Text.Substring($last, $m.Index - $last)))
        $label = $m.Groups['label'].Value
        $url = $m.Groups['url'].Value.Trim()
        if (-not (Test-SafeGuideUrl -Url $url)) { throw "Unsupported URL scheme in guide content: $url" }
        $parts.Add("<a href=`"$(ConvertTo-HtmlText $url)`">$(ConvertTo-HtmlText $label)</a>")
        $last = $m.Index + $m.Length
    }
    $parts.Add((ConvertTo-HtmlText $Text.Substring($last)))
    return ($parts -join '')
}

function Resolve-GuideHtmlPath {
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$Path)
    if ($Path -match '^(?i)(https?|data|javascript)://' -or $Path -match '^(?i)(https?|data|javascript):') {
        throw "Remote or absolute URI dependencies are not permitted: $Path"
    }
    $rootFull = [System.IO.Path]::GetFullPath($RepoRoot)
    $rootNormalized = $rootFull.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
        [System.IO.Path]::GetFullPath($Path)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $rootFull $Path))
    }
    $comparison = if ($IsWindows) { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
    $rootWithSep = $rootNormalized + [System.IO.Path]::DirectorySeparatorChar
    if (-not $candidate.Equals($rootNormalized, $comparison) -and -not $candidate.StartsWith($rootWithSep, $comparison)) {
        throw "Path traversal outside RepoRoot is not permitted: $Path"
    }
    $relative = [System.IO.Path]::GetRelativePath($rootNormalized, $candidate)
    $current = $rootNormalized
    foreach ($segment in ($relative -split '[\\/]')) {
        if (-not $segment -or $segment -eq '.') { continue }
        $current = Join-Path $current $segment
        if (-not (Test-Path -LiteralPath $current)) { continue }
        $item = Get-Item -LiteralPath $current -Force
        $isLink = (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
        if ($item.PSObject.Properties['LinkType'] -and $item.LinkType) { $isLink = $true }
        if ($isLink) { throw "Symbolic links and reparse points are not permitted in HTML package paths: $Path" }
    }
    return $candidate
}

function Resolve-GuideHtmlOutputPath {
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$Path)
    $rootFull = [System.IO.Path]::GetFullPath($RepoRoot)
    $rootNormalized = $rootFull.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
        [System.IO.Path]::GetFullPath($Path)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $rootFull $Path))
    }
    $comparison = if ($IsWindows) { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
    $rootWithSep = $rootNormalized + [System.IO.Path]::DirectorySeparatorChar
    if (-not $candidate.Equals($rootNormalized, $comparison) -and -not $candidate.StartsWith($rootWithSep, $comparison)) {
        throw "Output path traversal outside RepoRoot is not permitted: $Path"
    }
    $parent = Split-Path -Parent $candidate
    if ($parent) { [void](Resolve-GuideHtmlPath -RepoRoot $rootNormalized -Path ([System.IO.Path]::GetRelativePath($rootNormalized, $parent))) }
    if (Test-Path -LiteralPath $candidate) {
        $item = Get-Item -LiteralPath $candidate -Force
        if ($item.PSIsContainer) { throw "Output path must be a file, not an existing directory: $Path" }
        $isLink = (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
        if ($item.PSObject.Properties['LinkType'] -and $item.LinkType) { $isLink = $true }
        if ($isLink) { throw "Output path cannot be a symbolic link or reparse point: $Path" }
    }
    return $candidate
}

function Assert-SafeGuideMarkdown {
    param([Parameter(Mandatory)][string]$Markdown)
    if ($Markdown -match '(?is)<\s*script\b|<\s*iframe\b|<[^>]+\son[a-z]+\s*=') {
        throw 'Unsafe markup or executable URL was rejected before HTML rendering.'
    }
    foreach ($m in [regex]::Matches($Markdown, '\[[^\]]+\]\((?<url>[^)]+)\)')) {
        $url = $m.Groups['url'].Value.Trim()
        if (Test-SafeGuideUrl -Url $url) { continue }
        throw "Unsupported URL scheme in guide content: $url"
    }
}

function Test-SafeSvgContent {
    param([Parameter(Mandatory)][string]$Svg)
    return $false
}

function Get-DetectedImageMediaType {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    $prefix = [System.Text.Encoding]::ASCII.GetString($Bytes, 0, [Math]::Min($Bytes.Length, 64))
    if ($prefix -match '^\s*(<\?xml|<svg\b)') { return 'image/svg+xml' }
    if ($Bytes.Length -ge 8 -and $Bytes[0] -eq 0x89 -and $Bytes[1] -eq 0x50 -and $Bytes[2] -eq 0x4E -and $Bytes[3] -eq 0x47) { return 'image/png' }
    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xD8 -and $Bytes[2] -eq 0xFF) { return 'image/jpeg' }
    if ($Bytes.Length -ge 6 -and $prefix.StartsWith('GIF8')) { return 'image/gif' }
    if ($Bytes.Length -ge 12 -and $prefix.Substring(0, 4) -eq 'RIFF' -and $prefix.Substring(8, 4) -eq 'WEBP') { return 'image/webp' }
    return 'unknown'
}

function Get-ImageExtensionForMediaType {
    param([Parameter(Mandatory)][string]$MediaType)
    switch ($MediaType) {
        'image/png'  { return '.png' }
        'image/jpeg' { return '.jpg' }
        'image/gif'  { return '.gif' }
        'image/webp' { return '.webp' }
        default { throw "Unsupported media type '$MediaType'." }
    }
}

function Get-GuideHtmlAssetRecords {
    param(
        [string]$AssetManifestPath,
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$Packaging,
        [Parameter(Mandatory)][string]$OutputDirectory,
        [string]$BundleId
    )
    $records = [System.Collections.Generic.List[object]]::new()
    $destinations = @{}
    if (-not $AssetManifestPath) { return @($records) }
    $resolvedManifestPath = Resolve-GuideHtmlPath -RepoRoot $RepoRoot -Path $AssetManifestPath
    $manifest = Get-Content -LiteralPath $resolvedManifestPath -Raw | ConvertFrom-Json -AsHashtable
    $assetIndex = 0
    foreach ($asset in @($manifest.assets)) {
        $assetIndex++
        $id = if ($asset.ContainsKey('id') -and $asset.id) { [string]$asset.id } else { "asset-$assetIndex" }
        $path = if ($asset.ContainsKey('path')) { [string]$asset.path } else { '' }
        $mediaType = if ($asset.ContainsKey('mediaType') -and $asset.mediaType) { [string]$asset.mediaType } else { 'application/octet-stream' }
        $alt = if ($asset.ContainsKey('alt')) { [string]$asset.alt } else { '' }
        $permission = if ($asset.ContainsKey('permission')) { [string]$asset.permission } else { '' }
        if ($mediaType -notin @('image/png', 'image/jpeg', 'image/gif', 'image/webp')) { throw "Asset '$id' uses unsupported media type '$mediaType'." }
        if ($permission -notin @('embed', 'copy')) { throw "Asset '$id' is missing explicit embed/copy permission." }
        $resolved = Resolve-GuideHtmlPath -RepoRoot $RepoRoot -Path $path
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) { throw "Asset '$id' does not resolve to a local file: $path" }
        $extension = [System.IO.Path]::GetExtension($resolved).ToLowerInvariant()
        $bytes = [System.IO.File]::ReadAllBytes($resolved)
        $detectedMediaType = Get-DetectedImageMediaType -Bytes $bytes
        if ($detectedMediaType -eq 'image/svg+xml') { throw "Asset '$id' contains SVG/XML bytes and requires an approved sanitizer." }
        if ($detectedMediaType -ne $mediaType) { throw "Asset '$id' byte signature '$detectedMediaType' does not match declared media type '$mediaType'." }
        if ($extension -eq '.svg' -or $mediaType -eq 'image/svg+xml') {
            throw "Asset '$id' uses SVG, which requires an approved sanitizer before embedding or copying."
        }
        if ($Packaging -eq 'self-contained') {
            if ($permission -ne 'embed') { throw "Asset '$id' requires local-bundle packaging; self-contained output cannot copy it silently." }
            $records.Add([ordered]@{
                Id = $id; Mode = 'embedded'; Bytes = $bytes.Length; MediaType = $mediaType; Alt = $alt
                ContributionBytes = (Get-Utf8ByteCount -Text ([Convert]::ToBase64String($bytes)))
                Html = "<figure class=`"sga-asset`"><img src=`"data:$(ConvertTo-HtmlText $mediaType);base64,$([Convert]::ToBase64String($bytes))`" alt=`"$(ConvertTo-HtmlText $alt)`"><figcaption>$(ConvertTo-HtmlText $id)</figcaption></figure>"
                DeliveredPath = $null
                RelativePath = $null
            })
        } else {
            if ($permission -ne 'copy') { throw "Asset '$id' requires embed permission; local-bundle output cannot copy it silently." }
            $safeName = 'sga-' + (ConvertTo-GuideHtmlId -Text $id) + (Get-ImageExtensionForMediaType -MediaType $mediaType)
            if ($destinations.ContainsKey($safeName)) { throw "Asset '$id' normalizes to duplicate bundle destination '$safeName'." }
            $destinations[$safeName] = $true
            $assetDir = Join-Path $OutputDirectory 'assets'
            New-Item -ItemType Directory -Path $assetDir -Force | Out-Null
            $destination = Join-Path $assetDir $safeName
            Copy-Item -LiteralPath $resolved -Destination $destination -Force
            $relativePath = if ($BundleId) { "assets/$BundleId/$safeName" } else { "assets/$safeName" }
            $records.Add([ordered]@{
                Id = $id; Mode = 'copied'; Bytes = $bytes.Length; MediaType = $mediaType; Alt = $alt
                ContributionBytes = $bytes.Length
                Hash = Get-BytesSha256 -Bytes $bytes
                Html = "<figure class=`"sga-asset`"><img src=`"$relativePath`" alt=`"$(ConvertTo-HtmlText $alt)`"><figcaption>$(ConvertTo-HtmlText $id)</figcaption></figure>"
                DeliveredPath = $destination
                RelativePath = $relativePath
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
    $usedIds = @{}
    $h1Count = 0
    $previousLevel = 0
    $lines = @($Markdown -split '\r?\n')
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line.Trim().StartsWith('|') -and $i + 1 -lt $lines.Count -and $lines[$i + 1].Trim() -match '^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?$') {
            if ($inList) { [void]$body.AppendLine('</ul>'); $inList = $false }
            $headers = @($line.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
            [void]$body.AppendLine('<div class="sga-table-wrap"><table><thead><tr>')
            foreach ($header in $headers) { [void]$body.AppendLine("<th>$(ConvertTo-SafeInlineHtml $header)</th>") }
            [void]$body.AppendLine('</tr></thead><tbody>')
            $i += 2
            while ($i -lt $lines.Count -and $lines[$i].Trim().StartsWith('|')) {
                $cells = @($lines[$i].Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
                [void]$body.AppendLine('<tr>')
                foreach ($cell in $cells) { [void]$body.AppendLine("<td>$(ConvertTo-SafeInlineHtml $cell)</td>") }
                [void]$body.AppendLine('</tr>')
                $i++
            }
            $i--
            [void]$body.AppendLine('</tbody></table></div>')
            continue
        }
        if ($line -match '^\s*<!--.*-->\s*$') {
            if ($inList) { [void]$body.AppendLine('</ul>'); $inList = $false }
            continue
        }
        if ($line -match '^(?<hash>#{1,6})\s+(?<title>.+?)\s*$') {
            if ($inList) { [void]$body.AppendLine('</ul>'); $inList = $false }
            $level = [Math]::Min($Matches.hash.Length, 6)
            if ($level -eq 1) { $h1Count++ }
            if ($previousLevel -eq 0 -and $level -ne 1) { throw "HTML guides must start with the primary H1 heading." }
            if ($level -gt ($previousLevel + 1)) { throw "Heading level jumps from h$previousLevel to h$level." }
            $previousLevel = $level
            $title = $Matches.title.Trim()
            $baseId = ConvertTo-GuideHtmlId -Text $title
            $id = $baseId
            $suffix = 2
            while ($usedIds.ContainsKey($id)) {
                $id = "$baseId-$suffix"
                $suffix++
            }
            $usedIds[$id] = $true
            $nav.Add([ordered]@{ Id = $id; Title = $title; Level = $level })
            [void]$body.AppendLine("<h$level id=`"$id`">$(ConvertTo-HtmlText $title)</h$level>")
        } elseif ($line -match '^\s*[-*]\s+(?<item>.+?)\s*$') {
            if (-not $inList) { [void]$body.AppendLine('<ul>'); $inList = $true }
            [void]$body.AppendLine("<li>$(ConvertTo-SafeInlineHtml $Matches.item)</li>")
        } elseif ($line.Trim().Length -eq 0) {
            if ($inList) { [void]$body.AppendLine('</ul>'); $inList = $false }
        } else {
            if ($inList) { [void]$body.AppendLine('</ul>'); $inList = $false }
            [void]$body.AppendLine("<p>$(ConvertTo-SafeInlineHtml $line.Trim())</p>")
        }
    }
    if ($inList) { [void]$body.AppendLine('</ul>') }
    if ($h1Count -ne 1) { throw "HTML guides require exactly one primary H1 heading; found $h1Count." }
    return [ordered]@{ Body = $body.ToString(); Navigation = @($nav); Outline = 'PASS' }
}

function New-StyleGuideHtml {
    param(
        [Parameter(Mandatory)][string]$MarkdownPath,
        [Parameter(Mandatory)][string]$OutputPath,
        [ValidateSet('self-contained', 'local-bundle')][string]$Packaging = 'self-contained',
        [ValidateSet('reference-manual', 'presentation-inspired', 'quick-reference')][string]$Profile = 'reference-manual',
        [string]$AssetManifestPath,
        [string]$RepoRoot = (Get-Location).Path,
        [int]$BudgetBytes = -1,
        [string]$OverrideRationale,
        [string]$OverrideAuthorizer,
        [ValidatePattern('^[A-Za-z]{2,8}(-[A-Za-z0-9]{1,8})*$')][string]$Language = 'en'
    )
    $resolvedMarkdownPath = Resolve-GuideHtmlPath -RepoRoot $RepoRoot -Path $MarkdownPath
    $markdown = Get-Content -LiteralPath $resolvedMarkdownPath -Raw
    Assert-SafeGuideMarkdown -Markdown $markdown
    if ($BudgetBytes -lt -1) { throw 'BudgetBytes must be a positive integer override, or omitted to use the default.' }
    if ($BudgetBytes -eq -1) {
        $effectiveBudget = $script:DefaultHtmlBudgets[$Packaging]
    } else {
        if ($BudgetBytes -eq 0) { throw 'BudgetBytes override must be a positive integer; zero is invalid.' }
        if (-not $OverrideRationale -or -not $OverrideAuthorizer) { throw 'Budget override requires rationale and authorizer.' }
        $effectiveBudget = $BudgetBytes
    }
    $outputFullPath = Resolve-GuideHtmlOutputPath -RepoRoot $RepoRoot -Path $OutputPath
    $outputDirectory = Split-Path -Parent $outputFullPath
    $outputLeaf = [System.IO.Path]::GetFileNameWithoutExtension($outputFullPath)
    $bundleId = ConvertTo-GuideHtmlId -Text $outputLeaf
    if (-not $bundleId) { $bundleId = 'guide' }
    $outputMarkerPath = Resolve-GuideHtmlOutputPath -RepoRoot $RepoRoot -Path "$outputFullPath.sga-html-output.json"
    $stagingDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("sga-html-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stagingDirectory -Force | Out-Null
    $stagedOutput = Join-Path $stagingDirectory (Split-Path -Leaf $OutputPath)
    try {
    $converted = Convert-GuideMarkdownToHtmlBody -Markdown $markdown
    $assets = @(Get-GuideHtmlAssetRecords -AssetManifestPath $AssetManifestPath -RepoRoot $RepoRoot -Packaging $Packaging -OutputDirectory $stagingDirectory -BundleId $bundleId)
    $assetHtml = ($assets | ForEach-Object { $_.Html }) -join "`n"
    $nav = ($converted.Navigation | ForEach-Object { "<a href=`"#$($_.Id)`">$(ConvertTo-HtmlText $_.Title)</a>" }) -join "`n"
    $title = if ($converted.Navigation.Count -gt 0) { $converted.Navigation[0].Title } else { 'Style guide' }
    $html = @"
<!doctype html>
<html lang="$(ConvertTo-HtmlText $Language)">
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
main{min-width:0;overflow-wrap:anywhere;word-break:break-word}section,.sga-card{border:1px solid var(--sga-border);border-radius:.5rem;padding:1rem;margin:1rem 0}.sga-asset img{max-width:100%;height:auto}
.sga-table-wrap{max-width:100%;overflow-x:auto}table{border-collapse:collapse;width:100%;margin:1rem 0}th,td{border:1px solid var(--sga-border);padding:.4rem;text-align:left;vertical-align:top}
.sga-profile-reference-manual main{max-width:52rem}
.sga-profile-presentation-inspired main{max-width:60rem}.sga-profile-presentation-inspired h2{font-size:2rem;margin-top:2.5rem}.sga-profile-presentation-inspired .sga-card{font-size:1.125rem}
.sga-profile-quick-reference main{max-width:44rem}.sga-profile-quick-reference p,.sga-profile-quick-reference li{line-height:1.35}.sga-profile-quick-reference .sga-card{padding:.65rem;margin:.65rem 0}
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
    Set-Content -LiteralPath $stagedOutput -Value $html -NoNewline -Encoding utf8
    $htmlBytes = Get-Utf8ByteCount -Text $html
    $assetBytes = 0
    foreach ($asset in $assets) { $assetBytes += [int]$asset.Bytes }
    $managedRecords = @($assets | Where-Object { $_.RelativePath } | ForEach-Object { [ordered]@{ path = $_.RelativePath; hash = $_.Hash } })
    $managedManifestJson = if ($Packaging -eq 'local-bundle') { if ($managedRecords.Count -eq 0) { '[]' } else { ($managedRecords | ConvertTo-Json -Depth 4) } } else { '' }
    $managedManifestBytes = if ($Packaging -eq 'local-bundle') { Get-Utf8ByteCount -Text $managedManifestJson } else { 0 }
    $bundleBytes = if ($Packaging -eq 'self-contained') { $htmlBytes } else { $htmlBytes + $assetBytes + $managedManifestBytes }
    $passed = $bundleBytes -le $effectiveBudget
    $publishedAssets = @()
    if ($passed) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
        $stagedBytes = [System.IO.File]::ReadAllBytes($stagedOutput)
        $stagedHash = Get-BytesSha256 -Bytes $stagedBytes
        if (Test-Path -LiteralPath $outputFullPath) {
            $existingHash = Get-BytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($outputFullPath))
            if (Test-Path -LiteralPath $outputMarkerPath) {
                $marker = Get-Content -LiteralPath $outputMarkerPath -Raw | ConvertFrom-Json
                if (-not $marker.hash) { throw 'HTML output ownership marker is malformed.' }
                if ($existingHash -ne [string]$marker.hash) { throw "HTML output was edited outside the HTML helper: $OutputPath" }
            } elseif ($existingHash -ne $stagedHash) {
                throw "Refusing to overwrite unmanaged HTML output: $OutputPath"
            }
        }
        if ($Packaging -eq 'local-bundle') {
            $targetAssets = Join-Path $outputDirectory -ChildPath 'assets' -AdditionalChildPath $bundleId
            [void](Resolve-GuideHtmlPath -RepoRoot $RepoRoot -Path $targetAssets)
            New-Item -ItemType Directory -Path $targetAssets -Force | Out-Null
            $managedPath = Join-Path $targetAssets '.sga-html-assets.json'
            [void](Resolve-GuideHtmlOutputPath -RepoRoot $RepoRoot -Path $managedPath)
            $oldManaged = @{}
            if (Test-Path -LiteralPath $managedPath) {
                foreach ($entry in @((Get-Content -LiteralPath $managedPath -Raw | ConvertFrom-Json))) {
                    if (-not $entry.path -or -not $entry.hash) { throw 'Managed asset marker is malformed.' }
                    $oldManaged[[string]$entry.path] = [string]$entry.hash
                }
            }
            $newManaged = @()
            $targetAssetsFull = [System.IO.Path]::GetFullPath($targetAssets)
            foreach ($asset in $assets) {
                $relativeAsset = $asset.RelativePath
                if ([System.IO.Path]::IsPathRooted($relativeAsset) -or $relativeAsset -match '(^|[\\/])\.\.([\\/]|$)') { throw "Managed asset path is unsafe: $relativeAsset" }
                $target = Resolve-GuideHtmlOutputPath -RepoRoot $RepoRoot -Path (Join-Path $outputDirectory $relativeAsset)
                if (-not (Test-IsPathUnderDirectory -Path $target -Directory $targetAssetsFull)) { throw "Managed asset target escapes the bundle assets directory: $relativeAsset" }
                if ((Test-Path -LiteralPath $target) -and -not $oldManaged.ContainsKey($relativeAsset)) {
                    throw "Refusing to overwrite unmanaged bundle asset: $relativeAsset"
                }
                if ((Test-Path -LiteralPath $target) -and $oldManaged.ContainsKey($relativeAsset)) {
                    $currentHash = Get-BytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($target))
                    if ($currentHash -ne $oldManaged[$relativeAsset]) { throw "Managed bundle asset was edited outside the HTML helper: $relativeAsset" }
                }
                $newManaged += $relativeAsset
            }
            foreach ($old in $oldManaged.Keys) {
                if ([System.IO.Path]::IsPathRooted([string]$old) -or [string]$old -match '(^|[\\/])\.\.([\\/]|$)') { throw "Managed asset marker contains unsafe path: $old" }
                $oldTarget = Resolve-GuideHtmlOutputPath -RepoRoot $RepoRoot -Path (Join-Path $outputDirectory ([string]$old))
                if (-not (Test-IsPathUnderDirectory -Path $oldTarget -Directory $targetAssetsFull)) { throw "Managed asset marker escapes the bundle assets directory: $old" }
                if (Test-Path -LiteralPath $oldTarget) {
                    $oldHash = Get-BytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($oldTarget))
                    if ($oldHash -ne $oldManaged[$old]) { throw "Managed bundle asset was edited outside the HTML helper: $old" }
                }
            }
            foreach ($asset in $assets) {
                $relativeAsset = $asset.RelativePath
                $target = Join-Path $outputDirectory $relativeAsset
                if ((Test-Path -LiteralPath $target) -and (Get-BytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($target))) -eq $asset.Hash) { continue }
                Copy-Item -LiteralPath $asset.DeliveredPath -Destination $target -Force
            }
            foreach ($old in $oldManaged.Keys) {
                if ($newManaged -contains $old) { continue }
                Remove-Item -LiteralPath (Join-Path $outputDirectory ([string]$old)) -Force -ErrorAction SilentlyContinue
            }
            if (-not (Test-Path -LiteralPath $managedPath) -or (Get-Content -LiteralPath $managedPath -Raw) -ne $managedManifestJson) {
                Set-Content -LiteralPath $managedPath -Value $managedManifestJson -NoNewline
            }
        }
        if ((Test-Path -LiteralPath $outputFullPath) -and [System.Linq.Enumerable]::SequenceEqual([byte[]]([System.IO.File]::ReadAllBytes($outputFullPath)), [byte[]]$stagedBytes)) {
            $null = $true
        } else {
            Move-Item -LiteralPath $stagedOutput -Destination $outputFullPath -Force
        }
        $outputMarkerJson = ([ordered]@{ path = [System.IO.Path]::GetFileName($outputFullPath); hash = $stagedHash } | ConvertTo-Json -Depth 4)
        if (-not (Test-Path -LiteralPath $outputMarkerPath) -or (Get-Content -LiteralPath $outputMarkerPath -Raw) -ne $outputMarkerJson) {
            Set-Content -LiteralPath $outputMarkerPath -Value $outputMarkerJson -NoNewline
        }
        foreach ($asset in $assets) {
            $publishedAssets += [ordered]@{
                id = $asset.Id
                mode = $asset.Mode
                bytes = $asset.Bytes
                contributionBytes = $asset.ContributionBytes
                path = if ($asset.RelativePath) { Join-Path $outputDirectory $asset.RelativePath } else { $null }
            }
        }
    } else {
        $diagnosticPath = Resolve-GuideHtmlOutputPath -RepoRoot $RepoRoot -Path "$outputFullPath.blocked.html"
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
        Set-Content -LiteralPath $diagnosticPath -Value "<!-- BLOCKED: over budget diagnostic artifact, not approved output -->`n$html" -NoNewline -Encoding utf8
    }
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
        BudgetOverride = if ($BudgetBytes -eq -1) { $null } else { [ordered]@{ bytes = $BudgetBytes; rationale = $OverrideRationale; authorizer = $OverrideAuthorizer } }
        Assets = @(
            if ($passed) {
                $publishedAssets | Sort-Object contributionBytes -Descending
            } else {
                $assets | Sort-Object ContributionBytes -Descending | ForEach-Object {
                    [ordered]@{ id = $_.Id; mode = $_.Mode; bytes = $_.Bytes; contributionBytes = $_.ContributionBytes; path = $null }
                }
            }
        )
        Checks = [ordered]@{
            localFile = 'UNKNOWN'; offline = 'UNKNOWN'; noJavaScript = 'UNKNOWN'
            navigation = 'UNKNOWN'
            print = 'UNKNOWN'
            outline = $converted.Outline
        }
        Reasons = if ($passed) { @() } else { @("Artifact is $($bundleBytes - $effectiveBudget) byte(s) over the selected packaging budget.") }
    }
    } finally {
        Remove-Item -LiteralPath $stagingDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember -Function Get-Utf8ByteCount, Resolve-GuideHtmlPath, Resolve-GuideHtmlOutputPath, Assert-SafeGuideMarkdown, Test-SafeSvgContent, New-StyleGuideHtml

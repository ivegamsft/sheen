#!/usr/bin/env pwsh
# sync.ps1 --- basecoat-sheen consumer sync (PowerShell)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$DefaultSource = 'https://github.com/IBuySpy-Shared/basecoat-sheen.git'
$DefaultRef    = 'main'

$TargetMap = [ordered]@{
    skills       = '.github/skills'
    agents       = '.github/agents'
    instructions = '.github/instructions'
    prompts      = '.github/prompts'
    templates    = 'sheen/templates'
    tokens       = 'sheen/tokens'
}

$SourceMap = [ordered]@{
    skills       = @('.github/skills', 'skills')
    agents       = @('.github/agents', 'agents')
    instructions = @('.github/instructions', 'instructions')
    prompts      = @('.github/prompts', 'prompts', 'vendor/basecoat/prompts')
    templates    = @('templates')
    tokens       = @('tokens')
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is required' }
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { throw 'Run this inside a git repository' }

$configPath = Join-Path $repoRoot '.sheen.yml'
$configData = $null
if (Test-Path -LiteralPath $configPath) {
    try {
        $configData = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Yaml
    } catch {
        throw ".sheen.yml parse failed: $($_.Exception.Message)"
    }
}

function Test-HasProp {
    param($Obj, [string]$Name)
    if ($null -eq $Obj) { return $false }
    if ($Obj -is [System.Collections.IDictionary]) { return $Obj.Contains($Name) }
    return $null -ne ($Obj.PSObject.Properties | Where-Object { $_.Name -eq $Name })
}

function Get-PropValue {
    param($Obj, [string]$Name)
    if ($Obj -is [System.Collections.IDictionary]) { return $Obj[$Name] }
    return $Obj.$Name
}

function Get-ConfigScalar {
    param([Parameter(Mandatory)][string]$Key)
    if (-not (Test-HasProp -Obj $script:configData -Name $Key)) { return $null }
    $value = Get-PropValue -Obj $script:configData -Name $Key
    if ($null -eq $value) { return $null }
    $text = [string]$value
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    return $text.Trim()
}

function Convert-ToList {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [string]) {
        $trimmed = $Value.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) { return @() }
        return @($trimmed)
    }
    $items = New-Object System.Collections.Generic.List[string]
    foreach ($item in $Value) {
        $text = [string]$item
        if (-not [string]::IsNullOrWhiteSpace($text)) { $items.Add($text.Trim()) }
    }
    return @($items)
}

function Get-ConfigListSpec {
    param([Parameter(Mandatory)][string]$Key)
    if (Test-HasProp -Obj $script:configData -Name $Key) {
        return @{ Present = $true; Items = @(Convert-ToList -Value (Get-PropValue -Obj $script:configData -Name $Key)) }
    }
    if (Test-HasProp -Obj $script:configData -Name 'sync') {
        $syncObj = Get-PropValue -Obj $script:configData -Name 'sync'
        if (-not (Test-HasProp -Obj $syncObj -Name $Key)) { return @{ Present = $false; Items = $null } }
        return @{ Present = $true; Items = @(Convert-ToList -Value (Get-PropValue -Obj $syncObj -Name $Key)) }
    }
    return @{ Present = $false; Items = $null }
}

function Normalize-Name {
    param(
        [Parameter(Mandatory)][string]$Type,
        [Parameter(Mandatory)][string]$Name
    )
    $value = $Name.Trim()
    $value = $value -replace '\.(md|markdown|txt|ya?ml|json)$', ''
    switch ($Type) {
        'agents'       { $value = $value -replace '\.agent(\.eval)?$', '' }
        'instructions' { $value = $value -replace '\.instructions$', '' }
        'prompts'      { $value = $value -replace '\.prompt$', '' }
        'themes'       { $value = $value -replace '\.tokens$', '' }
        default        { }
    }
    return $value
}

function Normalize-AllowSet {
    param([string]$Type, [object[]]$Items)
    $set = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($item in $Items) {
        $normalized = Normalize-Name -Type $Type -Name ([string]$item)
        if (-not [string]::IsNullOrWhiteSpace($normalized)) { [void]$set.Add($normalized) }
    }
    return $set
}

function Test-IsExcluded {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [string[]]$Patterns
    )
    foreach ($raw in $Patterns) {
        $pattern = ($raw ?? '').Trim()
        if ([string]::IsNullOrWhiteSpace($pattern)) { continue }
        $normalized = $pattern -replace '\\', '/'
        if ($normalized.EndsWith('/')) {
            $prefix = $normalized.TrimEnd('/')
            if ($RelativePath -eq $prefix -or $RelativePath.StartsWith("$prefix/")) { return $true }
            continue
        }

        if ($RelativePath -like $normalized -or $RelativePath -like "$normalized/*") { return $true }
    }
    return $false
}

function Test-WasPreviouslyManaged {
    param(
        [Parameter(Mandatory)][string]$Path,
        [System.Collections.Generic.HashSet[string]]$PreviousManaged
    )
    if ($null -eq $PreviousManaged) { return $false }
    if ($PreviousManaged.Contains($Path)) { return $true }
    foreach ($managedPath in $PreviousManaged) {
        if ($null -ne $managedPath -and $managedPath.StartsWith("$Path/")) { return $true }
    }
    return $false
}

function Add-ManifestFile {
    param(
        [System.Collections.Generic.List[string]]$ManifestFiles,
        [string]$RepoRoot,
        [string]$Path
    )
    $rel = [System.IO.Path]::GetRelativePath($RepoRoot, $Path).Replace('\', '/')
    if (-not $ManifestFiles.Contains($rel)) { [void]$ManifestFiles.Add($rel) }
}

$source = if ($env:SHEEN_REPO) { $env:SHEEN_REPO } else { Get-ConfigScalar -Key 'source' }
if (-not $source) { $source = $DefaultSource }
$ref = if ($env:SHEEN_REF) { $env:SHEEN_REF } else { Get-ConfigScalar -Key 'ref' }
if (-not $ref) { $ref = $DefaultRef }

$displaySource = $source -replace '(?i)^(https?://)[^/@]*@', '$1' -replace '[?#].*$', ''
Write-Host "sheen sync: $displaySource @ $ref"

$themesSpec = Get-ConfigListSpec -Key 'themes'
$excludeSpec = Get-ConfigListSpec -Key 'exclude'
$excludePatterns = if ($excludeSpec.Present) { @($excludeSpec.Items) } else { @() }

$previousManaged = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
$previousManifest = Join-Path $repoRoot '.sheen/manifest.json'
if (Test-Path -LiteralPath $previousManifest) {
    try {
        $prev = Get-Content -LiteralPath $previousManifest -Raw | ConvertFrom-Json
        foreach ($item in @($prev.files)) { [void]$previousManaged.Add([string]$item) }
    } catch { }
}

$work = Join-Path ([System.IO.Path]::GetTempPath()) ("sheen-sync-" + [guid]::NewGuid().ToString('N'))
$manifest = [ordered]@{
    schema  = 'sheen-manifest/v1'
    source  = $displaySource
    ref     = $ref
    synced  = (Get-Date).ToUniversalTime().ToString('o')
    commit  = $null
    files   = New-Object System.Collections.Generic.List[string]
}

try {
    git clone --quiet --depth 1 --branch $ref $source $work 2>$null
    if ($LASTEXITCODE -ne 0) {
        git clone --quiet $source $work
        if ($LASTEXITCODE -ne 0) { throw "clone failed: $displaySource" }
        git -C $work checkout --quiet $ref
    }
    $manifest.commit = (git -C $work rev-parse HEAD).Trim()

    foreach ($type in $TargetMap.Keys) {
        $sourceCandidates = if ($SourceMap.Contains($type)) { @($SourceMap[$type]) } else { @($type) }
        $srcDirs = New-Object System.Collections.Generic.List[string]
        foreach ($candidate in $sourceCandidates) {
            $srcDir = Join-Path $work $candidate
            if (Test-Path -LiteralPath $srcDir) { [void]$srcDirs.Add($srcDir) }
        }
        if ($srcDirs.Count -eq 0) { continue }

        $allowSpec = Get-ConfigListSpec -Key $type
        $allowSet = $null
        if ($allowSpec.Present) { $allowSet = Normalize-AllowSet -Type $type -Items $allowSpec.Items }
        if ($allowSpec.Present -and $null -eq $allowSet) {
            $allowSet = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
        }

        $destRoot = Join-Path $repoRoot $TargetMap[$type]

        $seenEntries = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
        $matchedAllowEntries = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($srcDir in $srcDirs) {
            Get-ChildItem -LiteralPath $srcDir -Force | Where-Object { $_.Name -ne '.gitkeep' } | ForEach-Object {
                if (-not $seenEntries.Add($_.Name)) { return }
                $sourceRelative = "$type/$($_.Name)"
                if (Test-IsExcluded -RelativePath $sourceRelative -Patterns $excludePatterns) { return }

                $normalizedEntryName = Normalize-Name -Type $type -Name $_.Name
                if ($allowSpec.Present -and -not $allowSet.Contains($normalizedEntryName)) { return }
                if ($allowSpec.Present) { [void]$matchedAllowEntries.Add($normalizedEntryName) }

                $dest = Join-Path $destRoot $_.Name
                $destRel = ($TargetMap[$type] + '/' + $_.Name)

                $wasManaged = Test-WasPreviouslyManaged -Path $destRel -PreviousManaged $previousManaged
                if ((Test-Path -LiteralPath $dest) -and -not $wasManaged) {
                    Write-Warning "sheen sync: preserving consumer-owned path (collision): $destRel"
                    return
                }

                New-Item -ItemType Directory -Force -Path $destRoot | Out-Null

                if ($_.PSIsContainer) {
                    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
                    Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force

                    if ($type -eq 'tokens' -and $_.Name -eq 'themes' -and $themesSpec.Present) {
                        $themeAllow = Normalize-AllowSet -Type 'themes' -Items $themesSpec.Items
                        Get-ChildItem -LiteralPath $dest -Force | Where-Object { $_.Name -ne '.gitkeep' } | ForEach-Object {
                            $candidate = Normalize-Name -Type 'themes' -Name $_.Name
                            if (-not $themeAllow.Contains($candidate)) {
                                Remove-Item -LiteralPath $_.FullName -Recurse -Force
                            }
                        }
                    }

                    Get-ChildItem -LiteralPath $dest -File -Recurse | ForEach-Object {
                        Add-ManifestFile -ManifestFiles $manifest.files -RepoRoot $repoRoot -Path $_.FullName
                    }
                } else {
                    Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
                    Add-ManifestFile -ManifestFiles $manifest.files -RepoRoot $repoRoot -Path $dest
                }
            }
        }

        if ($allowSpec.Present -and (Test-Path -LiteralPath $destRoot)) {
            Get-ChildItem -LiteralPath $destRoot -Force | Where-Object { $_.Name -ne '.gitkeep' } | ForEach-Object {
                $candidate = Normalize-Name -Type $type -Name $_.Name
                if ($allowSet.Contains($candidate)) { return }
                $candidateRel = ($TargetMap[$type] + '/' + $_.Name)
                if (Test-WasPreviouslyManaged -Path $candidateRel -PreviousManaged $previousManaged) {
                    Remove-Item -LiteralPath $_.FullName -Recurse -Force
                }
            }
        }

        # Warn about allow-list entries that matched nothing in source (#88)
        if ($allowSpec.Present -and $allowSet.Count -gt 0) {
            foreach ($entry in $allowSet) {
                if (-not $matchedAllowEntries.Contains($entry)) {
                    Write-Warning "sheen sync: sync.$type allow-list entry '$entry' did not match any source file; check spelling or suffix"
                }
            }
        }
    }

    $manifestDir = Join-Path $repoRoot '.sheen'
    New-Item -ItemType Directory -Force -Path $manifestDir | Out-Null
    $manifestPath = Join-Path $manifestDir 'manifest.json'
    ($manifest | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath $manifestPath -Encoding utf8
    Write-Host ("sheen sync: wrote {0} file(s); manifest at .sheen/manifest.json" -f $manifest.files.Count)

    $materialize = Get-ConfigScalar -Key 'materialize_tokens'
    if ($materialize -and $materialize -notin @('false', 'no', '0')) {
        $buildScript = Join-Path $repoRoot 'scripts' 'build-tokens.ps1'
        if (-not (Test-Path -LiteralPath $buildScript)) {
            # Provision the build script from the upstream clone into the consumer repo (#86)
            $upstreamBuildScript = Join-Path $work 'scripts' 'build-tokens.ps1'
            if (Test-Path -LiteralPath $upstreamBuildScript) {
                $scriptsDir = Join-Path $repoRoot 'scripts'
                New-Item -ItemType Directory -Force -Path $scriptsDir | Out-Null
                Copy-Item -LiteralPath $upstreamBuildScript -Destination $buildScript -Force
                Write-Host 'sheen sync: provisioned scripts/build-tokens.ps1 from upstream (materialize_tokens=true)'
            } else {
                Write-Warning 'sheen sync: materialize_tokens=true but build-tokens.ps1 not found in upstream; skipping token build'
            }
        }
        if (Test-Path -LiteralPath $buildScript) {
            # Always pass consumer token paths explicitly (#92). build-tokens.ps1 also
            # auto-detects sheen/tokens, but sync must not rely on defaults alone.
            $tokensDir = Join-Path $repoRoot 'sheen' 'tokens'
            $outDir = Join-Path $repoRoot 'dist' 'tokens'
            Write-Host "sheen sync: running token build (materialize_tokens=true; TokensDir=$tokensDir)..."
            & $buildScript -TokensDir $tokensDir -OutDir $outDir
            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "token build failed (exit $LASTEXITCODE)" }
        }
    }

    # ── generate_design_md: export DESIGN.md from DTCG tokens (Stitch/Google format) ──
    $genDesign = Get-ConfigScalar -Key 'generate_design_md'
    if ($genDesign -and $genDesign -notin @('false', 'no', '0')) {
        $designScript = Join-Path $repoRoot 'scripts' 'build-design-md.ps1'
        if (-not (Test-Path -LiteralPath $designScript)) {
            # Provision the build script from the upstream clone
            $upstreamDesignScript = Join-Path $work 'scripts' 'build-design-md.ps1'
            if (Test-Path -LiteralPath $upstreamDesignScript) {
                $scriptsDir = Join-Path $repoRoot 'scripts'
                New-Item -ItemType Directory -Force -Path $scriptsDir | Out-Null
                Copy-Item -LiteralPath $upstreamDesignScript -Destination $designScript -Force
                Write-Host 'sheen sync: provisioned scripts/build-design-md.ps1 from upstream (generate_design_md=true)'
            } else {
                Write-Warning 'sheen sync: generate_design_md=true but build-design-md.ps1 not found in upstream; skipping'
            }
        }
        if (Test-Path -LiteralPath $designScript) {
            $themeArg = Get-ConfigScalar -Key 'design_md_theme'
            if (-not $themeArg) { $themeArg = 'light' }
            Write-Host "sheen sync: generating DESIGN.md (generate_design_md=true; theme=$themeArg)..."
            & $designScript -Theme $themeArg
            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "build-design-md failed (exit $LASTEXITCODE)" }
        }
    }
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}

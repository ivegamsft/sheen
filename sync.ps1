#!/usr/bin/env pwsh
# sync.ps1 --- basecoat-sheen consumer sync (PowerShell)
#
# Applies the "finish coat" to the current repo: clones the upstream sheen source
# at the configured ref, resolves the .sheen.yml allow-lists, copies selected
# assets into the consumer's customization directories, and records a manifest so
# rollback.ps1 can revert precisely.
#
# Idempotent: re-running with the same config yields the same tree.
# Behavior-equivalent to sync.sh.
#
# Config precedence: SHEEN_REPO / SHEEN_REF env vars > repo-root .sheen.yml > defaults.
# See specs/06-consumption-sync.spec.md.

$ErrorActionPreference = 'Stop'

$DefaultSource = 'https://github.com/IBuySpy-Shared/basecoat-sheen.git'
$DefaultRef    = 'main'

# Asset type -> consumer target directory. Skills/agents live under .github so the
# Copilot CLI discovers them; the rest land under a namespaced sheen/ tree.
$TargetMap = [ordered]@{
    skills       = '.github/skills'
    agents       = '.github/agents'
    instructions = '.github/instructions'
    prompts      = '.github/prompts'
    templates    = 'sheen/templates'
    tokens       = 'sheen/tokens'
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is required' }

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { throw 'Run this inside a git repository' }

function Get-SheenYmlValue {
    param([Parameter(Mandatory)][string]$Key, [Parameter(Mandatory)][string]$RepoRoot)
    $config = Join-Path $RepoRoot '.sheen.yml'
    if (-not (Test-Path -LiteralPath $config)) { return $null }
    foreach ($line in Get-Content -LiteralPath $config) {
        if ($line -match "^$([regex]::Escape($Key)):\s*(.*)$") {
            $value = ($Matches[1] -replace '\s+#.*$', '').Trim()
            if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") { $value = $Matches[1] }
            if ([string]::IsNullOrWhiteSpace($value)) { return $null }
            return $value
        }
    }
    return $null
}

# Resolve an allow-list. Returns $null when the key is absent (=> sync all),
# or an array of names when present (inline [a, b] or a following block list).
function Get-SheenYmlList {
    param([Parameter(Mandatory)][string]$Key, [Parameter(Mandatory)][string]$RepoRoot)
    $config = Join-Path $RepoRoot '.sheen.yml'
    if (-not (Test-Path -LiteralPath $config)) { return $null }
    $lines = Get-Content -LiteralPath $config
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^$([regex]::Escape($Key)):\s*(.*)$") {
            $rest = ($Matches[1] -replace '\s+#.*$', '').Trim()
            if ($rest -match '^\[(.*)\]$') {
                return @($Matches[1].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            }
            $items = @()
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j] -match '^\s+-\s*(.+?)\s*$') { $items += $Matches[1].Trim() }
                elseif ($lines[$j] -match '^\s*#') { continue }
                elseif ($lines[$j] -match '^\s*$') { continue }
                else { break }
            }
            return ,$items
        }
    }
    return $null
}

$source = if ($env:SHEEN_REPO) { $env:SHEEN_REPO } else { (Get-SheenYmlValue -Key 'source' -RepoRoot $repoRoot) }
if (-not $source) { $source = $DefaultSource }
$ref = if ($env:SHEEN_REF) { $env:SHEEN_REF } else { (Get-SheenYmlValue -Key 'ref' -RepoRoot $repoRoot) }
if (-not $ref) { $ref = $DefaultRef }

$displaySource = $source -replace '(?i)^(https?://)[^/@]*@', '$1' -replace '[?#].*$', ''
Write-Host "sheen sync: $displaySource @ $ref"

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
        $srcDir = Join-Path $work $type
        if (-not (Test-Path -LiteralPath $srcDir)) { continue }
        $allow = Get-SheenYmlList -Key $type -RepoRoot $repoRoot
        $destRoot = Join-Path $repoRoot $TargetMap[$type]

        Get-ChildItem -LiteralPath $srcDir -Force | Where-Object { $_.Name -ne '.gitkeep' } | ForEach-Object {
            $name = $_.BaseName
            if ($_.PSIsContainer) { $name = $_.Name }
            if ($null -ne $allow -and $allow -notcontains $name) { return }

            $dest = Join-Path $destRoot $_.Name
            New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
            if ($_.PSIsContainer) {
                if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
                Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force
            } else {
                Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
            }
            $manifest.files.Add(($TargetMap[$type] + '/' + $_.Name)) | Out-Null
        }
    }

    $manifestDir = Join-Path $repoRoot '.sheen'
    New-Item -ItemType Directory -Force -Path $manifestDir | Out-Null
    $manifestPath = Join-Path $manifestDir 'manifest.json'
    ($manifest | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $manifestPath -Encoding utf8
    Write-Host ("sheen sync: wrote {0} item(s); manifest at .sheen/manifest.json" -f $manifest.files.Count)
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}

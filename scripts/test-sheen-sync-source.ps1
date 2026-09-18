#!/usr/bin/env pwsh
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

function Read-RepoText([string]$RelativePath) {
    return Get-Content -LiteralPath (Join-Path $repoRoot $RelativePath) -Raw
}

function Assert-Contains([string]$Text, [string]$Needle, [string]$Message) {
    if (-not $Text.Contains($Needle)) { throw "ASSERTION FAILED: $Message" }
}

function Assert-NotContains([string]$Text, [string]$Needle, [string]$Message) {
    if ($Text.Contains($Needle)) { throw "ASSERTION FAILED: $Message" }
}

function Assert-Before([string]$Text, [string]$First, [string]$Second, [string]$Message) {
    $firstIndex = $Text.IndexOf($First, [System.StringComparison]::Ordinal)
    $secondIndex = $Text.IndexOf($Second, [System.StringComparison]::Ordinal)
    if ($firstIndex -lt 0 -or $secondIndex -lt 0 -or $firstIndex -gt $secondIndex) { throw "ASSERTION FAILED: $Message" }
}

function Invoke-CheckedGit {
    $output = & git @args 2>&1
    if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') failed with exit $LASTEXITCODE`n$output" }
}

function New-SyncSourceFixture([string]$Root, [string]$Template) {
    $source = Join-Path $Root 'source'
    New-Item -ItemType Directory -Force -Path (Join-Path $source 'templates') | Out-Null
    Set-Content -LiteralPath (Join-Path $source 'templates' 'sheen-sync.yml') -Value $Template -NoNewline
    Invoke-CheckedGit -C $source init -b main
    Invoke-CheckedGit -C $source config user.name test
    Invoke-CheckedGit -C $source config user.email test@example.com
    Invoke-CheckedGit -C $source add templates/sheen-sync.yml
    Invoke-CheckedGit -C $source commit -m init
    return $source
}

function New-SyncConsumerFixture([string]$Root, [string]$OldWorkflow) {
    $consumer = Join-Path $Root 'consumer'
    New-Item -ItemType Directory -Force -Path (Join-Path $consumer '.github' 'workflows') | Out-Null
    Set-Content -LiteralPath (Join-Path $consumer '.github' 'workflows' 'sheen-sync.yml') -Value $OldWorkflow -NoNewline
    Invoke-CheckedGit -C $consumer init -b main
    Invoke-CheckedGit -C $consumer config user.name test
    Invoke-CheckedGit -C $consumer config user.email test@example.com
    Invoke-CheckedGit -C $consumer add .github/workflows/sheen-sync.yml
    Invoke-CheckedGit -C $consumer commit -m init
    return $consumer
}

function Assert-MigratedConsumer([string]$Consumer) {
    $workflow = Get-Content -LiteralPath (Join-Path $Consumer '.github' 'workflows' 'sheen-sync.yml') -Raw
    Assert-Contains $workflow 'uses: IBuySpy-Shared/basecoat-sheen/.github/workflows/check-sheen-version-callable.yml@' 'managed workflow migration must restore the internal callable host'
    Assert-NotContains $workflow 'uses: ivegamsft/sheen/.github/workflows/check-sheen-version-callable.yml@' 'managed workflow migration must remove the public callable host'
    Assert-NotContains $workflow 'source_repo: ivegamsft/sheen' 'managed workflow migration must leave asset source precedence to .sheen.yml'
    $manifest = Get-Content -LiteralPath (Join-Path $Consumer '.sheen' 'manifest.json') -Raw | ConvertFrom-Json
    if (@($manifest.files) -notcontains '.github/workflows/sheen-sync.yml') {
        throw 'ASSERTION FAILED: migrated managed workflow must be recorded in .sheen/manifest.json'
    }
}

function Get-CallableResolverScript([string]$WorkflowText) {
    $match = [regex]::Match(
        $WorkflowText,
        '(?ms)^      - name: Resolve sync configuration.*?^        run: \|\r?\n(?<body>.*?)(?=^      - name: )'
    )
    if (-not $match.Success) { throw 'ASSERTION FAILED: could not find callable resolver run block' }
    $lines = $match.Groups['body'].Value -split "`r?`n"
    $script = ($lines | ForEach-Object {
        if ($_.StartsWith('          ')) { $_.Substring(10) } else { $_ }
    }) -join "`n"
    $script = $script.Replace('${{ inputs.source_repo }}', '${INPUT_SOURCE_REPO:-}')
    $script = $script.Replace('${{ inputs.source_ref }}', '${INPUT_SOURCE_REF:-}')
    $script = $script.Replace('${{ inputs.pr_branch_prefix }}', '${INPUT_PR_BRANCH_PREFIX:-chore/sheen-update}')
    return $script
}

function Invoke-CallableResolverFixture([string]$Root, [string]$ResolverScript, [string]$ConfigText) {
    if ($IsWindows -or -not (Get-Command bash -ErrorAction SilentlyContinue)) {
        Write-Host 'Skipping callable resolver behavior fixture because bash is unavailable or running on Windows.'
        return $null
    }

    $fixture = Join-Path $Root ([Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $fixture | Out-Null
    Set-Content -LiteralPath (Join-Path $fixture '.sheen.yml') -Value $ConfigText -NoNewline
    $scriptPath = Join-Path $fixture 'resolve.sh'
    $outputPath = Join-Path $fixture 'github-output.txt'
    Set-Content -LiteralPath $scriptPath -Value $ResolverScript -NoNewline
    $oldOutput = $env:GITHUB_OUTPUT
    $oldSourceRepo = $env:INPUT_SOURCE_REPO
    $oldSourceRef = $env:INPUT_SOURCE_REF
    $oldBranchPrefix = $env:INPUT_PR_BRANCH_PREFIX
    $oldFetchToken = $env:SHEEN_FETCH_TOKEN
    try {
        $env:GITHUB_OUTPUT = $outputPath
        $env:INPUT_SOURCE_REPO = ''
        $env:INPUT_SOURCE_REF = ''
        $env:INPUT_PR_BRANCH_PREFIX = 'chore/sheen-update'
        $env:SHEEN_FETCH_TOKEN = ''
        Push-Location $fixture
        try { $output = & bash $scriptPath 2>&1 }
        finally { Pop-Location }
        if ($LASTEXITCODE -ne 0) { throw "callable resolver fixture failed with exit $LASTEXITCODE`n$output" }
    }
    finally {
        $env:GITHUB_OUTPUT = $oldOutput
        $env:INPUT_SOURCE_REPO = $oldSourceRepo
        $env:INPUT_SOURCE_REF = $oldSourceRef
        $env:INPUT_PR_BRANCH_PREFIX = $oldBranchPrefix
        $env:SHEEN_FETCH_TOKEN = $oldFetchToken
    }

    $result = @{}
    foreach ($line in Get-Content -LiteralPath $outputPath) {
        $parts = $line.Split('=', 2)
        if ($parts.Count -eq 2) { $result[$parts[0]] = $parts[1] }
    }
    return $result
}

Write-Host '[1/6] standalone sync defaults use the public mirror'
$syncSh = Read-RepoText 'sync.sh'
$syncPs1 = Read-RepoText 'sync.ps1'
Assert-Contains $syncSh 'DEFAULT_SOURCE="https://github.com/ivegamsft/sheen.git"' 'sync.sh must not require private source credentials by default'
Assert-Contains $syncPs1 '$DefaultSource = ''https://github.com/ivegamsft/sheen.git''' 'sync.ps1 must not require private source credentials by default'
Assert-Contains $syncSh "grep -Fq 'This file was synced into your repo by basecoat-sheen.'" 'sync.sh must recognize marker-owned workflows for migration'
Assert-Contains $syncSh 'cmp -s "$UPSTREAM_SYNC_WF" "$SHEEN_SYNC_WF"' 'sync.sh must refresh changed marker-owned workflows from the template'
Assert-Contains $syncPs1 '$existingWorkflow.Contains(''This file was synced into your repo by basecoat-sheen.'')' 'sync.ps1 must recognize marker-owned workflows for migration'
Assert-Contains $syncPs1 '[string]::Equals($existingWorkflow, $upstreamWorkflow, [System.StringComparison]::Ordinal)' 'sync.ps1 must use case-sensitive workflow template comparison'
Assert-Before $syncSh 'SHEEN_SYNC_WF="$REPO_ROOT/.github/workflows/sheen-sync.yml"' 'cat > "$MANIFEST"' 'sync.sh must record managed workflow before manifest serialization'
Assert-Before $syncPs1 '$sheenSyncWorkflow = Join-Path $repoRoot ''.github'' ''workflows'' ''sheen-sync.yml''' '($manifest | ConvertTo-Json -Depth 8)' 'sync.ps1 must record managed workflow before manifest serialization'

Write-Host '[2/6] bootstrap-generated .sheen.yml defaults use the public mirror'
$bootstrapSh = Read-RepoText 'bootstrap.sh'
$bootstrapPs1 = Read-RepoText 'bootstrap.ps1'
Assert-Contains $bootstrapSh 'SOURCE="${SHEEN_SOURCE:-https://github.com/ivegamsft/sheen.git}"' 'bootstrap.sh must generate public mirror source by default'
Assert-Contains $bootstrapPs1 '[string]$Source = ''https://github.com/ivegamsft/sheen.git''' 'bootstrap.ps1 must generate public mirror source by default'
Assert-Contains (Read-RepoText '.sheen.yml.example') 'source: https://github.com/ivegamsft/sheen.git' '.sheen.yml.example must scaffold the public mirror source'
Assert-Contains (Read-RepoText 'docs/getting-started/quick-start.md') 'source: https://github.com/ivegamsft/sheen.git' 'quick-start guide must scaffold the public mirror source'

Write-Host '[3/6] scheduled sync template uses internal callable and .sheen.yml source precedence'
$template = Read-RepoText 'templates/sheen-sync.yml'
Assert-Contains $template 'uses: IBuySpy-Shared/basecoat-sheen/.github/workflows/check-sheen-version-callable.yml@' 'scheduled sync must keep using the internal callable workflow host'
Assert-NotContains $template 'source_repo: ivegamsft/sheen' 'scheduled sync template must not override .sheen.yml source'
Assert-NotContains $template 'source_repo: IBuySpy-Shared/basecoat-sheen' 'scheduled sync template must not clone the private source by default'
Assert-Contains $template 'Not required for the default public ivegamsft/sheen mirror.' 'template must document that fetch_token is optional for the default source'

Write-Host '[4/6] callable workflow falls back from private source to public mirror when no fetch token is provided'
$callable = Read-RepoText '.github/workflows/check-sheen-version-callable.yml'
Assert-Contains $callable 'default: ""' 'callable source/ref inputs must be empty so .sheen.yml can fill them'
Assert-Contains $callable 'SOURCE="${SOURCE:-ivegamsft/sheen}"' 'callable source_repo default must be public after .sheen.yml is evaluated'
Assert-Contains $callable 'REF="${REF:-main}"' 'callable source_ref default must be main after .sheen.yml is evaluated'
Assert-Contains $callable 'SHEEN_FETCH_TOKEN: ${{ secrets.fetch_token }}' 'callable must evaluate fetch token availability without logging token values'
Assert-Contains $callable 'NORMALIZED_SOURCE="${SOURCE#https://github.com/}"' 'callable must normalize URL-style .sheen.yml source values'
Assert-Contains $callable 'NORMALIZED_SOURCE_LOWER="$(printf ''%s'' "$NORMALIZED_SOURCE" | tr ''[:upper:]'' ''[:lower:]'')"' 'callable must compare GitHub owner/repo case-insensitively'
Assert-Contains $callable 'if [[ "$NORMALIZED_SOURCE_LOWER" == "ibuyspy-shared/basecoat-sheen" && -z "${SHEEN_FETCH_TOKEN:-}" ]]; then' 'callable must detect private source without fetch token'
Assert-Contains $callable 'SOURCE="ivegamsft/sheen"' 'callable must fall back to public mirror for private source without fetch token'
Assert-Contains $callable 'echo "source_url=$SOURCE_URL" >> "$GITHUB_OUTPUT"' 'callable must emit a clone-ready source URL'
Assert-Contains $callable 'SHEEN_REPO: "${{ steps.config.outputs.source_url }}"' 'sync step must use the resolved clone URL directly'
Assert-Contains $callable 'if [[ -n "${SHEEN_FETCH_TOKEN}" && "$SHEEN_REPO" == https://github.com/* ]]; then' 'sync step must only inject tokens into GitHub clone URLs'
Assert-Contains $callable 'Using public Sheen mirror' 'callable must emit an actionable fallback notice'
Assert-Contains $callable 'Missing Sheen fetch token' 'callable must warn when a non-default source has no fetch token'

Write-Host '[5/6] production publication preserves the internal callable workflow host'
$publish = Read-RepoText '.github/workflows/publish-to-production.yml'
Assert-Contains $publish 'templates/sheen-sync.yml' 'publish workflow must explicitly handle the generated sync template'
Assert-Contains $publish 'uses: IBuySpy-Shared/basecoat-sheen/.github/workflows/check-sheen-version-callable.yml@' 'publish workflow must restore the internal callable host after public mirror sanitization'
Assert-Contains $publish 'grep -v ''^templates/sheen-sync.yml:.*uses: IBuySpy-Shared/basecoat-sheen/.github/workflows/check-sheen-version-callable.yml@''' 'publish safety gate must allow-list only the generated callable host'
$publicTemplate = $template -replace 'IBuySpy-Shared/basecoat-sheen', 'ivegamsft/sheen'
$publicTemplate = [regex]::Replace($publicTemplate, 'uses:\s+ivegamsft/sheen/\.github/workflows/check-sheen-version-callable\.yml@', 'uses: IBuySpy-Shared/basecoat-sheen/.github/workflows/check-sheen-version-callable.yml@')
Assert-Contains $publicTemplate 'uses: IBuySpy-Shared/basecoat-sheen/.github/workflows/check-sheen-version-callable.yml@' 'sanitized public template must still call the internal reusable workflow'
$forbidden = @()
$publicLines = $publicTemplate -split "`r?`n"
for ($i = 0; $i -lt $publicLines.Count; $i++) {
    if ($publicLines[$i] -match 'IBuySpy-Shared|ibuyspy-shared\.github\.io' -and
        $publicLines[$i] -notmatch 'uses:\s+IBuySpy-Shared/basecoat-sheen/\.github/workflows/check-sheen-version-callable\.yml@') {
        $forbidden += "templates/sheen-sync.yml:$($i + 1):$($publicLines[$i])"
    }
}
if ($forbidden.Count -gt 0) { throw "ASSERTION FAILED: sanitized public template leaves unexpected internal owner references: $($forbidden -join '; ')" }

Write-Host '[6/6] marker-owned public-host workflows are migrated and recorded'
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("sheen-sync-source-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $scratch | Out-Null
try {
    $source = New-SyncSourceFixture -Root $scratch -Template $template
    $oldWorkflow = $template.Replace(
        'uses: IBuySpy-Shared/basecoat-sheen/.github/workflows/check-sheen-version-callable.yml@',
        'uses: ivegamsft/sheen/.github/workflows/check-sheen-version-callable.yml@'
    )

    $consumerPs = New-SyncConsumerFixture -Root (Join-Path $scratch 'ps') -OldWorkflow $oldWorkflow
    $oldRepo = $env:SHEEN_REPO
    $oldRef = $env:SHEEN_REF
    try {
        $env:SHEEN_REPO = $source
        $env:SHEEN_REF = 'main'
        Push-Location $consumerPs
        try { & (Join-Path $repoRoot 'sync.ps1') }
        finally { Pop-Location }
    }
    finally {
        $env:SHEEN_REPO = $oldRepo
        $env:SHEEN_REF = $oldRef
    }
    Assert-MigratedConsumer -Consumer $consumerPs

    if (-not $IsWindows -and (Get-Command bash -ErrorAction SilentlyContinue)) {
        $consumerSh = New-SyncConsumerFixture -Root (Join-Path $scratch 'sh') -OldWorkflow $oldWorkflow
        $oldRepo = $env:SHEEN_REPO
        $oldRef = $env:SHEEN_REF
        $env:SHEEN_REPO = $source
        $env:SHEEN_REF = 'main'
        Push-Location $consumerSh
        try {
            & bash (Join-Path $repoRoot 'sync.sh')
            if ($LASTEXITCODE -ne 0) { throw "sync.sh fixture failed with exit $LASTEXITCODE" }
        }
        finally {
            Pop-Location
            $env:SHEEN_REPO = $oldRepo
            $env:SHEEN_REF = $oldRef
        }
        Assert-MigratedConsumer -Consumer $consumerSh
    }

    $resolverScript = Get-CallableResolverScript -WorkflowText $callable
    $nonGitHub = Invoke-CallableResolverFixture -Root $scratch -ResolverScript $resolverScript -ConfigText @'
source: https://git.example.internal/platform/sheen.git
ref: v9.9.9
'@
    if ($null -ne $nonGitHub) {
        if ($nonGitHub['source_url'] -ne 'https://git.example.internal/platform/sheen.git') {
            throw "ASSERTION FAILED: non-GitHub source_url must not be wrapped in github.com; got '$($nonGitHub['source_url'])'"
        }
        if ($nonGitHub['ref'] -ne 'v9.9.9') {
            throw "ASSERTION FAILED: .sheen.yml ref must win before default; got '$($nonGitHub['ref'])'"
        }
    }

    $privateDefault = Invoke-CallableResolverFixture -Root $scratch -ResolverScript $resolverScript -ConfigText @'
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: main
'@
    if ($null -ne $privateDefault) {
        if ($privateDefault['source'] -ne 'ivegamsft/sheen') {
            throw "ASSERTION FAILED: canonical private source without token must fall back to public source; got '$($privateDefault['source'])'"
        }
        if ($privateDefault['source_url'] -ne 'https://github.com/ivegamsft/sheen.git') {
            throw "ASSERTION FAILED: canonical private source fallback must emit public source_url; got '$($privateDefault['source_url'])'"
        }
    }

    $privateLowercase = Invoke-CallableResolverFixture -Root $scratch -ResolverScript $resolverScript -ConfigText @'
source: https://github.com/ibuyspy-shared/basecoat-sheen.git
ref: main
'@
    if ($null -ne $privateLowercase -and $privateLowercase['source'] -ne 'ivegamsft/sheen') {
        throw "ASSERTION FAILED: canonical private fallback must be case-insensitive; got '$($privateLowercase['source'])'"
    }
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'Sheen sync source/token fallback contract passed.'

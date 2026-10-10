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
    Set-Content -LiteralPath (Join-Path $consumer '.sheen.yml') -Value 'install_sync_workflow: true'
    Invoke-CheckedGit -C $consumer init -b main
    Invoke-CheckedGit -C $consumer config user.name test
    Invoke-CheckedGit -C $consumer config user.email test@example.com
    Invoke-CheckedGit -C $consumer add .github/workflows/sheen-sync.yml
    Invoke-CheckedGit -C $consumer commit -m init
    return $consumer
}

function Assert-MigratedConsumer([string]$Consumer) {
    $workflow = Get-Content -LiteralPath (Join-Path $Consumer '.github' 'workflows' 'sheen-sync.yml') -Raw
    Assert-Contains $workflow 'uses: IBuySpy-Shared/basecoat-sheen/.github/actions/sync-assets@' 'managed workflow migration must install the internal shared action'
    Assert-Contains $workflow 'uses: IBuySpy-Shared/basecoat-sheen/.github/actions/discover-release@' 'managed workflow migration must install pinned release discovery'
    $workflowPin = [regex]::Match($workflow, '(?m)^\s+uses:\s+IBuySpy-Shared/basecoat-sheen/\.github/actions/sync-assets@(?<sha>[0-9a-f]{40})\s*$')
    if (-not $workflowPin.Success) { throw 'ASSERTION FAILED: generated workflow must pin the shared action to an immutable 40-character commit SHA' }
    Assert-NotContains $workflow 'uses: ivegamsft/sheen/.github/actions/sync-assets@' 'managed workflow migration must preserve the configured public action owner'
    Assert-NotContains $workflow 'source_repo: ivegamsft/sheen' 'managed workflow migration must leave asset source precedence to .sheen.yml'
    $manifest = Get-Content -LiteralPath (Join-Path $Consumer '.sheen' 'manifest.json') -Raw | ConvertFrom-Json
    if ($workflowPin.Groups['sha'].Value -ne $manifest.commit) {
        throw "ASSERTION FAILED: generated action commit pin must match source metadata; workflow='$($workflowPin.Groups['sha'].Value)' manifest='$($manifest.commit)'"
    }
    Assert-Contains $workflow "source_commit: $($manifest.commit)" 'generated action input must use the same immutable source commit'
    if (@($manifest.files) -notcontains '.github/workflows/sheen-sync.yml') {
        throw 'ASSERTION FAILED: migrated managed workflow must be recorded in .sheen/manifest.json'
    }
}

function Assert-RepeatSyncNoOp {
    param(
        [Parameter(Mandatory)][string]$Consumer,
        [Parameter(Mandatory)][scriptblock]$Sync
    )
    & $Sync
    Invoke-CheckedGit -C $Consumer add -A
    Invoke-CheckedGit -C $Consumer commit -m 'commit sync pass one'
    $manifestPath = Join-Path $Consumer '.sheen' 'manifest.json'
    [byte[]]$passOneManifest = [System.IO.File]::ReadAllBytes($manifestPath)

    Start-Sleep -Milliseconds 1100
    & $Sync

    [byte[]]$passTwoManifest = [System.IO.File]::ReadAllBytes($manifestPath)
    if ($passOneManifest.Length -ne $passTwoManifest.Length -or
        -not [System.Linq.Enumerable]::SequenceEqual[byte]($passOneManifest, $passTwoManifest)) {
        throw 'ASSERTION FAILED: repeated exact-tag sync must preserve .sheen/manifest.json byte-for-byte'
    }
    $status = & git -C $Consumer status --porcelain=v1
    if ($LASTEXITCODE -ne 0) { throw 'ASSERTION FAILED: git status failed after repeated exact-tag sync' }
    if ($status) { throw "ASSERTION FAILED: repeated exact-tag sync must leave zero git status; got: $($status -join '; ')" }
    & git -C $Consumer diff --quiet
    if ($LASTEXITCODE -ne 0) { throw 'ASSERTION FAILED: repeated exact-tag sync must leave zero unstaged diff' }
    & git -C $Consumer diff --cached --quiet
    if ($LASTEXITCODE -ne 0) { throw 'ASSERTION FAILED: repeated exact-tag sync must leave zero staged diff' }
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

function Invoke-CallableResolverFailureFixture([string]$Root, [string]$ResolverScript, [string]$ConfigText) {
    if ($IsWindows -or -not (Get-Command bash -ErrorAction SilentlyContinue)) {
        Write-Host 'Skipping callable resolver failure fixture because bash is unavailable or running on Windows.'
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
        return @{ exitCode = $LASTEXITCODE; output = ($output -join "`n") }
    }
    finally {
        $env:GITHUB_OUTPUT = $oldOutput
        $env:INPUT_SOURCE_REPO = $oldSourceRepo
        $env:INPUT_SOURCE_REF = $oldSourceRef
        $env:INPUT_PR_BRANCH_PREFIX = $oldBranchPrefix
        $env:SHEEN_FETCH_TOKEN = $oldFetchToken
    }
}

Write-Host '[1/7] standalone sync defaults use the public mirror'
$syncSh = Read-RepoText 'sync.sh'
$syncPs1 = Read-RepoText 'sync.ps1'
Assert-Contains $syncSh 'DEFAULT_SOURCE="https://github.com/ivegamsft/sheen.git"' 'sync.sh must not require private source credentials by default'
Assert-Contains $syncPs1 '$DefaultSource = ''https://github.com/ivegamsft/sheen.git''' 'sync.ps1 must not require private source credentials by default'
Assert-Contains $syncSh "grep -Fq 'This file was synced into your repo by basecoat-sheen.'" 'sync.sh must recognize marker-owned workflows for migration'
Assert-Contains $syncSh 'cmp -s "$NORMALIZED_SYNC_WF" "$SHEEN_SYNC_WF"' 'sync.sh must refresh changed marker-owned workflows from the normalized template'
Assert-Contains $syncPs1 '$existingWorkflow.Contains(''This file was synced into your repo by basecoat-sheen.'')' 'sync.ps1 must recognize marker-owned workflows for migration'
Assert-Contains $syncPs1 '[string]::Equals($existingWorkflow, $normalizedWorkflow, [System.StringComparison]::Ordinal)' 'sync.ps1 must use case-sensitive normalized workflow template comparison'
Assert-Contains $syncPs1 'SHEEN_SYNC_TEMP_ROOT' 'sync.ps1 must allow an explicit short Windows staging root'
Assert-Contains $syncPs1 'Join-Path $env:SystemDrive ''_sheen-sync''' 'sync.ps1 must default to a short Windows staging root'
Assert-Contains $syncPs1 'core.longpaths=true' 'sync.ps1 must enable Git long-path checkout for its clone'
Assert-Contains $syncPs1 'clone did not create a complete Git checkout' 'sync.ps1 must report an actionable incomplete-clone error'
Assert-Contains $syncSh 'core.longpaths=true' 'sync.sh must enable Git long-path checkout for its clone'
Assert-Contains $syncSh '__SHEEN_COMMIT_SHA__' 'sync.sh must substitute the resolved source commit into generated workflow pins'
Assert-Contains $syncSh 'SHEEN_SOURCE_PATH and SHEEN_SOURCE_COMMIT must be provided together' 'sync.sh must validate paired action archive inputs'
Assert-Contains $syncSh 'SHEEN_SOURCE_COMMIT must be a full 40-character commit SHA' 'sync.sh must validate the action source hash'
Assert-Contains $syncSh 'using staged local payload at immutable source commit' 'sync.sh must use the local pinned payload without cloning'
Assert-Contains $syncSh 'Cannot verify legacy agent ownership for $rel from an action archive without Git history' 'sync.sh must retain legacy agent provenance checks'
Assert-Contains $syncSh 'source_commit:[[:space:]]*' 'sync.sh must render the action input commit from the same source SHA'
Assert-Contains $syncPs1 'SHEEN_SOURCE_PATH and SHEEN_SOURCE_COMMIT must be provided together' 'sync.ps1 must validate paired action archive inputs'
Assert-Contains $syncPs1 'SHEEN_SOURCE_COMMIT must be a full 40-character commit SHA' 'sync.ps1 must validate the action source hash'
Assert-Contains $syncPs1 'using staged local payload at immutable source commit' 'sync.ps1 must use the local pinned payload without cloning'
Assert-Contains $syncPs1 'Cannot verify legacy agent ownership for $relative from an action archive without Git history' 'sync.ps1 must retain legacy agent provenance checks'
Assert-Contains $syncPs1 'source_commit:[ \t]*' 'sync.ps1 must render the action input commit from the same source SHA'
Assert-Before $syncSh 'SHEEN_SYNC_WF="$REPO_ROOT/.github/workflows/sheen-sync.yml"' 'cat > "$CANDIDATE_MANIFEST"' 'sync.sh must record managed workflow before manifest serialization'
Assert-Before $syncPs1 '$sheenSyncWorkflow = Join-Path $repoRoot ''.github'' ''workflows'' ''sheen-sync.yml''' '($manifest | ConvertTo-Json -Depth 8)' 'sync.ps1 must record managed workflow before manifest serialization'

Write-Host '[2/7] bootstrap-generated .sheen.yml defaults use the public mirror'
$bootstrapSh = Read-RepoText 'bootstrap.sh'
$bootstrapPs1 = Read-RepoText 'bootstrap.ps1'
Assert-Contains $bootstrapSh 'SOURCE="${SHEEN_SOURCE:-https://github.com/ivegamsft/sheen.git}"' 'bootstrap.sh must generate public mirror source by default'
Assert-Contains $bootstrapPs1 '[string]$Source = ''https://github.com/ivegamsft/sheen.git''' 'bootstrap.ps1 must generate public mirror source by default'
foreach ($bootstrap in @($bootstrapSh, $bootstrapPs1)) {
    Assert-Contains $bootstrap 'centrally managed organization SHEEN_FETCH_TOKEN; no per-repo setup.' 'bootstrap must explain inherited organization access'
    Assert-Contains $bootstrap 'Never provision a consumer secret.' 'bootstrap must not ask consumers to provision a secret'
    Assert-NotContains $bootstrap 'gh secret set' 'bootstrap must not provision repository secrets'
    Assert-NotContains $bootstrap 'Read-Host' 'bootstrap must not prompt for credentials'
    Assert-NotContains $bootstrap 'read -' 'bootstrap must not prompt for credentials'
}
Assert-Contains (Read-RepoText '.sheen.yml.example') 'source: https://github.com/ivegamsft/sheen.git' '.sheen.yml.example must scaffold the public mirror source'
Assert-Contains (Read-RepoText 'docs/getting-started/quick-start.md') 'source: https://github.com/ivegamsft/sheen.git' 'quick-start guide must scaffold the public mirror source'
foreach ($example in Get-ChildItem -LiteralPath (Join-Path $repoRoot 'docs' 'examples') -Force -File -Filter '.sheen.yml*') {
    $exampleText = Get-Content -LiteralPath $example.FullName -Raw
    Assert-NotContains $exampleText 'IBuySpy-Shared/basecoat-sheen' "copyable example $($example.Name) must not default to the private source"
    Assert-NotContains $exampleText 'ref: v0.5.0' "copyable example $($example.Name) must not pin a nonexistent public mirror tag"
}

Write-Host '[3/7] scheduled sync template pins the token-free shared action'
$template = Read-RepoText 'templates/sheen-sync.yml'
Assert-Contains $template 'uses: IBuySpy-Shared/basecoat-sheen/.github/actions/sync-assets@' 'scheduled sync must run the internal shared action by default'
Assert-Contains $template 'uses: IBuySpy-Shared/basecoat-sheen/.github/actions/discover-release@' 'scheduled sync must pin release discovery to the current source'
Assert-Contains $template 'source_commit: v1.3.0' 'released template must use a non-circular source commit placeholder'
Assert-Contains $template 'desired_tag: ${{ inputs.source_ref || '''' }}' 'manual ref must be a release-discovery request only'
Assert-Contains $template 'Assets apply on a later workflow run' 'discovery must not apply its selected release in the same run'
Assert-Contains $template 'secrets.SHEEN_UPDATE_TOKEN || github.token' 'workflow must preserve the update-token fallback'
Assert-Contains $template 'SHEEN_FETCH_TOKEN' 'internal compatibility guidance must explain centrally managed fetch access'
Assert-Contains $template 'centrally managed organization' 'internal compatibility guidance must not request consumer credentials'
Assert-NotContains $template 'fetch_token:' 'default shared action workflow must not pass a fetch token'
$pinJobStart = $template.IndexOf('  discover-release:')
$assetJobStart = $template.IndexOf('  sync-assets:')
if ($pinJobStart -lt 0 -or $assetJobStart -le $pinJobStart) { throw 'ASSERTION FAILED: expected separate release-pin and asset-sync jobs' }
$pinJob = $template.Substring($pinJobStart, $assetJobStart - $pinJobStart)
Assert-NotContains $pinJob 'AUTO_MERGE' 'asset-sync auto_merge consent must not merge executable action pin changes'
$assetJob = $template.Substring($assetJobStart)
Assert-Contains $assetJob 'title == "chore(sheen): sync pinned assets"' 'asset sync must recognize existing managed open PRs'
Assert-Contains $assetJob 'if [[ -n "$open_pr" ]]' 'asset sync must stop before duplicating an open PR'
Assert-Before $assetJob 'if [[ -n "$open_pr" ]]' 'branch="chore/sheen-assets-' 'asset PR deduplication must precede branch creation'

Write-Host '[4/7] callable workflow preflights private access and isolates Sheen from a root sync.sh collision'
$callable = Read-RepoText '.github/workflows/check-sheen-version-callable.yml'
Assert-Contains $callable 'default: ""' 'callable source/ref inputs must be empty so .sheen.yml can fill them'
Assert-Contains $callable 'SOURCE="${SOURCE:-ivegamsft/sheen}"' 'callable source_repo default must be public after .sheen.yml is evaluated'
Assert-Contains $callable 'REF="${REF:-main}"' 'callable source_ref default must be main after .sheen.yml is evaluated'
Assert-Contains $callable 'SHEEN_FETCH_TOKEN: ${{ secrets.fetch_token }}' 'callable must evaluate fetch token availability without logging token values'
Assert-Contains $callable 'sed ''s/[[:space:]]#.*$//''' 'callable must strip valid YAML trailing comments from source/ref values'
Assert-Contains $callable 'sed -E ''s#^[Hh][Tt][Tt][Pp][Ss]://[Gg][Ii][Tt][Hh][Uu][Bb][.][Cc][Oo][Mm]/##; s#[.][Gg][Ii][Tt]$##''' 'callable must normalize GitHub URLs and .git suffix case-insensitively'
Assert-Contains $callable 'NORMALIZED_SOURCE_LOWER="$(printf ''%s'' "$NORMALIZED_SOURCE" | tr ''[:upper:]'' ''[:lower:]'')"' 'callable must compare GitHub owner/repo case-insensitively'
Assert-Contains $callable 'if [[ "$NORMALIZED_SOURCE_LOWER" == "ibuyspy-shared/basecoat-sheen" && -z "${SHEEN_FETCH_TOKEN:-}" ]]; then' 'callable must detect private source without fetch token'
Assert-Contains $callable 'The consumer repo GITHUB_TOKEN cannot clone another repository.' 'callable must explain why GITHUB_TOKEN cannot fetch the internal source'
Assert-Contains $callable 'inherit the centrally managed organization SHEEN_FETCH_TOKEN' 'callable must explain inherited fetch access'
Assert-Contains $callable 'Do not create a repository secret or provision your own credential.' 'callable must prohibit consumer provisioning'
Assert-Contains $callable 'File an issue in https://github.com/IBuySpy-Shared/basecoat-sheen/issues' 'callable must direct missing access to source maintainers'
Assert-NotContains $callable 'Configure a repository or organization secret named SHEEN_FETCH_TOKEN' 'callable must not prescribe consumer secret setup'
Assert-Contains $callable 'change .sheen.yml source to the public mirror https://github.com/ivegamsft/sheen.git' 'callable must offer the public mirror alternative'
Assert-Contains $callable 'echo "source_url=$SOURCE_URL" >> "$GITHUB_OUTPUT"' 'callable must emit a clone-ready source URL'
Assert-Contains $callable 'SHEEN_REPO: "${{ steps.config.outputs.source_url }}"' 'sync step must use the resolved clone URL directly'
Assert-Contains $callable 'git -c core.longpaths=true clone --no-checkout -- "$CLONE_URL" "$SOURCE_PATH"' 'callable must stage source before invoking the sync engine'
Assert-Contains $callable 'git -C "$SOURCE_PATH" checkout --detach "$SHEEN_REF"' 'callable must check out the exact resolved Sheen source ref'
Assert-Contains $callable 'source_commit=$SOURCE_COMMIT' 'callable must expose the resolved immutable source commit'
Assert-Contains $callable 'SHEEN_REF: "${{ steps.source.outputs.source_commit }}"' 'callable asset sync must use the staged script commit'
Assert-Contains $callable 'SHEEN_SOURCE_COMMIT: "${{ steps.source.outputs.source_commit }}"' 'callable must pass the staged commit with its local source path'
Assert-Contains $callable 'bash "$SHEEN_SOURCE_PATH/sync.sh"' 'callable must invoke sync.sh from the staged Sheen source path'
Assert-NotContains $callable 'bash sync.sh' 'callable must never dispatch through the consumer-owned BaseCoat root sync.sh'
Assert-NotContains $callable 'raw.githubusercontent.com/ivegamsft/sheen/main/sync.sh' 'callable must not drift to the public main sync.sh'
Assert-Contains $callable 'if [[ -n "${SHEEN_FETCH_TOKEN}" && "$SHEEN_REPO" == https://github.com/* ]]; then' 'sync step must only inject tokens into GitHub clone URLs'
Assert-Contains $callable 'Missing Sheen fetch token' 'callable must warn when a non-default source has no fetch token'
Assert-Contains $callable 'Non-GitHub Sheen source authentication' 'callable must give host-auth guidance for non-GitHub sources'

$generator = Read-RepoText '.github/workflows/generate-design-md-callable.yml'
Assert-Contains $generator 'FETCH_TOKEN: ${{ secrets.token || github.token }}' 'generator must preserve the existing credential path'
Assert-Contains $generator 'Missing Sheen fetch token' 'generator must explain missing source access'
Assert-Contains $generator 'https://github.com/IBuySpy-Shared/basecoat-sheen/issues for maintainers to' 'generator must route source-access changes to maintainers'
Assert-Contains $generator 'resolve central access or workflow wiring. Do not create a repository secret' 'generator must not prescribe consumer secret setup'
Assert-Contains $generator 'public ivegamsft/sheen mirror needs no fetch token.' 'generator must document no-token public source'
Assert-NotContains $generator 'must supply `secrets.token` with read access' 'generator must not ask consumers to provision source credentials'

$guide = Read-RepoText 'docs/guides/upgrading-sheen.md'
Assert-Contains $guide 'Contents: Read only' 'guide must document read-only source scope'
Assert-Contains $guide 'organization secret administrators own' 'guide must name role-based central ownership'
Assert-Contains $guide 'revokes the previous credential' 'guide must document rotation completion'
Assert-Contains $guide 'they do not edit' 'guide must prohibit managed-content edits in consumers'
Assert-Contains $guide 'regardless of consumer organization.' 'guide must preserve public access for outside consumers'
foreach ($guidance in @((Read-RepoText 'README.md'), (Read-RepoText '.sheen.yml.example'))) {
    Assert-Contains $guidance 'centrally managed' 'entry guidance must describe central fetch ownership'
    Assert-Contains $guidance 'Contents: Read only' 'entry guidance must describe least-privilege fetch scope'
}

Write-Host '[5/7] production publication preserves and rewrites the shared action'
$publish = Read-RepoText '.github/workflows/publish-to-production.yml'
Assert-Contains $publish '''.github/workflows/check-sheen-version-callable.yml''' 'publish workflow must keep the consumer-facing callable workflow in the public mirror'
Assert-NotContains $publish 'uses: IBuySpy-Shared/basecoat-sheen/.github/workflows/check-sheen-version-callable.yml@' 'publish workflow must not restore the internal callable host after public mirror sanitization'
Assert-NotContains $publish 'grep -v ''^templates/sheen-sync.yml:.*uses: IBuySpy-Shared/basecoat-sheen/.github/workflows/check-sheen-version-callable.yml@''' 'publish safety gate must not allow-list the generated template to keep internal owner references'
Assert-Contains $publish '''scripts/test-sheen-sync-source.ps1''' 'publish workflow must strip source-only internal sync source tests from the public mirror'
Assert-Contains $publish '''.github/actions/sync-assets/action.yml''' 'publish workflow must preserve the public sync action'
Assert-Contains $publish '''.github/actions/discover-release/action.yml''' 'publish workflow must preserve the public discovery action'
Assert-Contains $publish '''scripts/discover-sheen-release.py''' 'publish workflow must preserve the action runtime resolver'
Assert-Contains $publish 'release-provenance.json' 'publish workflow must provide source commit provenance for internal action pins'
Assert-Before $publish 'python scripts/prepare-public-guidance.py --root .' '- name: Remove internal-only content before publish' 'publisher must strip internal guidance before removal and global rewrites'
Assert-Contains $publish '''scripts/prepare-public-guidance.py''' 'publisher must remove its source-only preparation helper'
& python (Join-Path $repoRoot 'scripts' 'test-public-guidance.py')
if ($LASTEXITCODE -ne 0) { throw "public guidance regression failed with exit $LASTEXITCODE" }

Write-Host '[6/7] marker-owned public-host workflows are migrated and recorded'
$scratch = Join-Path $repoRoot (".sheen-sync-source-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $scratch | Out-Null
try {
    $oldWorkflow = @'
# This file was synced into your repo by basecoat-sheen.
# Do not edit directly — changes will be overwritten on the next sync.
name: Sheen - Sync Assets
on:
  schedule:
    - cron: "0 9 * * 1"
jobs:
  sync:
    uses: ivegamsft/sheen/.github/workflows/check-sheen-version-callable.yml@v0.13.2
    with:
      source_repo: ivegamsft/sheen
'@
    $source = New-SyncSourceFixture -Root $scratch -Template $template
    Invoke-CheckedGit -C $source tag v0.13.2

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

    Write-Host '[7/7] repeated exact-tag sync preserves manifest bytes and leaves zero diff'
    $noOpConsumerPs = New-SyncConsumerFixture -Root (Join-Path $scratch 'noop-ps') -OldWorkflow $oldWorkflow
    $runPowerShellSync = {
        $oldRepo = $env:SHEEN_REPO
        $oldRef = $env:SHEEN_REF
        try {
            $env:SHEEN_REPO = $source
            $env:SHEEN_REF = 'v0.13.2'
            Push-Location $noOpConsumerPs
            try { & (Join-Path $repoRoot 'sync.ps1') }
            finally { Pop-Location }
        }
        finally {
            $env:SHEEN_REPO = $oldRepo
            $env:SHEEN_REF = $oldRef
        }
    }
    Assert-RepeatSyncNoOp -Consumer $noOpConsumerPs -Sync $runPowerShellSync

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

        $noOpConsumerSh = New-SyncConsumerFixture -Root (Join-Path $scratch 'noop-sh') -OldWorkflow $oldWorkflow
        $runShellSync = {
            $oldRepo = $env:SHEEN_REPO
            $oldRef = $env:SHEEN_REF
            try {
                $env:SHEEN_REPO = $source
                $env:SHEEN_REF = 'v0.13.2'
                Push-Location $noOpConsumerSh
                try {
                    & bash (Join-Path $repoRoot 'sync.sh')
                    if ($LASTEXITCODE -ne 0) { throw "sync.sh no-op fixture failed with exit $LASTEXITCODE" }
                }
                finally { Pop-Location }
            }
            finally {
                $env:SHEEN_REPO = $oldRepo
                $env:SHEEN_REF = $oldRef
            }
        }
        Assert-RepeatSyncNoOp -Consumer $noOpConsumerSh -Sync $runShellSync
    }

    $resolverScript = Get-CallableResolverScript -WorkflowText $callable
    $nonGitHub = Invoke-CallableResolverFixture -Root $scratch -ResolverScript $resolverScript -ConfigText @'
source: https://git.example.internal/platform/sheen.git  # or internal mirror
ref: v9.9.9  # pinned
'@
    if ($null -ne $nonGitHub) {
        if ($nonGitHub['source_url'] -ne 'https://git.example.internal/platform/sheen.git') {
            throw "ASSERTION FAILED: non-GitHub source_url must not be wrapped in github.com; got '$($nonGitHub['source_url'])'"
        }
        if ($nonGitHub['ref'] -ne 'v9.9.9') {
            throw "ASSERTION FAILED: .sheen.yml ref must win before default; got '$($nonGitHub['ref'])'"
        }
    }

    $privateDefault = Invoke-CallableResolverFailureFixture -Root $scratch -ResolverScript $resolverScript -ConfigText @'
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: main
'@
    if ($null -ne $privateDefault) {
        if ($privateDefault['exitCode'] -eq 0) {
            throw "ASSERTION FAILED: canonical private source without token must fail preflight"
        }
        if (-not $privateDefault['output'].Contains('Missing Sheen fetch token')) {
            throw "ASSERTION FAILED: canonical private source failure must name Missing Sheen fetch token; got '$($privateDefault['output'])'"
        }
        if (-not $privateDefault['output'].Contains('GITHUB_TOKEN cannot clone another repository')) {
            throw "ASSERTION FAILED: canonical private source failure must explain GITHUB_TOKEN scope; got '$($privateDefault['output'])'"
        }
    }

    $privateLowercase = Invoke-CallableResolverFailureFixture -Root $scratch -ResolverScript $resolverScript -ConfigText @'
source: https://GitHub.com/ibuyspy-shared/basecoat-sheen.Git
ref: main
'@
    if ($null -ne $privateLowercase -and $privateLowercase['exitCode'] -eq 0) {
        throw 'ASSERTION FAILED: canonical private token preflight must be case-insensitive'
    }
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'Sheen sync source/token preflight contract passed.'

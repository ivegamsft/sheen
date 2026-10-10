#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$scratch = Join-Path $repoRoot 'dist' ("sheen-action-sync-" + [guid]::NewGuid().ToString('N'))
$source = Join-Path $scratch 'source'
$archive = Join-Path $scratch 'action-archive'
$consumerPs = Join-Path $scratch 'consumer-ps'
$consumerSh = Join-Path $scratch 'consumer-sh'
$consumerPublic = Join-Path $scratch 'consumer-public'
$legacyConsumer = Join-Path $scratch 'consumer-legacy'
$legacyCloneConsumer = Join-Path $scratch 'consumer-legacy-clone'
$unmanagedConsumer = Join-Path $scratch 'consumer-unmanaged'
$syncRoot = Join-Path $repoRoot 'sync.ps1'
$basecoatSyncContent = "# basecoat-owned root sync`nWrite-Output 'BaseCoat sync must not run during Sheen sync'"
$legacyAgentContent = 'Legacy agent source owned by the pinned Sheen commit'

function Invoke-CheckedGit {
    $output = & git @args 2>&1
    if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') failed with exit $LASTEXITCODE`n$output" }
}

function Invoke-PowerShellSync([string]$Consumer, [string]$Payload, [string]$Commit) {
    $env:SHEEN_SOURCE_PATH = $Payload
    $env:SHEEN_SOURCE_COMMIT = $Commit
    $env:SHEEN_REPO = 'https://github.com/IBuySpy-Shared/basecoat-sheen.git'
    $env:SHEEN_REF = $Commit
    $env:SHEEN_SYNC_TEMP_ROOT = Join-Path $Consumer '.git\sheen-sync-staging'
    Push-Location $Consumer
    try { & $syncRoot }
    finally { Pop-Location }
}

function New-Consumer([string]$Path, [string]$Workflow = '') {
    New-Item -ItemType Directory -Force -Path (Join-Path $Path '.github\workflows') | Out-Null
    Set-Content -LiteralPath (Join-Path $Path '.sheen.yml') -Value @'
install_sync_workflow: true
'@ -NoNewline
    Set-Content -LiteralPath (Join-Path $Path '.basecoat.yml') -Value "source: IBuySpy-Shared/basecoat`n" -NoNewline
    Set-Content -LiteralPath (Join-Path $Path 'sync.sh') -Value $basecoatSyncContent -NoNewline
    if ($Workflow) {
        Set-Content -LiteralPath (Join-Path $Path '.github\workflows\sheen-sync.yml') -Value $Workflow -NoNewline
    }
    Invoke-CheckedGit -C $Path init -b main
    Invoke-CheckedGit -C $Path config user.name test
    Invoke-CheckedGit -C $Path config user.email test@example.com
    Invoke-CheckedGit -C $Path add -A
    Invoke-CheckedGit -C $Path commit -m init
}

function Assert-BasecoatSyncPreserved([string]$Consumer) {
    $actual = Get-Content -LiteralPath (Join-Path $Consumer 'sync.sh') -Raw
    if ($actual -cne $basecoatSyncContent) {
        throw 'Sheen sync altered the consumer-owned BaseCoat root sync.sh'
    }
}

function Add-LegacyAgent([string]$Consumer, [string]$Commit) {
    New-Item -ItemType Directory -Force -Path (Join-Path $Consumer '.github\agents'), (Join-Path $Consumer '.sheen') | Out-Null
    Set-Content -LiteralPath (Join-Path $Consumer '.github\agents\legacy.agent.md') -Value $legacyAgentContent -NoNewline
    Set-Content -LiteralPath (Join-Path $Consumer '.sheen\manifest.json') -Value (@{
        schema = 'sheen-manifest/v1'
        source = 'https://github.com/IBuySpy-Shared/basecoat-sheen.git'
        ref = $Commit
        synced = '2026-01-01T00:00:00Z'
        commit = $Commit
        agent_distribution = 'organization'
        files = @('.github/agents/legacy.agent.md')
    } | ConvertTo-Json -Depth 5) -NoNewline
    Invoke-CheckedGit -C $Consumer add -A
    Invoke-CheckedGit -C $Consumer commit -m 'add legacy managed agent'
}

function Assert-WorkflowPin([string]$Consumer, [string]$Commit, [string]$Owner = 'IBuySpy-Shared/basecoat-sheen') {
    $workflowPath = Join-Path $Consumer '.github\workflows\sheen-sync.yml'
    $workflow = Get-Content -LiteralPath $workflowPath -Raw
    $escapedOwner = [regex]::Escape($Owner)
    $uses = [regex]::Matches(
        $workflow,
        "(?m)^\s*uses:\s+$escapedOwner/\.github/actions/(?:sync-assets|discover-release)@(?<sha>[0-9a-f]{40})\s*$"
    )
    if ($uses.Count -ne 2) { throw "Expected two SHA-pinned action refs; found $($uses.Count)" }
    foreach ($match in $uses) {
        if ($match.Groups['sha'].Value -ne $Commit) { throw 'Action ref does not match the pinned source commit' }
    }
    $sourceCommit = [regex]::Match($workflow, '(?m)^\s*source_commit:\s*(?<sha>[0-9a-f]{40})\s*$')
    if (-not $sourceCommit.Success -or $sourceCommit.Groups['sha'].Value -ne $Commit) {
        throw 'source_commit input does not match the action SHA'
    }
}

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $source 'templates'), (Join-Path $source '.github\skills\sample'), (Join-Path $source '.github\agents') | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'sync.ps1') -Destination (Join-Path $source 'sync.ps1')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'sync.sh') -Destination (Join-Path $source 'sync.sh')
    Set-Content -LiteralPath (Join-Path $source 'templates\sheen-sync.yml') -Value @'
# This file was synced into your repo by basecoat-sheen.
jobs:
  discover:
    uses: IBuySpy-Shared/basecoat-sheen/.github/actions/discover-release@v1.2.0
  sync:
    uses: IBuySpy-Shared/basecoat-sheen/.github/actions/sync-assets@v1.2.0
    with:
      source_commit: v1.2.0
'@ -NoNewline
    Set-Content -LiteralPath (Join-Path $source '.github\skills\sample\sample.md') -Value 'Pinned payload' -NoNewline
    Set-Content -LiteralPath (Join-Path $source '.github\agents\legacy.agent.md') -Value $legacyAgentContent -NoNewline
    Invoke-CheckedGit -C $source init -b main
    Invoke-CheckedGit -C $source config user.name test
    Invoke-CheckedGit -C $source config user.email test@example.com
    Invoke-CheckedGit -C $source add -A
    Invoke-CheckedGit -C $source commit -m source
    $commit = (& git -C $source rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not resolve source fixture commit' }

    New-Item -ItemType Directory -Force -Path $archive | Out-Null
    Get-ChildItem -LiteralPath $source -Force | Where-Object { $_.Name -ne '.git' } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $archive -Recurse -Force
    }
    $payloadHash = (Get-FileHash -LiteralPath (Join-Path $archive 'templates\sheen-sync.yml') -Algorithm SHA256).Hash

    New-Consumer $consumerPs
    Write-Host '[1/7] PowerShell local pinned payload installs without cloning and renders matching pins'
    Invoke-PowerShellSync $consumerPs $archive $commit
    $manifest = Get-Content -LiteralPath (Join-Path $consumerPs '.sheen\manifest.json') -Raw | ConvertFrom-Json
    if ($manifest.commit -ne $commit) { throw 'Manifest commit does not match action release SHA' }
    Assert-WorkflowPin $consumerPs $commit
    if ((Get-Content -LiteralPath (Join-Path $consumerPs '.github\skills\sample\sample.md') -Raw) -cne 'Pinned payload') {
        throw 'Local action payload was not installed'
    }
    Assert-BasecoatSyncPreserved $consumerPs
    if ((Get-FileHash -LiteralPath (Join-Path $archive 'templates\sheen-sync.yml') -Algorithm SHA256).Hash -ne $payloadHash) {
        throw 'The staged copy mutated the action payload cache'
    }

    Write-Host '[2/7] Repeated PowerShell local sync preserves the manifest and consumer tree'
    Invoke-CheckedGit -C $consumerPs add -A
    Invoke-CheckedGit -C $consumerPs commit -m 'commit first sync'
    $manifestPath = Join-Path $consumerPs '.sheen\manifest.json'
    $firstManifest = [System.IO.File]::ReadAllBytes($manifestPath)
    Invoke-PowerShellSync $consumerPs $archive $commit
    $secondManifest = [System.IO.File]::ReadAllBytes($manifestPath)
    if (-not [System.Linq.Enumerable]::SequenceEqual[byte]($firstManifest, $secondManifest)) {
        throw ("Repeated local sync rewrote the stable manifest`nfirst: {0}`nsecond: {1}" -f
            [System.Text.Encoding]::UTF8.GetString($firstManifest),
            [System.Text.Encoding]::UTF8.GetString($secondManifest))
    }
    $status = & git -C $consumerPs status --porcelain=v1
    if ($LASTEXITCODE -ne 0 -or $status) { throw 'Repeated local sync must leave no consumer changes' }

    Write-Host '[3/7] Missing paths, malformed hashes, and legacy-agent provenance fail visibly'
    foreach ($case in @(
        @{ Path = Join-Path $scratch 'missing-source'; Commit = $commit; Pattern = 'Local source payload directory does not exist' },
        @{ Path = $archive; Commit = ''; Pattern = 'must be provided together' },
        @{ Path = ''; Commit = $commit; Pattern = 'must be provided together' },
        @{ Path = $archive; Commit = 'not-a-sha'; Pattern = 'full 40-character commit SHA' }
    )) {
        $oldPath = $env:SHEEN_SOURCE_PATH
        $oldCommit = $env:SHEEN_SOURCE_COMMIT
        try {
            $env:SHEEN_SOURCE_PATH = $case.Path
            $env:SHEEN_SOURCE_COMMIT = $case.Commit
            Push-Location $consumerPs
            try {
                $output = ''
                try { & $syncRoot 2>&1 | Out-String } catch { $output = $_.Exception.Message }
                if ($output -notmatch [regex]::Escape($case.Pattern)) { throw "Expected local source error '$($case.Pattern)', got '$output'" }
            }
            finally { Pop-Location }
        }
        finally {
            $env:SHEEN_SOURCE_PATH = $oldPath
            $env:SHEEN_SOURCE_COMMIT = $oldCommit
        }
    }
    $brokenArchive = Join-Path $scratch 'broken-archive'
    New-Item -ItemType Directory -Force -Path $brokenArchive | Out-Null
    Set-Content -LiteralPath (Join-Path $brokenArchive 'sync.sh') -Value '# incomplete archive' -NoNewline
    $oldPath = $env:SHEEN_SOURCE_PATH
    $oldCommit = $env:SHEEN_SOURCE_COMMIT
    try {
        $env:SHEEN_SOURCE_PATH = $brokenArchive
        $env:SHEEN_SOURCE_COMMIT = $commit
        Push-Location $consumerPs
        try {
            $output = ''
            try { & $syncRoot 2>&1 | Out-String } catch { $output = $_.Exception.Message }
            if ($output -notmatch 'missing required file') { throw "Expected missing-payload error, got '$output'" }
        }
        finally { Pop-Location }
    }
    finally {
        $env:SHEEN_SOURCE_PATH = $oldPath
        $env:SHEEN_SOURCE_COMMIT = $oldCommit
    }

    New-Consumer $legacyConsumer
    Add-LegacyAgent $legacyConsumer $commit
    $legacyFile = Join-Path $legacyConsumer '.github\agents\legacy.agent.md'
    $legacyManifestPath = Join-Path $legacyConsumer '.sheen\manifest.json'
    $legacyManifestBytes = [System.IO.File]::ReadAllBytes($legacyManifestPath)
    try {
        Invoke-PowerShellSync $legacyConsumer $archive $commit
        throw 'Expected archive mode to refuse unverifiable legacy managed agents'
    }
    catch {
        if ($_.Exception.Message -notmatch 'Cannot verify legacy agent ownership') { throw }
    }
    if ((Get-Content -LiteralPath $legacyFile -Raw) -cne $legacyAgentContent) {
        throw 'Legacy agent refusal must not alter consumer-owned content'
    }
    if (-not [System.Linq.Enumerable]::SequenceEqual[byte](
        $legacyManifestBytes,
        [System.IO.File]::ReadAllBytes($legacyManifestPath)
    )) {
        throw 'Legacy agent refusal must not alter the ownership manifest'
    }

    Write-Host '[4/7] Callable staged clones retain history for verified legacy-agent migration'
    New-Consumer $legacyCloneConsumer
    Add-LegacyAgent $legacyCloneConsumer $commit
    Invoke-PowerShellSync $legacyCloneConsumer $source $commit
    if (Test-Path -LiteralPath (Join-Path $legacyCloneConsumer '.github\agents\legacy.agent.md')) {
        throw 'Callable clone with Git history should remove the verified legacy managed agent'
    }
    Assert-BasecoatSyncPreserved $legacyCloneConsumer

    Write-Host '[5/7] Unmanaged workflow files are preserved'
    $unmanaged = "name: consumer-owned`n"
    New-Consumer $unmanagedConsumer $unmanaged
    Invoke-PowerShellSync $unmanagedConsumer $archive $commit
    if ((Get-Content -LiteralPath (Join-Path $unmanagedConsumer '.github\workflows\sheen-sync.yml') -Raw) -cne $unmanaged) {
        throw 'Unmanaged consumer workflow was overwritten'
    }
    $unmanagedManifest = Get-Content -LiteralPath (Join-Path $unmanagedConsumer '.sheen\manifest.json') -Raw | ConvertFrom-Json
    if (@($unmanagedManifest.files) -contains '.github/workflows/sheen-sync.yml') {
        throw 'Unmanaged workflow must not become manifest-owned'
    }

    Write-Host '[6/7] Public action owner remains public while pins render to the source SHA'
    $publicArchive = Join-Path $scratch 'public-action-archive'
    New-Item -ItemType Directory -Force -Path $publicArchive | Out-Null
    Get-ChildItem -LiteralPath $archive -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $publicArchive -Recurse -Force
    }
    $publicTemplate = Join-Path $publicArchive 'templates\sheen-sync.yml'
    $publicText = (Get-Content -LiteralPath $publicTemplate -Raw).Replace(
        'IBuySpy-Shared/basecoat-sheen',
        'ivegamsft/sheen'
    )
    Set-Content -LiteralPath $publicTemplate -Value $publicText -NoNewline
    New-Consumer $consumerPublic
    Invoke-PowerShellSync $consumerPublic $publicArchive $commit
    Assert-WorkflowPin $consumerPublic $commit 'ivegamsft/sheen'
    $publicWorkflow = Get-Content -LiteralPath (Join-Path $consumerPublic '.github\workflows\sheen-sync.yml') -Raw
    if ($publicWorkflow.Contains('uses: IBuySpy-Shared/basecoat-sheen/.github/actions/')) {
        throw 'PowerShell renderer must not force public action references to the private host'
    }
    Assert-BasecoatSyncPreserved $consumerPublic

    $bashCommand = Get-Command bash -ErrorAction SilentlyContinue
    $bashPath = if ($IsWindows) {
        Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
    } else {
        $bashCommand.Source
    }
    if ($bashPath -and (Test-Path -LiteralPath $bashPath -PathType Leaf)) {
        Write-Host '[7/7] Bash archive and callable-clone modes preserve history and root sync ownership'
        New-Consumer $consumerSh
        function Convert-BashPath([string]$Path) {
            if ($IsWindows) { return (& $bashPath -c 'cygpath -u "$1"' -- $Path).Trim() }
            return $Path.Replace('\', '/')
        }
        function Invoke-BashSync([string]$Consumer) {
            Push-Location $Consumer
            try {
                $output = & $bashPath (Join-Path $repoRoot 'sync.sh') 2>&1
                return @{ ExitCode = $LASTEXITCODE; Output = ($output -join "`n") }
            }
            finally { Pop-Location }
        }
        $oldPath = $env:SHEEN_SOURCE_PATH
        $oldCommit = $env:SHEEN_SOURCE_COMMIT
        $oldRepo = $env:SHEEN_REPO
        $oldRef = $env:SHEEN_REF
        $oldTemp = $env:SHEEN_SYNC_TEMP_ROOT
        try {
            $env:SHEEN_SOURCE_PATH = Convert-BashPath $archive
            $env:SHEEN_SOURCE_COMMIT = $commit
            $env:SHEEN_REPO = 'https://github.com/IBuySpy-Shared/basecoat-sheen.git'
            $env:SHEEN_REF = $commit
            $stagingPath = Join-Path $consumerSh '.git\sheen-sync-staging'
            $env:SHEEN_SYNC_TEMP_ROOT = Convert-BashPath $stagingPath
            foreach ($case in @(
                @{ Path = Convert-BashPath (Join-Path $scratch 'missing-bash-source'); Commit = $commit; Pattern = 'local source payload directory does not exist' },
                @{ Path = Convert-BashPath $archive; Commit = ''; Pattern = 'must be provided together' },
                @{ Path = Convert-BashPath $archive; Commit = 'not-a-sha'; Pattern = 'full 40-character commit SHA' }
            )) {
                $env:SHEEN_SOURCE_PATH = $case.Path
                $env:SHEEN_SOURCE_COMMIT = $case.Commit
                $result = Invoke-BashSync $consumerSh
                if ($result.ExitCode -eq 0 -or $result.Output -notmatch [regex]::Escape($case.Pattern)) {
                    throw "Bash sync must reject '$($case.Pattern)' (exit=$($result.ExitCode), output='$($result.Output)')"
                }
            }
            $env:SHEEN_SOURCE_PATH = Convert-BashPath $archive
            $env:SHEEN_SOURCE_COMMIT = $commit
            $legacyArchiveBashConsumer = Join-Path $scratch 'consumer-legacy-bash-archive'
            New-Consumer $legacyArchiveBashConsumer
            Add-LegacyAgent $legacyArchiveBashConsumer $commit
            $legacyArchiveManifest = Join-Path $legacyArchiveBashConsumer '.sheen\manifest.json'
            $legacyArchiveManifestBytes = [System.IO.File]::ReadAllBytes($legacyArchiveManifest)
            $legacyArchiveResult = Invoke-BashSync $legacyArchiveBashConsumer
            if ($legacyArchiveResult.ExitCode -eq 0 -or
                $legacyArchiveResult.Output -notmatch 'Cannot verify legacy agent ownership') {
                throw "Bash action archive must refuse unverifiable legacy agents: $($legacyArchiveResult.Output)"
            }
            if (-not (Test-Path -LiteralPath (Join-Path $legacyArchiveBashConsumer '.github\agents\legacy.agent.md')) -or
                -not [System.Linq.Enumerable]::SequenceEqual[byte](
                    $legacyArchiveManifestBytes,
                    [System.IO.File]::ReadAllBytes($legacyArchiveManifest)
                )) {
                throw 'Bash action archive refusal must preserve the legacy agent and manifest'
            }
            Assert-BasecoatSyncPreserved $legacyArchiveBashConsumer

            Push-Location $consumerSh
            try {
                & $bashPath (Join-Path $repoRoot 'sync.sh')
                if ($LASTEXITCODE -ne 0) { throw "Bash local sync failed: $LASTEXITCODE" }
            }
            finally { Pop-Location }
            Assert-WorkflowPin $consumerSh $commit
            Assert-BasecoatSyncPreserved $consumerSh
            Invoke-CheckedGit -C $consumerSh add -A
            Invoke-CheckedGit -C $consumerSh commit -m 'commit first sync'
            $manifestPath = Join-Path $consumerSh '.sheen\manifest.json'
            $firstManifest = [System.IO.File]::ReadAllBytes($manifestPath)
            Push-Location $consumerSh
            try {
                & $bashPath (Join-Path $repoRoot 'sync.sh')
                if ($LASTEXITCODE -ne 0) { throw "Repeated Bash local sync failed: $LASTEXITCODE" }
            }
            finally { Pop-Location }
            $secondManifest = [System.IO.File]::ReadAllBytes($manifestPath)
            if (-not [System.Linq.Enumerable]::SequenceEqual[byte]($firstManifest, $secondManifest)) {
                throw 'Repeated Bash local sync rewrote the stable manifest'
            }
            $status = & git -C $consumerSh status --porcelain=v1
            if ($LASTEXITCODE -ne 0 -or $status) { throw 'Repeated Bash local sync must leave no consumer changes' }

            $legacyBashConsumer = Join-Path $scratch 'consumer-legacy-bash'
            New-Consumer $legacyBashConsumer
            Add-LegacyAgent $legacyBashConsumer $commit
            $env:SHEEN_SOURCE_PATH = Convert-BashPath $source
            $legacyBashResult = Invoke-BashSync $legacyBashConsumer
            if ($legacyBashResult.ExitCode -ne 0) {
                throw "Bash callable clone with Git history failed legacy-agent migration: $($legacyBashResult.Output)"
            }
            if (Test-Path -LiteralPath (Join-Path $legacyBashConsumer '.github\agents\legacy.agent.md')) {
                throw 'Bash callable clone with Git history should remove the verified legacy managed agent'
            }
            Assert-BasecoatSyncPreserved $legacyBashConsumer
        }
        finally {
            $env:SHEEN_SOURCE_PATH = $oldPath
            $env:SHEEN_SOURCE_COMMIT = $oldCommit
            $env:SHEEN_REPO = $oldRepo
            $env:SHEEN_REF = $oldRef
            $env:SHEEN_SYNC_TEMP_ROOT = $oldTemp
        }
    }
    else {
        Write-Host 'Skipping Bash runtime fixture because bash is unavailable.'
    }
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

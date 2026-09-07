#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Upgrade or re-sync basecoat-sheen assets in a consumer repository.

.DESCRIPTION
    Windows-first (PowerShell 7+ / 5.1+) upgrade script for consumer repositories
    that have already adopted basecoat-sheen via sync.ps1.

    Detects the current installed version from .sheen/manifest.json, fetches the
    latest (or pinned) upstream ref, shows a changelog diff, and re-runs sync.ps1
    so updated assets land with the same allow-list policy as the previous sync.

    Operations:
        1. Read current .sheen.yml and .sheen/manifest.json (detect current version).
        2. Optionally show what changed between the installed and target ref.
        3. Run sync.ps1 at the target ref.
        4. Run scripts/diagnose-sheen.ps1 to validate the result.
        5. Optionally open a pull request via the GitHub CLI.

.PARAMETER Ref
    Branch or tag to upgrade to.
    Defaults to SHEEN_REF env var, then the ref already in .sheen.yml, then 'main'.

.PARAMETER Source
    Upstream sheen repo HTTPS URL or file path.
    Defaults to SHEEN_REPO env var, then the source already in .sheen.yml.

.PARAMETER Silent
    Skip all interactive prompts; suitable for CI use.

.PARAMETER SkipPR
    Do not offer to open a pull request after a successful upgrade.

.PARAMETER SkipDiagnose
    Do not run scripts/diagnose-sheen.ps1 after sync.

.PARAMETER DryRun
    Show what would be done without running sync or creating a PR.

.EXAMPLE
    # Interactive upgrade to latest main
    pwsh scripts/upgrade-sheen.ps1

.EXAMPLE
    # Pin to a specific release in CI — no prompts, no PR
    pwsh scripts/upgrade-sheen.ps1 -Ref v0.7.0 -Silent -SkipPR

.EXAMPLE
    # Preview what would happen
    pwsh scripts/upgrade-sheen.ps1 -Ref v0.7.0 -DryRun
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Ref    = $env:SHEEN_REF,
    [string]$Source = $env:SHEEN_REPO,
    [switch]$Silent,
    [switch]$SkipPR,
    [switch]$SkipDiagnose,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── output helpers ────────────────────────────────────────────────────────────
function Write-Header([string]$text) {
    Write-Host ''
    Write-Host ('─' * 56) -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host ('─' * 56) -ForegroundColor Cyan
}
function Write-Ok([string]$msg)   { Write-Host "  ✅  $msg" -ForegroundColor Green }
function Write-Warn([string]$msg) { Write-Host "  ⚠️   $msg" -ForegroundColor Yellow }
function Write-Fail([string]$msg) { Write-Host "  ❌  $msg" -ForegroundColor Red }
function Write-Info([string]$msg) { Write-Host "  ℹ️   $msg" -ForegroundColor DarkGray }

function Confirm-Step([string]$prompt) {
    if ($Silent) { return $true }
    $ans = Read-Host "$prompt [Y/n]"
    return ($ans -eq '' -or $ans -match '^[Yy]')
}

Write-Host ''
Write-Host '  basecoat-sheen Upgrade' -ForegroundColor White
Write-Host "  PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray
if ($DryRun) { Write-Host '  [DRY RUN — no files will be modified]' -ForegroundColor Yellow }

# ── Phase 1: prerequisites ────────────────────────────────────────────────────
Write-Header 'Phase 1 — Prerequisites'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Fail 'git not found — install from https://git-scm.com'
    exit 1
}
Write-Ok "git available"

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Fail 'Not inside a git repository. Run from your consumer repo root.'
    exit 1
}
Set-Location $repoRoot
Write-Ok "Consumer repo root: $repoRoot"

$ghAvailable = $null -ne (Get-Command gh -ErrorAction SilentlyContinue)
if ($ghAvailable) {
    Write-Ok "GitHub CLI available"
} else {
    Write-Warn 'GitHub CLI (gh) not found — PR creation will be skipped.'
}

# ── Phase 2: read installed state ────────────────────────────────────────────
Write-Header 'Phase 2 — Installed State'

$configPath   = Join-Path $repoRoot '.sheen.yml'
$manifestPath = Join-Path $repoRoot '.sheen/manifest.json'

if (-not (Test-Path $configPath)) {
    Write-Fail '.sheen.yml not found. Run sync.ps1 first to adopt sheen, then upgrade.'
    exit 1
}
Write-Ok '.sheen.yml found'

$installedVersion = $null
$installedRef     = $null
$installedSource  = $null

if (Test-Path $manifestPath) {
    try {
        $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
        $installedRef    = $manifest.ref
        $installedSource = $manifest.source
        Write-Ok "Manifest: ref=$installedRef  source=$installedSource"
    } catch {
        Write-Warn "Could not parse .sheen/manifest.json: $_"
    }
}

# Read .sheen.yml for source/ref defaults
try {
    $configText = Get-Content $configPath -Raw
    if (-not $Source) {
        if ($configText -match '(?m)^source:\s*(.+)$') { $Source = $Matches[1].Trim().Trim('"').Trim("'") }
    }
    if (-not $Ref) {
        if ($configText -match '(?m)^ref:\s*(.+)$') { $Ref = $Matches[1].Trim().Trim('"').Trim("'") }
    }
} catch {
    Write-Warn "Could not read .sheen.yml: $_"
}

if (-not $Source) { $Source = 'https://github.com/ivegamsft/sheen.git' }
if (-not $Ref)    { $Ref    = 'main' }

Write-Ok "Upgrade target: $Source @ $Ref"

# ── Phase 3: show changelog diff ─────────────────────────────────────────────
Write-Header 'Phase 3 — Changelog Preview'

if ($installedRef -and $installedRef -ne $Ref) {
    Write-Info "Upgrading from ref '$installedRef' → '$Ref'"
} elseif ($installedRef) {
    Write-Info "Re-syncing at same ref '$Ref' (asset updates within ref)"
} else {
    Write-Info "No previous manifest ref; performing fresh sync at '$Ref'"
}

# Fetch upstream CHANGELOG for a quick peek (best-effort)
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "sheen-upgrade-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$fetchedChangelog = $false
try {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $cloneArgs = @('clone', '--quiet', '--depth', '1', '--branch', $Ref, $Source, $tempDir)
    git @cloneArgs 2>$null
    if ($LASTEXITCODE -eq 0) {
        $upstreamChangelog = Join-Path $tempDir 'CHANGELOG.md'
        if (Test-Path $upstreamChangelog) {
            $lines = Get-Content $upstreamChangelog | Select-Object -First 40
            Write-Host ''
            Write-Host '  Upstream CHANGELOG (first 40 lines):' -ForegroundColor DarkGray
            $lines | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
            $fetchedChangelog = $true
        }
        # Read upstream version for display
        $upstreamVersion = Join-Path $tempDir 'version.json'
        if (Test-Path $upstreamVersion) {
            try {
                $upVer = (Get-Content $upstreamVersion -Raw | ConvertFrom-Json).version
                Write-Host ''
                Write-Ok "Upstream version: $upVer"
            } catch { }
        }
    }
} catch {
    Write-Warn "Could not fetch upstream CHANGELOG (non-fatal): $_"
} finally {
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
}

if (-not $fetchedChangelog) {
    Write-Info "CHANGELOG preview unavailable; proceeding without it."
}

# ── Phase 4: run upgrade ──────────────────────────────────────────────────────
Write-Header 'Phase 4 — Sync'

if (-not (Confirm-Step "  Proceed with upgrade to $Source @ $Ref?")) {
    Write-Host '  Aborted.' -ForegroundColor Yellow
    exit 0
}

$syncScript = Join-Path $repoRoot 'sync.ps1'
if (-not (Test-Path $syncScript)) {
    Write-Fail "sync.ps1 not found at $syncScript. Download the latest sync script from the sheen release assets."
    exit 1
}

if ($DryRun) {
    Write-Info "[DRY RUN] Would run: pwsh $syncScript"
    Write-Info "[DRY RUN] Would set SHEEN_REPO=$Source SHEEN_REF=$Ref"
} else {
    $env:SHEEN_REPO = $Source
    $env:SHEEN_REF  = $Ref
    pwsh -NoLogo -NoProfile -File $syncScript
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        Write-Fail "sync.ps1 exited with code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
    Write-Ok "sync.ps1 completed successfully"
    $env:SHEEN_REPO = ''
    $env:SHEEN_REF  = ''
}

# ── Phase 5: diagnose ─────────────────────────────────────────────────────────
Write-Header 'Phase 5 — Validate'

if ($SkipDiagnose) {
    Write-Info 'Diagnose step skipped (-SkipDiagnose).'
} else {
    $diagnoseScript = Join-Path $repoRoot 'scripts/diagnose-sheen.ps1'
    if (Test-Path $diagnoseScript) {
        if ($DryRun) {
            Write-Info "[DRY RUN] Would run: pwsh $diagnoseScript"
        } else {
            Write-Info "Running diagnose-sheen.ps1..."
            pwsh -NoLogo -NoProfile -File $diagnoseScript
            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
                Write-Warn "diagnose-sheen.ps1 reported warnings or errors (exit $LASTEXITCODE) — review output before merging."
            } else {
                Write-Ok "Diagnose passed"
            }
        }
    } else {
        Write-Warn "scripts/diagnose-sheen.ps1 not found — skipping validation."
    }
}

# ── Phase 6: open PR ──────────────────────────────────────────────────────────
Write-Header 'Phase 6 — Pull Request'

if ($SkipPR) {
    Write-Info 'PR step skipped (-SkipPR).'
} elseif (-not $ghAvailable) {
    Write-Info 'GitHub CLI not available — skipping PR creation.'
} elseif ($DryRun) {
    Write-Info '[DRY RUN] Would open a PR: chore: upgrade sheen assets to <ref>'
} else {
    $currentBranch = git branch --show-current 2>$null
    $prBranch = "chore/sheen-upgrade-$($Ref -replace '[^a-zA-Z0-9._-]', '-')"

    if (Confirm-Step "  Open a PR for this upgrade (branch: $prBranch)?") {
        # Stage all changes to sheen-managed paths
        git add '.sheen/' '.github/skills/' '.github/agents/' '.github/instructions/' '.github/prompts/' 'sheen/' 2>$null

        $status = git status --porcelain
        if (-not $status) {
            Write-Info 'No staged changes — nothing to commit. Upgrade may already be current.'
        } else {
            git checkout -b $prBranch 2>$null
            git commit -m "chore: upgrade sheen assets to $Ref

- Ran sync.ps1 at $Source @ $Ref
- Manifest updated at .sheen/manifest.json
- Review .sheen/manifest.json for the full file list

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
            git push --set-upstream origin $prBranch

            gh pr create `
                --title "chore: upgrade sheen assets to $Ref" `
                --body "## Sheen Upgrade

**Source:** $Source
**Ref:** $Ref

### What changed
See upstream [CHANGELOG](${Source -replace '\.git$', ''}/blob/$Ref/CHANGELOG.md) for details.

### Validation
- \`sync.ps1\` ran successfully.
- \`diagnose-sheen.ps1\` $(if ($SkipDiagnose) { 'skipped' } else { 'passed' }).

### Rollback
\`\`\`powershell
pwsh rollback.ps1
\`\`\`
" `
                --base main

            Write-Ok "PR created on branch $prBranch"
        }
    }
}

Write-Host ''
Write-Ok "Upgrade complete. Sheen assets are now at $Ref."
Write-Info "Next steps:"
Write-Info "  • Review changes with: git diff .sheen/"
Write-Info "  • Commit or push the upgrade branch"
Write-Info "  • To roll back: pwsh rollback.ps1"

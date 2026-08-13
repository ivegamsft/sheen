#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Syncs shared org memory from a private BaseCoat memory repository.

.DESCRIPTION
    Pulls the shared hot index and domain-specific memories from the org's
    private basecoat-memory repo into the local .memory/shared/ cache.
    Cache TTL is 24 hours by default. Does not commit anything.

.PARAMETER Export
    Generate a memory template for contribution to the shared repo.

.PARAMETER ExportFile
    Push a completed memory template to the shared repo and open a PR.
    Requires -Subject. Used after editing the template from -Export mode.

.PARAMETER Subject
    Subject tag for -Export/-ExportFile mode. Format: "domain:subject".

.PARAMETER Force
    Bypass TTL and re-sync everything from the shared repo.

.PARAMETER Status
    Show last sync time, memory count, and cache age without syncing.

.PARAMETER Domain
    Only sync memories for a specific domain (e.g., "ci", "security").

.EXAMPLE
    pwsh scripts/sync-shared-memory.ps1
    pwsh scripts/sync-shared-memory.ps1 -Force
    pwsh scripts/sync-shared-memory.ps1 -Export -Subject "ci:gh-aw-compile"
    pwsh scripts/sync-shared-memory.ps1 -ExportFile /tmp/ci-pattern.md -Subject "ci:gh-aw-compile"
    pwsh scripts/sync-shared-memory.ps1 -Status
    pwsh scripts/sync-shared-memory.ps1 -Domain ci
#>

param(
    [switch]$Export,
    [string]$ExportFile,
    [string]$Subject,
    [switch]$Force,
    [switch]$Status,
    [string]$Domain
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Configuration ─────────────────────────────────────────────────────────────

$SharedRepo    = $env:BASECOAT_SHARED_MEMORY_REPO  # e.g. "your-org/basecoat-memory"
$CacheDir      = Join-Path $PSScriptRoot ".." ".memory" "shared"
$HotIndexPath  = Join-Path $CacheDir "hot-index.md"
$MetaPath      = Join-Path $CacheDir "sync-meta.json"
$TtlHours      = 24

# ── Helpers ───────────────────────────────────────────────────────────────────

function Write-Step([string]$msg) { Write-Host "  → $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn([string]$msg) { Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Err([string]$msg)  { Write-Host "  ✗ $msg" -ForegroundColor Red }

function Get-SyncMeta {
    if (Test-Path $MetaPath) {
        return Get-Content $MetaPath -Raw | ConvertFrom-Json
    }
    return @{ lastSync = $null; memoryCount = 0 }
}

function Save-SyncMeta([int]$count) {
    @{
        lastSync    = (Get-Date -Format "o")
        memoryCount = $count
        repo        = $SharedRepo
    } | ConvertTo-Json | Set-Content $MetaPath -Encoding utf8
}

function Test-CacheStale {
    $meta = Get-SyncMeta
    if (-not $meta.lastSync) { return $true }
    $age = (Get-Date) - [datetime]$meta.lastSync
    return $age.TotalHours -gt $TtlHours
}

function Assert-SharedRepo {
    if (-not $SharedRepo) {
        Write-Err "BASECOAT_SHARED_MEMORY_REPO is not set."
        Write-Host "  Set it in your environment or .env:"
        Write-Host '    $env:BASECOAT_SHARED_MEMORY_REPO = "your-org/basecoat-memory"'
        exit 1
    }
}

function Assert-GhAuth {
    $null = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Not authenticated with gh CLI. Run: gh auth login"
        exit 1
    }
}

# ── Status mode ───────────────────────────────────────────────────────────────

if ($Status) {
    $meta = Get-SyncMeta
    if (-not $meta.lastSync) {
        Write-Warn "No sync has been performed yet."
        Write-Host "  Run: pwsh scripts/sync-shared-memory.ps1"
    } else {
        $age = [math]::Round(((Get-Date) - [datetime]$meta.lastSync).TotalHours, 1)
        $stale = if ($age -gt $TtlHours) { " (STALE — run sync)" } else { "" }
        Write-Host ""
        Write-Host "  Shared memory cache status" -ForegroundColor White
        Write-Host "  Repo:         $($meta.repo)"
        Write-Host "  Last sync:    $($meta.lastSync) ($age hours ago)$stale"
        Write-Host "  Memories:     $($meta.memoryCount)"
        Write-Host "  Cache dir:    $CacheDir"
        if (Test-Path $HotIndexPath) {
            $lines = (Get-Content $HotIndexPath).Count
            Write-Host "  Hot index:    $lines lines"
        }
    }
    exit 0
}

# ── Export mode ───────────────────────────────────────────────────────────────

if ($Export) {
    if (-not $Subject) {
        Write-Err "-Subject is required for -Export. Format: 'domain:subject'"
        exit 1
    }
    if ($Subject -notmatch '^[a-z-]+:[a-z-]+$') {
        Write-Err "Subject must be namespaced: 'domain:subject' (e.g., 'ci:gh-aw-compile')"
        exit 1
    }

    Assert-SharedRepo
    Assert-GhAuth

    $domain  = $Subject.Split(':')[0]
    $subject = $Subject.Split(':')[1]
    $branch  = "memory/$domain-$subject-$(Get-Date -Format 'yyyyMMdd')"
    $file    = "memories/$domain/$subject.md"

    Write-Host ""
    Write-Host "  Preparing memory contribution" -ForegroundColor White
    Write-Step "Subject: $Subject"
    Write-Step "Target:  $SharedRepo/$file"
    Write-Step "Branch:  $branch"
    Write-Host ""

    $template = @"
---
subject: "$Subject"
category: "convention"
confidence: 0.80
created: "$(Get-Date -Format 'yyyy-MM-dd')"
applies_to: "all teams"
---

# {Short title for this memory}

## Pattern

{The reusable pattern or rule — max 200 chars, generic, no project-specific references.}

## Evidence

- Validated in N sessions
- Context: {when this applies}
- Does NOT apply to: {exceptions}

## Source

{Link to originating issue, session checkpoint, or document}
"@

    $tmpFile = [System.IO.Path]::GetTempFileName() + ".md"
    $template | Set-Content $tmpFile -Encoding utf8

    Write-Ok "Template written to: $tmpFile"
    Write-Host ""
    Write-Warn "Edit the template above, then re-run with -ExportFile to open the PR."
    Write-Host "  Or open it now: code `"$tmpFile`""
    Write-Host ""
    Write-Host "  Next step after editing:"
    Write-Host "    pwsh scripts/sync-shared-memory.ps1 -ExportFile `"$tmpFile`" -Subject `"$Subject`""

    exit 0
}

# ── ExportFile mode ───────────────────────────────────────────────────────────

if ($ExportFile) {
    if (-not $Subject) {
        Write-Err "-Subject is required for -ExportFile. Format: 'domain:subject'"
        exit 1
    }
    if (-not (Test-Path $ExportFile)) {
        Write-Err "File not found: $ExportFile"
        exit 1
    }
    if ($Subject -notmatch '^[a-z-]+:[a-z][a-z0-9-]+$') {
        Write-Err "Subject must be namespaced: 'domain:subject' (e.g., 'ci:gh-aw-compile')"
        exit 1
    }

    Assert-SharedRepo
    Assert-GhAuth

    $domain   = $Subject.Split(':')[0]
    $key      = $Subject.Split(':')[1]
    $filePath = "memories/$domain/$key.md"
    $branch   = "memory/$domain-$key-$(Get-Date -Format 'yyyyMMdd')"
    $content  = Get-Content $ExportFile -Raw -Encoding utf8
    $encoded  = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))

    Write-Host ""
    Write-Host "  Pushing memory to $SharedRepo" -ForegroundColor White
    Write-Step "Subject:  $Subject"
    Write-Step "Target:   $SharedRepo/$filePath"
    Write-Step "Branch:   $branch"
    Write-Host ""

    # Get default branch SHA
    $defaultBranch = gh api "repos/$SharedRepo" --jq '.default_branch' 2>&1
    if ($LASTEXITCODE -ne 0) { $defaultBranch = "main" }
    $defaultBranch = $defaultBranch.Trim()

    $branchSha = gh api "repos/$SharedRepo/git/ref/heads/$defaultBranch" --jq '.object.sha' 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Err "Cannot read branch SHA: $branchSha"; exit 1 }
    $branchSha = $branchSha.Trim()

    # Create branch
    $createPayload = @{ ref = "refs/heads/$branch"; sha = $branchSha } | ConvertTo-Json -Compress
    $branchResult  = $createPayload | gh api "repos/$SharedRepo/git/refs" --method POST --input - 2>&1
    if ($LASTEXITCODE -ne 0 -and $branchResult -notmatch "already exists") {
        Write-Err "Failed to create branch: $branchResult"; exit 1
    }
    Write-Ok "Branch created: $branch"

    # Push file
    $filePayload = @{ message = "feat(memory): add $filePath"; content = $encoded; branch = $branch } |
        ConvertTo-Json -Compress
    $fileResult = $filePayload | gh api "repos/$SharedRepo/contents/$filePath" --method PUT --input - 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Err "Failed to push file: $fileResult"; exit 1 }
    Write-Ok "File pushed: $filePath"

    # Open PR using MEMORY_REPO_TOKEN if available
    $savedToken = $env:GH_TOKEN
    if ($env:MEMORY_REPO_TOKEN) { $env:GH_TOKEN = $env:MEMORY_REPO_TOKEN }

    $prTitle = "feat(memory): add $Subject"
    $prBody  = "## New Memory: ``$Subject``

Auto-generated by ``sync-shared-memory.ps1 -ExportFile``.

### Review Checklist
- [ ] Pattern is generic (not project-specific)
- [ ] Confidence score is justified
- [ ] Subject namespace is correct
- [ ] Evidence is accurate

---
*Memory steward: review and merge or request changes.*"

    $prUrl = gh pr create `
        --repo $SharedRepo `
        --title $prTitle `
        --base $defaultBranch `
        --head $branch `
        --body $prBody 2>&1
    $env:GH_TOKEN = $savedToken

    if ($LASTEXITCODE -ne 0) { Write-Err "Failed to open PR: $prUrl"; exit 1 }

    Write-Host ""
    Write-Ok "Memory contributed!"
    Write-Host "  PR: $prUrl"
    Write-Host ""
    exit 0
}

# ── Pull / sync mode ──────────────────────────────────────────────────────────

Assert-SharedRepo
Assert-GhAuth

if (-not $Force -and -not (Test-CacheStale)) {
    $meta = Get-SyncMeta
    $age  = [math]::Round(((Get-Date) - [datetime]$meta.lastSync).TotalHours, 1)
    Write-Ok "Shared memory cache is fresh ($age hours old, TTL = $TtlHours h). Use -Force to re-sync."
    exit 0
}

Write-Host ""
Write-Host "  Syncing shared memory from $SharedRepo" -ForegroundColor White

# Ensure cache directory exists (git-ignored)
New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null

# Pull hot index
Write-Step "Fetching hot-index.md..."
try {
    $hotIndex = gh api "repos/$SharedRepo/contents/hot-index.md" --jq '.content' 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Could not fetch hot-index.md: $hotIndex" }
    [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($hotIndex)) |
        Set-Content $HotIndexPath -Encoding utf8
    Write-Ok "Hot index cached → $HotIndexPath"
} catch {
    Write-Warn "Could not fetch hot index: $_"
    Write-Warn "Shared memory will not be available this session."
    exit 0
}

# Pull domain-specific memories
$domains = if ($Domain) { @($Domain) } else {
    try {
        gh api "repos/$SharedRepo/contents/memories" --jq '.[].name' 2>&1 |
            Where-Object { $_ -match '^[a-z]' }
    } catch { @() }
}

$memoryCount = 0
foreach ($d in $domains) {
    $domainDir = Join-Path $CacheDir "memories" $d
    New-Item -ItemType Directory -Path $domainDir -Force | Out-Null

    Write-Step "Syncing domain: $d"
    try {
        $files = gh api "repos/$SharedRepo/contents/memories/$d" --jq '.[].name' 2>&1 |
                 Where-Object { $_ -match '\.md$' }
        foreach ($f in $files) {
            $content = gh api "repos/$SharedRepo/contents/memories/$d/$f" --jq '.content' 2>&1
            if ($LASTEXITCODE -eq 0) {
                [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($content)) |
                    Set-Content (Join-Path $domainDir $f) -Encoding utf8
                $memoryCount++
            }
        }
        Write-Ok "  $d: $($files.Count) memories"
    } catch {
        Write-Warn "  Could not sync domain '$d': $_"
    }
}

Save-SyncMeta -count $memoryCount

Write-Host ""
Write-Ok "Sync complete. $memoryCount memories cached from $SharedRepo."
Write-Host "  Cache: $CacheDir"
Write-Host "  Valid for: $TtlHours hours (use -Force to re-sync earlier)"
Write-Host ""

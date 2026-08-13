#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validate, audit, update, and purge memories in the shared basecoat-memory repository.

.DESCRIPTION
    Four modes covering the full memory lifecycle beyond initial contribution:

    -Validate  Check all memory files for frontmatter completeness, fact length,
               subject format, and scope policy markers. Exits non-zero on violations.
               Safe to run in CI — no writes.

    -Audit     Scan all memories for staleness (no last_validated after 180 days),
               low confidence, or scope violations. Outputs an actionable report.
               Optionally opens a PR moving stale memories to deprecated/.

    -Update    Append new evidence to an existing memory and bump last_validated.
               Opens a PR in basecoat-memory.

    -Purge     Move a memory to deprecated/{domain}/{key}.md with a deprecation note.
               Opens a PR in basecoat-memory.

.PARAMETER Validate
    Validate all memory files. Exits 1 if violations found. Use in CI.

.PARAMETER Audit
    Scan all memories and report stale / low-confidence / out-of-scope entries.

.PARAMETER Update
    Update mode — requires -Subject and -Evidence.

.PARAMETER Purge
    Purge mode — requires -Subject and -Reason.

.PARAMETER Subject
    Memory subject key (domain:key). Required for -Update and -Purge.

.PARAMETER Evidence
    New evidence string to append. Required for -Update.

.PARAMETER Reason
    Deprecation reason. Required for -Purge.

.PARAMETER StaleAfterDays
    Days without last_validated before a memory is considered stale. Default: 180.

.PARAMETER OpenPR
    For -Audit: open a PR in basecoat-memory moving stale memories to deprecated/.
    Default: false (report only).

.PARAMETER DryRun
    For -Update and -Purge: print changes without writing. For -Audit with -OpenPR: skip PR.

.EXAMPLE
    pwsh scripts/audit-memories.ps1 -Validate
    pwsh scripts/audit-memories.ps1 -Audit
    pwsh scripts/audit-memories.ps1 -Audit -OpenPR
    pwsh scripts/audit-memories.ps1 -Update -Subject "ci:copilot-agent-pr" -Evidence "Confirmed in PR #620"
    pwsh scripts/audit-memories.ps1 -Purge -Subject "portal:scan-backend" -Reason "Portal removed in v4.0"
#>

[CmdletBinding()]
param(
    [switch]$Validate,
    [switch]$Audit,
    [switch]$Update,
    [switch]$Purge,
    [string]$Subject,
    [string]$Evidence,
    [string]$Reason,
    [int]   $StaleAfterDays = 180,
    [switch]$OpenPR,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Configuration ──────────────────────────────────────────────────────────────

$SharedRepo = $env:BASECOAT_SHARED_MEMORY_REPO

# ── Helpers ────────────────────────────────────────────────────────────────────

function Write-Step([string]$msg) { Write-Host "  → $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn([string]$msg) { Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Err([string]$msg)  { Write-Host "  ✗ $msg" -ForegroundColor Red }

function Assert-SharedRepo {
    if (-not $SharedRepo) {
        Write-Err "BASECOAT_SHARED_MEMORY_REPO is not set."
        Write-Host '  Set: $env:BASECOAT_SHARED_MEMORY_REPO = "your-org/basecoat-memory"'
        exit 1
    }
}

function Assert-GhAuth {
    $null = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Err "Not authenticated. Run: gh auth login"; exit 1 }
}

function Get-AllMemoryFiles {
    $result = gh api "repos/$SharedRepo/git/trees/HEAD?recursive=1" `
        --jq '[.tree[] | select(.path | startswith("memories/")) | select(.path | endswith(".md")) | .path]' 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Cannot list memory files: $result" }
    return $result | ConvertFrom-Json
}

function Get-MemoryContent([string]$path) {
    $b64 = gh api "repos/$SharedRepo/contents/$path" --jq '.content' 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Cannot fetch $path`: $b64" }
    $b64clean = ($b64 -replace '\s', '')
    return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64clean))
}

function Get-MemoryFileSha([string]$path) {
    $sha = gh api "repos/$SharedRepo/contents/$path" --jq '.sha' 2>&1
    if ($LASTEXITCODE -ne 0) { return $null }
    return $sha.Trim()
}

function Parse-Frontmatter([string]$content) {
    $fm = @{}
    if ($content -notmatch '(?s)^---\s*\n(.+?)\n---') { return $fm }
    $block = $Matches[1]
    foreach ($line in ($block -split "`n")) {
        if ($line -match '^(\w+):\s*"?([^"]*)"?\s*$') {
            $fm[$Matches[1]] = $Matches[2].Trim()
        }
    }
    return $fm
}

function Get-DefaultBranch {
    $b = gh api "repos/$SharedRepo" --jq '.default_branch' 2>&1
    if ($LASTEXITCODE -ne 0) { return "main" }
    return $b.Trim()
}

function Create-Branch([string]$name, [string]$fromBranch) {
    $sha = gh api "repos/$SharedRepo/git/ref/heads/$fromBranch" --jq '.object.sha' 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Cannot get branch SHA: $sha" }
    $payload = @{ ref = "refs/heads/$name"; sha = $sha.Trim() } | ConvertTo-Json -Compress
    $result  = $payload | gh api "repos/$SharedRepo/git/refs" --method POST --input - 2>&1
    if ($LASTEXITCODE -ne 0 -and $result -notmatch "already exists") {
        throw "Cannot create branch $name`: $result"
    }
}

function Push-File([string]$path, [string]$content, [string]$branch, [string]$message, [string]$sha) {
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
    $payload = @{ message = $message; content = $encoded; branch = $branch }
    if ($sha) { $payload.sha = $sha }
    $result = ($payload | ConvertTo-Json -Compress) | gh api "repos/$SharedRepo/contents/$path" `
        --method PUT --input - 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Cannot push $path`: $result" }
}

function Open-PR([string]$title, [string]$base, [string]$head, [string]$body) {
    $savedToken = $env:GH_TOKEN
    if ($env:MEMORY_REPO_TOKEN) { $env:GH_TOKEN = $env:MEMORY_REPO_TOKEN }
    $url = gh pr create --repo $SharedRepo --title $title --base $base --head $head --body $body 2>&1
    $env:GH_TOKEN = $savedToken
    if ($LASTEXITCODE -ne 0) { throw "Cannot open PR: $url" }
    return $url
}

# ── Validate mode ─────────────────────────────────────────────────────────────

if ($Validate) {
    Assert-SharedRepo
    Assert-GhAuth

    Write-Host ""
    Write-Host "  Memory Validation — $SharedRepo" -ForegroundColor White
    Write-Host ""

    $files      = Get-AllMemoryFiles
    $violations = [System.Collections.Generic.List[string]]::new()

    foreach ($path in $files) {
        $content = Get-MemoryContent $path
        $fm      = Parse-Frontmatter $content

        # Required frontmatter fields
        foreach ($field in @("subject", "confidence", "created", "category")) {
            if (-not $fm[$field]) {
                $violations.Add("$path — missing frontmatter field: $field")
            }
        }

        # Subject format
        if ($fm.subject -and $fm.subject -notmatch '^[a-z][a-z-]+:[a-z][a-z0-9-]+$') {
            $violations.Add("$path — subject '$($fm.subject)' does not match 'domain:key' format")
        }

        # Confidence range
        if ($fm.confidence) {
            $conf = [double]$fm.confidence
            if ($conf -lt 0 -or $conf -gt 1) {
                $violations.Add("$path — confidence $conf is outside 0.0–1.0")
            }
        }

        # Fact length (extract the Pattern section body)
        if ($content -match '(?m)^## Pattern\s*\n+(.+?)(\n##|\z)') {
            $fact = $Matches[1].Trim()
            if ($fact.Length -gt 300) {
                $violations.Add("$path — Pattern section exceeds 300 chars ($($fact.Length))")
            }
        } else {
            $violations.Add("$path — missing '## Pattern' section")
        }

        # Scope: reject known project-specific markers
        $scopePatterns = @("jest", "typeorm", "winston", "supertest", "express", "prisma")
        foreach ($sp in $scopePatterns) {
            if ($content -imatch "\b$sp\b") {
                $violations.Add("$path — contains project-specific marker '$sp' (check scope policy)")
            }
        }
    }

    Write-Host "  Files checked: $($files.Count)"
    if ($violations.Count -eq 0) {
        Write-Ok "All $($files.Count) memory files valid"
        exit 0
    } else {
        Write-Err "$($violations.Count) violation(s) found:"
        foreach ($v in $violations) { Write-Host "    • $v" -ForegroundColor Red }
        exit 1
    }
}

# ── Audit mode ────────────────────────────────────────────────────────────────

if ($Audit) {
    Assert-SharedRepo
    Assert-GhAuth

    $cutoff = (Get-Date).AddDays(-$StaleAfterDays)
    Write-Host ""
    Write-Host "  Memory Audit — $SharedRepo" -ForegroundColor White
    Write-Host "  Stale threshold: $StaleAfterDays days (before $(Get-Date $cutoff -Format 'yyyy-MM-dd'))"
    Write-Host ""

    $files  = Get-AllMemoryFiles
    $stale  = [System.Collections.Generic.List[hashtable]]::new()
    $lowCon = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($path in $files) {
        $content = Get-MemoryContent $path
        $fm      = Parse-Frontmatter $content

        $validated = if ($fm.last_validated) { [datetime]$fm.last_validated }
                     elseif ($fm.created)     { [datetime]$fm.created }
                     else                     { [datetime]::MinValue }

        $conf = if ($fm.confidence) { [double]$fm.confidence } else { 0 }

        if ($validated -lt $cutoff) {
            $ageDays = ([int]((Get-Date) - $validated).TotalDays)
            $stale.Add(@{ path = $path; subject = $fm.subject; age = $ageDays; validated = $validated.ToString("yyyy-MM-dd") })
        }
        if ($conf -lt 0.50) {
            $lowCon.Add(@{ path = $path; subject = $fm.subject; confidence = $conf })
        }
    }

    Write-Host "  Total memories: $($files.Count)"
    Write-Host ""

    if ($stale.Count -gt 0) {
        Write-Warn "$($stale.Count) stale memory/memories (>$StaleAfterDays days without validation):"
        foreach ($s in ($stale | Sort-Object { $_.age } -Descending)) {
            Write-Host "    • $($s.path) — last validated $($s.validated) ($($s.age) days ago)"
        }
    } else {
        Write-Ok "No stale memories"
    }

    Write-Host ""
    if ($lowCon.Count -gt 0) {
        Write-Warn "$($lowCon.Count) low-confidence memory/memories (< 0.50):"
        foreach ($l in $lowCon) {
            Write-Host "    • $($l.path) — confidence $($l.confidence)"
        }
    } else {
        Write-Ok "No low-confidence memories"
    }

    if ($stale.Count -eq 0 -and $lowCon.Count -eq 0) {
        Write-Host ""
        Write-Ok "Memory audit complete — all memories healthy"
        exit 0
    }

    if ($OpenPR -and -not $DryRun -and $stale.Count -gt 0) {
        $defaultBranch = Get-DefaultBranch
        $branch        = "memory-audit/deprecate-$(Get-Date -Format 'yyyyMMdd')"
        Write-Host ""
        Write-Step "Opening deprecation PR for $($stale.Count) stale memories..."
        Create-Branch $branch $defaultBranch

        foreach ($s in $stale) {
            $content        = Get-MemoryContent $s.path
            $fm             = Parse-Frontmatter $content
            $deprecatedPath = $s.path -replace '^memories/', 'deprecated/'
            $note           = "`n`n---`n`n> **Deprecated** $(Get-Date -Format 'yyyy-MM-dd') — not validated in $($s.age) days. See [audit workflow]."
            $sha            = Get-MemoryFileSha $s.path

            # Delete original
            $delPayload = @{ message = "chore(memory): deprecate $($s.path)"; sha = $sha; branch = $branch } |
                ConvertTo-Json -Compress
            $null = $delPayload | gh api "repos/$SharedRepo/contents/$($s.path)" --method DELETE --input - 2>&1

            # Create in deprecated/
            Push-File $deprecatedPath ($content + $note) $branch "chore(memory): archive $($s.subject)" $null
        }

        $prBody = "## Memory Audit — Stale Deprecations`n`n$($stale.Count) memories have not been validated in $StaleAfterDays+ days.`n`n$(($stale | ForEach-Object { "- ``$($_.subject)`` — $($_.age) days old" }) -join "`n")`n`nThese have been moved to ``deprecated/``. Review and either restore with updated evidence or merge to confirm deprecation."
        $url = Open-PR "chore(memory): deprecate $($stale.Count) stale memories" $defaultBranch $branch $prBody
        Write-Host ""
        Write-Ok "Deprecation PR opened: $url"
    }

    exit 0
}

# ── Update mode ───────────────────────────────────────────────────────────────

if ($Update) {
    if (-not $Subject -or -not $Evidence) {
        Write-Err "-Subject and -Evidence are required for -Update"; exit 1
    }

    Assert-SharedRepo
    Assert-GhAuth

    $domain  = $Subject.Split(':')[0]
    $key     = $Subject.Split(':')[1]
    $path    = "memories/$domain/$key.md"
    $today   = Get-Date -Format "yyyy-MM-dd"

    Write-Host ""
    Write-Host "  Updating memory: $Subject" -ForegroundColor White
    Write-Step "Path: $path"

    $content = Get-MemoryContent $path
    $sha     = Get-MemoryFileSha $path

    # Update last_validated in frontmatter
    $updated = $content -replace '(last_validated:\s*")[^"]*(")', "`${1}$today`${2}"
    if ($updated -eq $content) {
        # No existing last_validated — insert after 'created' line
        $updated = $content -replace '(created:\s*"[^"]*")', "`$1`nlast_validated: `"$today`""
    }

    # Append evidence
    $updated = $updated -replace '(## Evidence)', "`$1`n- $today`: $Evidence"

    if ($DryRun) {
        Write-Warn "DryRun — would write:"
        Write-Host $updated
        exit 0
    }

    $defaultBranch = Get-DefaultBranch
    $branch        = "memory-update/$domain-$key-$today"
    Create-Branch $branch $defaultBranch
    Push-File $path $updated $branch "feat(memory): update evidence for $Subject" $sha

    $url = Open-PR "feat(memory): update $Subject" $defaultBranch $branch "Updated evidence for ``$Subject``.`n`n**New evidence:** $Evidence`n`n**Updated:** last_validated → $today"
    Write-Host ""
    Write-Ok "Update PR opened: $url"
    exit 0
}

# ── Purge mode ────────────────────────────────────────────────────────────────

if ($Purge) {
    if (-not $Subject -or -not $Reason) {
        Write-Err "-Subject and -Reason are required for -Purge"; exit 1
    }

    Assert-SharedRepo
    Assert-GhAuth

    $domain  = $Subject.Split(':')[0]
    $key     = $Subject.Split(':')[1]
    $path    = "memories/$domain/$key.md"
    $depPath = "deprecated/$domain/$key.md"
    $today   = Get-Date -Format "yyyy-MM-dd"

    Write-Host ""
    Write-Host "  Purging memory: $Subject" -ForegroundColor White
    Write-Step "Moving: $path → $depPath"
    Write-Step "Reason: $Reason"

    $content = Get-MemoryContent $path
    $sha     = Get-MemoryFileSha $path
    $note    = "`n`n---`n`n> **Deprecated** $today — $Reason"

    if ($DryRun) {
        Write-Warn "DryRun — would move $path to $depPath with note: $note"
        exit 0
    }

    $defaultBranch = Get-DefaultBranch
    $branch        = "memory-purge/$domain-$key-$today"
    Create-Branch $branch $defaultBranch

    # Write to deprecated/
    Push-File $depPath ($content + $note) $branch "chore(memory): deprecate $Subject" $null

    # Delete from memories/
    $delPayload = @{ message = "chore(memory): remove $path (deprecated)"; sha = $sha; branch = $branch } |
        ConvertTo-Json -Compress
    $null = $delPayload | gh api "repos/$SharedRepo/contents/$path" --method DELETE --input - 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Warn "Could not delete original file — may need manual cleanup" }

    $url = Open-PR "chore(memory): deprecate $Subject" $defaultBranch $branch "Deprecating ``$Subject``.`n`n**Reason:** $Reason`n`nMemory moved to ``$depPath``."
    Write-Host ""
    Write-Ok "Purge PR opened: $url"
    exit 0
}

Write-Err "No mode specified. Use -Validate, -Audit, -Update, or -Purge."
Write-Host "  Run: Get-Help scripts/audit-memories.ps1"
exit 1

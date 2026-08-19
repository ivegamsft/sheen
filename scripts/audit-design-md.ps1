#!/usr/bin/env pwsh
# audit-design-md.ps1 — Audit sheen consumer repos for DESIGN.md status
#
# Scans an org (or explicit list) for repos that have synced sheen
# (.sheen/manifest.json) and reports whether each has a DESIGN.md, its
# token structure health, and whether it is current with upstream.
#
# Usage:
#   pwsh scripts/audit-design-md.ps1 -Org IBuySpy-Dev
#   pwsh scripts/audit-design-md.ps1 -Repos "owner/repo1,owner/repo2"
#   pwsh scripts/audit-design-md.ps1 -Org IBuySpy-Dev -Out audit-report.md
#   pwsh scripts/audit-design-md.ps1 -Org IBuySpy-Dev -GenerateMissing

param(
    # GitHub org to scan (all non-archived repos)
    [string]$Org = '',
    # Explicit comma-separated list of owner/repo (overrides -Org)
    [string]$Repos = '',
    # Write markdown report to file (defaults to stdout)
    [string]$Out = '',
    # For repos missing DESIGN.md: open a PR via the generate-design-md workflow
    [switch]$GenerateMissing,
    # Sheen ref to generate against (used with -GenerateMissing)
    [string]$SheenRef = 'main'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'gh CLI is required (https://cli.github.com)' }

# ── Collect repos ─────────────────────────────────────────────────────────────
$repoList = @()
if ($Repos) {
    $repoList = $Repos -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
} elseif ($Org) {
    Write-Host "audit-design-md: discovering repos in org '$Org' …"
    $repoList = @(gh api "orgs/$Org/repos?per_page=100&type=all" --paginate --jq '.[].full_name' 2>&1 |
        Where-Object { $_ -and $_ -notmatch '^gh:' })
    Write-Host "audit-design-md: found $($repoList.Count) repos"
} else {
    throw 'Provide -Org <org> or -Repos <owner/repo,...>'
}

if ($repoList.Count -eq 0) { throw 'No repos to audit' }

# ── Audit each repo ───────────────────────────────────────────────────────────
$results = @()

foreach ($repo in $repoList) {
    $row = [ordered]@{
        Repo          = $repo
        SheenInstalled = $false
        SheenRef      = ''
        SheenSynced   = ''
        DesignMdExists = $false
        DesignMdTheme = ''
        TokensExist   = $false
        TokenTiers    = ''
        Status        = ''
        Notes         = ''
    }

    # Check for .sheen/manifest.json
    $manifest = gh api "repos/$repo/contents/.sheen/manifest.json" --jq '.content' 2>$null
    if (-not $manifest -or $manifest -match '^gh:') {
        $row.Status = 'NOT_CONSUMER'
        $row.Notes  = 'No .sheen/manifest.json — not a sheen consumer'
        $results += $row
        continue
    }

    $row.SheenInstalled = $true
    try {
        $clean = ($manifest -replace '\s','')
        $bytes = [System.Convert]::FromBase64String($clean)
        $mj = [System.Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-Json
        $row.SheenRef    = if ($mj.ref) { $mj.ref } else { 'unknown' }
        $row.SheenSynced = if ($mj.synced) { $mj.synced.Substring(0,10) } else { '' }
    } catch { $row.Notes = "manifest parse error: $($_.Exception.Message)" }

    # Check for DESIGN.md
    $designContent = gh api "repos/$repo/contents/DESIGN.md" --jq '.content' 2>$null
    if ($designContent -and $designContent -notmatch '^gh:') {
        $row.DesignMdExists = $true
        try {
            $bytes = [System.Convert]::FromBase64String(($designContent -replace '\s',''))
            $text  = [System.Text.Encoding]::UTF8.GetString($bytes)
            # Extract theme from YAML front matter
            if ($text -match 'theme:\s*(\S+)') { $row.DesignMdTheme = $Matches[1] }
        } catch { }
    }

    # Check for sheen/tokens/
    $tokensExist = gh api "repos/$repo/contents/sheen/tokens" --jq 'length' 2>$null
    if ($tokensExist -and $tokensExist -notmatch '^gh:' -and [int]$tokensExist -gt 0) {
        $row.TokensExist = $true
        # Check which tiers exist
        $tiers = @()
        foreach ($tier in @('core','semantic','themes')) {
            $check = gh api "repos/$repo/contents/sheen/tokens/$tier" --jq 'length' 2>$null
            if ($check -and $check -notmatch '^gh:' -and [int]$check -gt 0) { $tiers += $tier }
        }
        $row.TokenTiers = $tiers -join ', '
    }

    # Set overall status
    if (-not $row.DesignMdExists -and $row.TokensExist) {
        $row.Status = 'MISSING_DESIGN_MD'
        $row.Notes  = 'Tokens present — can generate DESIGN.md'
    } elseif (-not $row.DesignMdExists -and -not $row.TokensExist) {
        $row.Status = 'NO_TOKENS'
        $row.Notes  = 'No sheen/tokens/ — run materialize_tokens or sync tokens'
    } elseif ($row.DesignMdExists) {
        $row.Status = 'OK'
    }

    $results += $row
}

# ── Generate missing DESIGN.md via workflow dispatch ──────────────────────────
$generated = @()
if ($GenerateMissing) {
    $missing = $results | Where-Object { $_.Status -eq 'MISSING_DESIGN_MD' }
    if ($missing.Count -eq 0) {
        Write-Host "audit-design-md: no repos need DESIGN.md generation"
    } else {
        Write-Host "audit-design-md: dispatching generate-design-md workflow for $($missing.Count) repo(s)…"
        foreach ($row in $missing) {
            $result = gh workflow run generate-design-md-callable.yml `
                --repo IBuySpy-Shared/basecoat-sheen `
                --field "target_repo=$($row.Repo)" `
                --field "sheen_ref=$SheenRef" 2>&1
            if ($LASTEXITCODE -eq 0) {
                $generated += $row.Repo
                Write-Host "  dispatched: $($row.Repo)"
            } else {
                Write-Warning "  dispatch failed for $($row.Repo): $result"
            }
        }
    }
}

# ── Build markdown report ─────────────────────────────────────────────────────
$date = (Get-Date -Format 'yyyy-MM-dd HH:mm UTC')
$consumers = @($results | Where-Object { $_.SheenInstalled })
$ok        = @($results | Where-Object { $_.Status -eq 'OK' })
$missing   = @($results | Where-Object { $_.Status -eq 'MISSING_DESIGN_MD' })
$noTokens  = @($results | Where-Object { $_.Status -eq 'NO_TOKENS' })
$notConsumer = @($results | Where-Object { $_.Status -eq 'NOT_CONSUMER' })

$report = @"
# DESIGN.md Audit Report

Generated: $date  
Scope: $($repoList.Count) repo(s) scanned$(if ($Org) { " in **$Org**" })

## Summary

| Status | Count |
|--------|-------|
| ✅ Has DESIGN.md | $($ok.Count) |
| ⚠️ Missing DESIGN.md (tokens present) | $($missing.Count) |
| ❌ No tokens (cannot generate) | $($noTokens.Count) |
| — Not a sheen consumer | $($notConsumer.Count) |

$(if ($generated.Count -gt 0) { "**$($generated.Count) DESIGN.md workflow(s) dispatched** — PRs will open shortly." })

---

## Sheen Consumer Repos

$(if ($consumers.Count -eq 0) { "_No sheen consumers found._" } else {
@"
| Repo | Sheen Ref | Synced | DESIGN.md | Theme | Tokens | Status |
|------|-----------|--------|-----------|-------|--------|--------|
$(($consumers | ForEach-Object {
    $designMd = if ($_.DesignMdExists) { '✅' } else { '❌' }
    $tokens   = if ($_.TokensExist)    { "✅ ($($_.TokenTiers))" } else { '❌' }
    $statusIcon = switch ($_.Status) {
        'OK'                { '✅ OK' }
        'MISSING_DESIGN_MD' { '⚠️ Missing DESIGN.md' }
        'NO_TOKENS'         { '❌ No tokens' }
        default             { $_.Status }
    }
    "| ``$($_.Repo)`` | ``$($_.SheenRef)`` | $($_.SheenSynced) | $designMd | $($_.DesignMdTheme) | $tokens | $statusIcon |"
}) -join "`n")
"@
})

---

## Repos Missing DESIGN.md

$(if ($missing.Count -eq 0) { "_None — all consumer repos with tokens have DESIGN.md._" } else {
"These repos have sheen tokens but no `DESIGN.md`. Generate with:

\`\`\`powershell
# Generate for all missing repos
pwsh scripts/audit-design-md.ps1 $(if ($Org) { "-Org $Org" } else { "-Repos '$($missing.Repo -join ',')''" }) -GenerateMissing

# Or generate individually (run from within each consumer repo)
pwsh scripts/build-design-md.ps1
\`\`\`

| Repo | Sheen Ref | Token Tiers |
|------|-----------|-------------|
$(($missing | ForEach-Object {
    "| ``$($_.Repo)`` | ``$($_.SheenRef)`` | $($_.TokenTiers) |"
}) -join "`n")
"
})

---

## Not Sheen Consumers

$(if ($notConsumer.Count -eq 0) { "_All scanned repos are sheen consumers._" } else {
"These repos have no `.sheen/manifest.json` and are not sheen consumers:
$(($notConsumer | ForEach-Object { "- ``$($_.Repo)``" }) -join "`n")
"
})

---

_Generated by `scripts/audit-design-md.ps1`. Re-run to refresh._
"@

# ── Output ────────────────────────────────────────────────────────────────────
if ($Out) {
    Set-Content -LiteralPath $Out -Value $report -Encoding utf8
    Write-Host "audit-design-md: report written to $Out"
} else {
    Write-Output $report
}

# Print summary to stderr so it's always visible regardless of -Out
Write-Host "audit-design-md: $($repoList.Count) scanned | $($consumers.Count) consumers | $($ok.Count) OK | $($missing.Count) missing DESIGN.md | $($noTokens.Count) no tokens" -ForegroundColor Cyan

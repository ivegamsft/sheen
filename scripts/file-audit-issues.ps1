#!/usr/bin/env pwsh
# file-audit-issues.ps1 — files/updates GitHub issues from an
# audit-skills-agents.ps1 findings report (#131).
#
# Deduplicates using a stable per-finding fingerprint (the 'id' field
# already computed by audit-skills-agents.ps1 — a SHA-256 hash of
# "category|target|message") embedded as a hidden HTML-comment marker in
# the issue body. Re-running this script is idempotent: existing open
# issues for still-open findings are left alone, issues for findings that
# no longer appear in the report are auto-closed, and only genuinely new
# findings get a new issue.
#
# Usage:
#   pwsh scripts/file-audit-issues.ps1 -FindingsPath dist/audit/skills-agents-findings.json [-DryRun] [-MinSeverity warning]
#
# Requires: gh CLI authenticated against the target repo.

param(
    [string]$FindingsPath = 'dist/audit/skills-agents-findings.json',
    [string]$Repo = '',
    [ValidateSet('error', 'warning')]
    [string]$MinSeverity = 'warning',
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'eval-routing-lib.ps1')
$repoRoot = Get-RepoRoot -Start $PSScriptRoot

$fullPath = if ([System.IO.Path]::IsPathRooted($FindingsPath)) { $FindingsPath } else { Join-Path $repoRoot $FindingsPath }
if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "Findings report not found: $fullPath. Run scripts/audit-skills-agents.ps1 first."
}

if (-not $Repo) {
    $Repo = (gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>$null)
    if (-not $Repo) { throw "Could not resolve target repo; pass -Repo owner/repo explicitly." }
}

$report = Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
$severityRank = @{ warning = 0; error = 1 }
$minRank = $severityRank[$MinSeverity]
$findings = @($report.findings | Where-Object { $severityRank[$_.severity] -ge $minRank })

$label = 'skills-agents-audit'
$existingLabels = gh label list --repo $Repo --json name --jq '.[].name' 2>$null
if ($existingLabels -notcontains $label) {
    if ($DryRun) {
        Write-Host "[dry-run] would create label '$label'"
    } else {
        gh label create $label --repo $Repo --color 'B60205' --description 'Findings from scripts/audit-skills-agents.ps1' 2>$null | Out-Null
    }
}

# Pull all open issues carrying our label, and extract each one's marker.
$openIssues = gh issue list --repo $Repo --label $label --state open --limit 200 --json number,title,body 2>$null | ConvertFrom-Json
$markerPattern = '<!-- audit-fingerprint:\s*([0-9a-f]{16})\s*-->'
$openByFingerprint = @{}
foreach ($issue in @($openIssues)) {
    if ($issue.body -match $markerPattern) {
        $openByFingerprint[$Matches[1]] = $issue
    }
}

$created = 0
$skipped = 0
$closed = 0

$currentFingerprints = [System.Collections.Generic.HashSet[string]]::new()
foreach ($finding in $findings) {
    [void]$currentFingerprints.Add($finding.id)
    if ($openByFingerprint.ContainsKey($finding.id)) {
        $skipped++
        continue
    }

    $title = "[skills-audit] $($finding.category): $($finding.target)"
    $body = @"
$($finding.message)

- **Severity**: $($finding.severity)
- **Category**: $($finding.category)
- **Target**: ``$($finding.target)``

Filed automatically by ``scripts/file-audit-issues.ps1`` from a
``scripts/audit-skills-agents.ps1`` run (#131). Re-running the audit after a
fix closes this issue automatically once the finding no longer appears.

<!-- audit-fingerprint: $($finding.id) -->
"@

    if ($DryRun) {
        Write-Host "[dry-run] would create issue: $title"
        $created++
        continue
    }

    $severityLabel = if ($finding.severity -eq 'error') { 'bug' } else { 'enhancement' }
    $bodyFile = [System.IO.Path]::GetTempFileName()
    Set-Content -LiteralPath $bodyFile -Value $body -Encoding UTF8
    try {
        gh issue create --repo $Repo --title $title --label $label --label $severityLabel --body-file $bodyFile | Out-Null
        $created++
    } finally {
        Remove-Item -LiteralPath $bodyFile -Force -ErrorAction SilentlyContinue
    }
}

# Auto-close issues whose finding no longer appears in the current report.
foreach ($fingerprint in $openByFingerprint.Keys) {
    if ($currentFingerprints.Contains($fingerprint)) { continue }
    $issue = $openByFingerprint[$fingerprint]
    if ($DryRun) {
        Write-Host "[dry-run] would close resolved issue #$($issue.number): $($issue.title)"
        $closed++
        continue
    }
    gh issue close $issue.number --repo $Repo --comment "Finding no longer present in the latest scripts/audit-skills-agents.ps1 run — auto-closed by scripts/file-audit-issues.ps1." | Out-Null
    $closed++
}

Write-Host "file-audit-issues: $created created, $skipped already open, $closed auto-closed (of $($findings.Count) findings at or above severity '$MinSeverity')."

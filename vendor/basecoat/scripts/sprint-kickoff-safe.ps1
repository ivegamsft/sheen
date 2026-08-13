#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Sprint kickoff script that enforces 4-agent concurrency limit for cloud-agent workflows.

.DESCRIPTION
  This script processes issue assignments in batches of 4 (MAX_CONCURRENT_AGENTS)
  to prevent GitHub API rate limiting and agent workflow saturation.

  Phase 2 implementation for Issue #451: Implement 4-agent concurrency limit for Copilot cloud agents.

.PARAMETER IssueNumbers
  Comma-separated list of GitHub issue numbers to approve (e.g., "444,446,448,450,451")

.PARAMETER WaveSize
  Number of agents to assign concurrently (default: 4). Must be >= 1 and <= 10.

.PARAMETER InterWaveDelay
  Delay in seconds between waves (default: 120). Allows agents to start processing before next batch.

.PARAMETER RateLimitBuffer
  Minimum API requests to keep available before pausing (default: 200).

.EXAMPLE
  # Approve 12 issues in 3 waves of 4
  .\scripts\sprint-kickoff-safe.ps1 -IssueNumbers "444,446,448,450,451,453,455,457,459,461,463,465"

.EXAMPLE
  # Custom wave size: 6 agents per wave, 180s between waves
  .\scripts\sprint-kickoff-safe.ps1 -IssueNumbers "444,446,448,450" -WaveSize 6 -InterWaveDelay 180

#>
param(
  [Parameter(Mandatory = $true)]
  [string]$IssueNumbers,

  [ValidateRange(1, 10)]
  [int]$WaveSize = 4,

  [ValidateRange(30, 600)]
  [int]$InterWaveDelay = 120,

  [ValidateRange(50, 500)]
  [int]$RateLimitBuffer = 200
)

# Require gh CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Error "gh CLI not found. Install from https://cli.github.com/"
  exit 1
}

Write-Host "Sprint Kickoff — 4-Agent Concurrency Mode" -ForegroundColor Cyan
Write-Host ("Wave Size: {0}, Inter-Wave Delay: {1}s, Rate Limit Buffer: {2}" -f $WaveSize, $InterWaveDelay, $RateLimitBuffer)
Write-Host ""

# Parse issue numbers
$issues = $IssueNumbers -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
if ($issues.Count -eq 0) {
  Write-Error "No valid issue numbers provided"
  exit 1
}

Write-Host ("Preparing to approve {0} issues in {1} wave(s)" -f $issues.Count, [Math]::Ceiling($issues.Count / $WaveSize))
Write-Host ""

# Function: Check rate limit and wait if necessary
function Assert-RateLimitAvailable {
  param(
    [int]$MinimumAvailable = $RateLimitBuffer
  )

  $rateLimit = gh api rate_limit --jq '.rate | {limit: .limit, remaining: .remaining, reset: .reset}' 2>$null | ConvertFrom-Json
  if ($null -eq $rateLimit) {
    Write-Warning "Could not fetch rate limit status; proceeding with caution"
    return
  }

  $remaining = $rateLimit.remaining
  $resetTime = [datetime]::UnixEpoch.AddSeconds($rateLimit.reset)
  $resetIn = ($resetTime - (Get-Date)).TotalSeconds

  Write-Host ("Rate Limit: {0}/{1} remaining" -f $remaining, $rateLimit.limit) -ForegroundColor Gray

  if ($remaining -le $MinimumAvailable) {
    Write-Host "Rate limit critical! Waiting for reset..." -ForegroundColor Yellow
    $waitSeconds = [Math]::Min([Math]::Ceiling($resetIn) + 5, 3600)  # Cap at 1 hour
    Write-Host ("Sleeping {0} seconds until reset at {1:HH:mm:ss} UTC" -f $waitSeconds, $resetTime)
    Start-Sleep -Seconds $waitSeconds
    Write-Host "Reset complete; resuming..." -ForegroundColor Green
  }
}

# Function: Approve single issue with error handling
function Approve-Issue {
  param(
    [string]$IssueNumber
  )

  try {
    Write-Host "  → Approving issue #$IssueNumber..." -NoNewline
    gh issue comment $IssueNumber --body "/approve" 2>$null | Out-Null
    Write-Host " ✓" -ForegroundColor Green
    return $true
  }
  catch {
    Write-Host " ✗ (Error: $_)" -ForegroundColor Red
    return $false
  }
}

# Main loop: Process issues in waves
$waveNumber = 1
$succeededCount = 0
$failedCount = 0

for ($i = 0; $i -lt $issues.Count; $i += $WaveSize) {
  $wave = $issues[$i..([Math]::Min($i + $WaveSize - 1, $issues.Count - 1))]

  Write-Host ("Wave {0}/{1}: Approving issues {2}..." -f $waveNumber, [Math]::Ceiling($issues.Count / $WaveSize), ($wave -join ', '))

  # Check rate limit before wave
  Assert-RateLimitAvailable -MinimumAvailable $RateLimitBuffer

  # Approve all issues in this wave (spacing by 3 seconds to avoid thundering herd)
  foreach ($issue in $wave) {
    if (Approve-Issue $issue) {
      $succeededCount++
    }
    else {
      $failedCount++
    }
    # Space out requests within wave
    Start-Sleep -Seconds 3
  }

  Write-Host ("  → Wave {0} complete. Agents are initializing..." -f $waveNumber)
  Write-Host ""

  # If more waves remain, wait for agents to start before assigning next batch
  if (($i + $WaveSize) -lt $issues.Count) {
    Write-Host ("Waiting {0} seconds before next wave (agents processing current batch)..." -f $InterWaveDelay) -ForegroundColor Yellow
    $remaining = $InterWaveDelay
    while ($remaining -gt 0) {
      Write-Host -NoNewline ("`rWaiting {0:D2} seconds..." -f $remaining)
      Start-Sleep -Seconds 1
      $remaining--
    }
    Write-Host "`r                       " # Clear line
    Write-Host ""
  }

  $waveNumber++
}

# Summary
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ("Kickoff Complete: {0} approved, {1} failed" -f $succeededCount, $failedCount) -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:"
Write-Host "  1. Monitor agent workflows: gh workflow list"
Write-Host "  2. Check issue progress: gh issue list --label approved"
Write-Host "  3. Track API usage: gh api rate_limit --jq '.rate'"
Write-Host ""

if ($failedCount -gt 0) {
  exit 1
}

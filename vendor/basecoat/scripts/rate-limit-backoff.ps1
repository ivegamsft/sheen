#!/usr/bin/env pwsh
# rate-limit-backoff.ps1 — GitHub API rate-limit backoff implementation and utilities
#
# Usage:
#   . ./scripts/rate-limit-backoff.ps1
#   $result = Invoke-WithExponentialBackoff { gh api repos/owner/repo }
#
# Functions:
#   - Invoke-WithExponentialBackoff: Execute action with exponential backoff on failure
#   - Get-GitHubRateLimit: Fetch and display current rate limit status
#   - Assert-RateLimitAvailable: Halt if rate limit < threshold

<#
.SYNOPSIS
    Executes an action with exponential backoff retry logic.

.DESCRIPTION
    Implements exponential backoff for API calls or other operations that may fail temporarily.
    Initial delay starts at 30 seconds, increases by 1.5x multiplier each retry, capped at 90 seconds.
    Logs each retry attempt and final status.

.PARAMETER Action
    ScriptBlock to execute. Should throw on failure to trigger retry.

.PARAMETER MaxAttempts
    Maximum number of retry attempts (default: 5). Total attempts = MaxAttempts + 1 initial.

.PARAMETER InitialDelaySeconds
    Initial delay in seconds before first retry (default: 30).

.PARAMETER Multiplier
    Backoff multiplier applied each retry (default: 1.5).

.PARAMETER MaxDelaySeconds
    Maximum delay capped at this value (default: 90).

.EXAMPLE
    $result = Invoke-WithExponentialBackoff {
        gh api repos/owner/repo --jq '.name'
    }

.EXAMPLE
    Invoke-WithExponentialBackoff -Action { gh workflow run test.yml } -MaxAttempts 3

#>
function Invoke-WithExponentialBackoff {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,

        [int]$MaxAttempts = 5,

        [int]$InitialDelaySeconds = 30,

        [decimal]$Multiplier = 1.5,

        [int]$MaxDelaySeconds = 90
    )

    $attempt = 0

    while ($true) {
        $attempt++

        try {
            Write-Verbose "Attempt $attempt of $($MaxAttempts + 1): Executing action..."
            return & $Action
        }
        catch {
            if ($attempt -gt $MaxAttempts) {
                Write-Error "Max attempts ($MaxAttempts) exceeded. Final error: $_"
                throw
            }

            $delay = [math]::Min(
                $InitialDelaySeconds * [math]::Pow($Multiplier, $attempt - 1),
                $MaxDelaySeconds
            )

            Write-Warning "Attempt $attempt failed: $_`nWaiting $($delay)s before retry..."
            Start-Sleep -Seconds $delay
        }
    }
}

<#
.SYNOPSIS
    Fetches and displays current GitHub API rate limit status.

.DESCRIPTION
    Queries the GitHub API rate limit endpoint and displays:
    - Current remaining requests
    - Total limit
    - Time until reset
    - Percentage consumed

.EXAMPLE
    Get-GitHubRateLimit

.EXAMPLE
    Get-GitHubRateLimit | ConvertTo-Json

#>
function Get-GitHubRateLimit {
    [CmdletBinding()]
    param()

    try {
        $rate = gh api rate_limit --jq '.rate' 2>$null | ConvertFrom-Json

        $resetTime = [DateTime]::UnixEpoch.AddSeconds($rate.reset)
        $percentUsed = [math]::Round(($rate.used / $rate.limit) * 100, 2)

        return @{
            Limit      = $rate.limit
            Used       = $rate.used
            Remaining  = $rate.remaining
            ResetTime  = $resetTime
            PercentUsed = $percentUsed
            Status     = if ($rate.remaining -lt 50) { "CRITICAL" }
                         elseif ($rate.remaining -lt 200) { "WARNING" }
                         else { "OK" }
        }
    }
    catch {
        Write-Error "Failed to fetch rate limit: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Displays rate limit status in human-readable format.

.DESCRIPTION
    Queries and formats rate limit information with color coding:
    - GREEN: > 200 remaining
    - YELLOW: 50–200 remaining
    - RED: < 50 remaining (critical)

.EXAMPLE
    Show-GitHubRateLimitStatus

#>
function Show-GitHubRateLimitStatus {
    [CmdletBinding()]
    param()

    $rate = Get-GitHubRateLimit

    if ($null -eq $rate) {
        return
    }

    $color = switch ($rate.Status) {
        'CRITICAL' { 'Red' }
        'WARNING'  { 'Yellow' }
        'OK'       { 'Green' }
    }

    Write-Host "GitHub API Rate Limit Status:" -ForegroundColor Cyan
    Write-Host "  Status:    " -NoNewline
    Write-Host $rate.Status -ForegroundColor $color
    Write-Host "  Remaining: $($rate.Remaining) / $($rate.Limit)"
    Write-Host "  Used:      $($rate.Used) ($($rate.PercentUsed)%)"
    Write-Host "  Resets:    $($rate.ResetTime)"
}

<#
.SYNOPSIS
    Asserts that sufficient rate limit quota is available.

.DESCRIPTION
    Checks if remaining quota exceeds threshold. If not, waits until reset or raises error.
    Useful as a guard before batch operations.

.PARAMETER Threshold
    Minimum remaining requests required (default: 50). Raises error if below this.

.PARAMETER WaitUntilReset
    If $true, waits until rate limit resets instead of raising error (default: $false).

.EXAMPLE
    Assert-RateLimitAvailable -Threshold 100

.EXAMPLE
    Assert-RateLimitAvailable -Threshold 50 -WaitUntilReset $true

#>
function Assert-RateLimitAvailable {
    [CmdletBinding()]
    param(
        [int]$Threshold = 50,

        [bool]$WaitUntilReset = $false
    )

    $rate = Get-GitHubRateLimit

    if ($null -eq $rate) {
        Write-Error "Failed to check rate limit"
        return $false
    }

    if ($rate.Remaining -lt $Threshold) {
        if ($WaitUntilReset) {
            $waitSeconds = [math]::Max(0, ($rate.ResetTime - [DateTime]::UtcNow).TotalSeconds + 5)
            Write-Warning "Rate limit below threshold ($($rate.Remaining) < $Threshold). Waiting $([math]::Round($waitSeconds))s for reset..."
            Start-Sleep -Seconds $waitSeconds
            return $true
        }
        else {
            Write-Error "Insufficient rate limit quota: $($rate.Remaining) < $Threshold. Resets at $($rate.ResetTime)"
            return $false
        }
    }

    Write-Verbose "Rate limit check passed: $($rate.Remaining) / $($rate.Limit) remaining"
    return $true
}

<#
.SYNOPSIS
    Safely dispatches GitHub workflows with rate limit awareness.

.DESCRIPTION
    Wraps `gh workflow run` with backoff and rate limit checks.
    Enforces 60+ second spacing between dispatches to prevent quota exhaustion.

.PARAMETER Workflow
    Workflow file name or ID (e.g., 'ci.yml').

.PARAMETER Ref
    Branch reference (default: 'main').

.PARAMETER Inputs
    Optional workflow input parameters as hashtable.

.EXAMPLE
    Invoke-WorkflowDispatchSafe -Workflow ci.yml -Ref main

.EXAMPLE
    $workflows = @('test.yml', 'build.yml')
    $workflows | ForEach-Object { Invoke-WorkflowDispatchSafe $_ }

#>
function Invoke-WorkflowDispatchSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Workflow,

        [string]$Ref = 'main',

        [hashtable]$Inputs = @{}
    )

    process {
        Assert-RateLimitAvailable -Threshold 50 | Out-Null

        Write-Host "Dispatching workflow: $Workflow (ref: $Ref)"

        Invoke-WithExponentialBackoff {
            $args = @('workflow', 'run', $Workflow, '--ref', $Ref)

            if ($Inputs.Count -gt 0) {
                $Inputs.GetEnumerator() | ForEach-Object {
                    $args += '--input'
                    $args += "$($_.Key)=$($_.Value)"
                }
            }

            & gh @args
        }

        Write-Verbose "Workflow dispatch complete. Respecting 60s spacing before next operation..."
        Start-Sleep -Seconds 60
    }
}

<#
.SYNOPSIS
    Processes a batch of operations with rate limit safety.

.DESCRIPTION
    Executes operations in batches, respecting rate limit thresholds and spacing.
    Ideal for bulk issue creation, label assignments, or workflow dispatches.

.PARAMETER Operations
    Array of ScriptBlocks to execute.

.PARAMETER BatchSize
    Operations per batch (default: 5).

.PARAMETER BatchIntervalSeconds
    Wait time between batches (default: 60).

.EXAMPLE
    $ops = @(
        { gh workflow run test.yml },
        { gh workflow run build.yml },
        { gh workflow run deploy.yml }
    )
    Invoke-BatchOperations -Operations $ops -BatchSize 2

#>
function Invoke-BatchOperations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock[]]$Operations,

        [int]$BatchSize = 5,

        [int]$BatchIntervalSeconds = 60
    )

    $totalOps = $Operations.Count
    $totalBatches = [math]::Ceiling($totalOps / $BatchSize)

    Write-Host "Processing $totalOps operations in $totalBatches batches of $BatchSize..."

    for ($i = 0; $i -lt $totalOps; $i += $BatchSize) {
        $batchNum = [math]::Floor($i / $BatchSize) + 1
        $batchEnd = [math]::Min($i + $BatchSize - 1, $totalOps - 1)

        Write-Host "Batch $batchNum / $totalBatches (operations $($i + 1)–$($batchEnd + 1))..."

        Assert-RateLimitAvailable -Threshold 50 | Out-Null

        for ($j = $i; $j -le $batchEnd; $j++) {
            Invoke-WithExponentialBackoff $Operations[$j]
        }

        if ($i + $BatchSize -lt $totalOps) {
            Write-Host "  Batch complete. Waiting $BatchIntervalSeconds seconds before next batch..."
            Start-Sleep -Seconds $BatchIntervalSeconds
        }
    }

    Write-Host "All batches complete."
}

# Export functions
Export-ModuleMember -Function @(
    'Invoke-WithExponentialBackoff',
    'Get-GitHubRateLimit',
    'Show-GitHubRateLimitStatus',
    'Assert-RateLimitAvailable',
    'Invoke-WorkflowDispatchSafe',
    'Invoke-BatchOperations'
)

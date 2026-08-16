<#
.SYNOPSIS
CI gate for skill and agent routing eval.yaml files.

Validates the simple eval schema used by this repo, checks referenced SKILL.md/agent files,
requires at least three positive and two negative scenarios, and fails any eval whose audit
specificity score is below the configured threshold (default 7.0).
#>
param([double]$MinimumScore = 7.0)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'eval-routing-lib.ps1')

$repoRoot = Get-RepoRoot -Start $PSScriptRoot
$results = Invoke-EvalAudit -RepoRoot $repoRoot -MinimumScore $MinimumScore
$failures = [System.Collections.Generic.List[string]]::new()
$totalScenarios = 0

foreach ($result in $results) {
    $totalScenarios += $result.scenario_count
    foreach ($error in $result.parse_errors) { $failures.Add("$($result.path): $error") }
    if (-not $result.target_exists) { $failures.Add("$($result.path): referenced file '$($result.target)' does not exist") }
    if ($result.scenario_count -lt 5) { $failures.Add("$($result.path): expected at least 5 scenarios (3 positive, 2 negative), found $($result.scenario_count)") }
    if ($result.positive_count -lt 3) { $failures.Add("$($result.path): expected at least 3 positive scenarios, found $($result.positive_count)") }
    if ($result.negative_count -lt 2) { $failures.Add("$($result.path): expected at least 2 negative scenarios, found $($result.negative_count)") }
    if ($result.score -lt $MinimumScore) { $failures.Add("$($result.path): specificity score $($result.score) is below $MinimumScore") }
}

Write-Host ("Routing eval files: {0}" -f @($results).Count)
Write-Host ("Routing scenarios: {0}" -f $totalScenarios)
Write-Host ("Minimum specificity score: {0:n1}" -f $MinimumScore)

if ($totalScenarios -lt 50) { $failures.Add("expected at least 50 scenarios across eval files, found $totalScenarios") }

if ($failures.Count -gt 0) {
    Write-Host 'Routing eval validation failed:'
    foreach ($failure in $failures) { Write-Host "::error::$failure" }
    exit 1
}

Write-Host 'Routing eval validation passed.'

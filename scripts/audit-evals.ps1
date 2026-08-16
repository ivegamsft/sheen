<#
.SYNOPSIS
Audits skill and agent routing eval.yaml files for scenario specificity.

.RUBRIC
Each eval receives a 0-10 specificity score:
- Positive coverage (0-2): at least three activation scenarios, with credit for four or more.
- Negative coverage (0-2): at least two non-activation scenarios, with credit for hard third negatives.
- Realistic input detail (0-2): average scenario length favors concrete user prompts over labels.
- Positive diversity (0-1.5): activation prompts must use varied, non-generic vocabulary.
- Trigger overlap (0-1.5): positive prompts should overlap meaningful terms in the referenced SKILL.md or agent file.
- Hard negatives (0-1): negatives should be adjacent-but-wrong design/routing requests, not only out-of-domain tasks.
- Boilerplate penalties (up to -2): repeated scaffold phrases like "Need help with ..." or "Use <agent> ..." reduce confidence.

The default passing threshold is 7.0. The script prints a human-readable table and writes a JSON report
(default: build/eval-audit.json; ignored by git). Use -JsonPath '' to skip writing JSON.
#>
param(
    [double]$MinimumScore = 7.0,
    [string]$JsonPath = 'build/eval-audit.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'eval-routing-lib.ps1')

$repoRoot = Get-RepoRoot -Start $PSScriptRoot
$results = Invoke-EvalAudit -RepoRoot $repoRoot -MinimumScore $MinimumScore
$total = @($results).Count
$below = @($results | Where-Object { $_.below_threshold }).Count
$scenarios = ($results | Measure-Object -Property scenario_count -Sum).Sum

$results |
    Select-Object @{Name='Score';Expression={$_.score}}, @{Name='Scenarios';Expression={$_.scenario_count}}, @{Name='Pos';Expression={$_.positive_count}}, @{Name='Neg';Expression={$_.negative_count}}, @{Name='HardNeg';Expression={$_.hard_negatives}}, Path |
    Format-Table -AutoSize

Write-Host ("Audited {0} eval files; {1} scenarios; {2} below threshold {3:n1}." -f $total, $scenarios, $below, $MinimumScore)

$report = [pscustomobject]@{
    generated_at = (Get-Date).ToUniversalTime().ToString('o')
    minimum_score = $MinimumScore
    file_count = $total
    scenario_count = $scenarios
    below_threshold_count = $below
    results = @($results)
}

if ($JsonPath -ne '') {
    $fullJsonPath = if ([System.IO.Path]::IsPathRooted($JsonPath)) { $JsonPath } else { Join-Path $repoRoot $JsonPath }
    $dir = Split-Path -Parent $fullJsonPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $fullJsonPath -Encoding UTF8
    Write-Host "JSON report: $fullJsonPath"
}

if ($below -gt 0) {
    Write-Host 'Lowest-scoring evals:'
    $results | Select-Object -First ([Math]::Min(13, $total)) | ForEach-Object {
        $note = if ($_.notes.Count -gt 0) { ' — ' + ($_.notes -join '; ') } else { '' }
        Write-Host ("- {0}: {1:n1}{2}" -f $_.path, $_.score, $note)
    }
}

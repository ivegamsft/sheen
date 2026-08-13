#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Runs BaseCoat agents and skills audits and organizes outputs by folder.

.DESCRIPTION
    Executes helper audit scripts for agents and skills, writes structured outputs
    under test-results/audits/{agents,skills}, and emits a concise roll-up summary.

.PARAMETER OutputRoot
    Root folder for organized audit outputs. Defaults to 'test-results/audits'.

.PARAMETER FailOnError
    Forward FailOnError to agent/skill audits and exit non-zero on their errors.
#>
param(
    [string]$OutputRoot = 'test-results/audits',
    [switch]$FailOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$outputRootPath = Join-Path $repoRoot $OutputRoot
$agentDir = Join-Path $outputRootPath 'agents'
$skillDir = Join-Path $outputRootPath 'skills'

foreach ($dir in @($outputRootPath, $agentDir, $skillDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

$agentAuditArgs = @(
    '-NoProfile', '-File', (Join-Path $PSScriptRoot 'audit-agents.ps1'),
    '-OutputFile', (Join-Path $OutputRoot 'agents\agent-audit.txt')
)
if ($FailOnError) { $agentAuditArgs += '-FailOnError' }
& pwsh @agentAuditArgs
$agentExitCode = $LASTEXITCODE

$skillAuditArgs = @(
    '-NoProfile', '-File', (Join-Path $PSScriptRoot 'audit-skills.ps1'),
    '-OutputFile', (Join-Path $OutputRoot 'skills\skill-audit.txt')
)
if ($FailOnError) { $skillAuditArgs += '-FailOnError' }
& pwsh @skillAuditArgs
$skillExitCode = $LASTEXITCODE

& pwsh -NoProfile -File (Join-Path $PSScriptRoot 'audit-assets.ps1') -Category agents -Format json |
    Set-Content -Path (Join-Path $agentDir 'agent-health.json') -Encoding UTF8
& pwsh -NoProfile -File (Join-Path $PSScriptRoot 'audit-assets.ps1') -Category skills -Format json |
    Set-Content -Path (Join-Path $skillDir 'skill-health.json') -Encoding UTF8

$agentHealth = Get-Content (Join-Path $agentDir 'agent-health.json') -Raw | ConvertFrom-Json
$skillHealth = Get-Content (Join-Path $skillDir 'skill-health.json') -Raw | ConvertFrom-Json

Write-Host ''
Write-Host 'Guidance audit summary' -ForegroundColor Cyan
Write-Host "  Agents: avg $($agentHealth.avgScore)/10, red=$($agentHealth.red), yellow=$($agentHealth.yellow), green=$($agentHealth.green)"
Write-Host "  Skills: avg $($skillHealth.avgScore)/10, red=$($skillHealth.red), yellow=$($skillHealth.yellow), green=$($skillHealth.green)"
Write-Host "  Reports: $OutputRoot\agents and $OutputRoot\skills"

if ($FailOnError -and ($agentExitCode -ne 0 -or $skillExitCode -ne 0)) {
    exit 1
}

exit 0

#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { throw 'Run this inside a git repository' }
Set-Location $repoRoot

$workspace = Join-Path $repoRoot '.diagnose-sheen-tests'
if (Test-Path -LiteralPath $workspace) { Remove-Item -LiteralPath $workspace -Recurse -Force }
New-Item -ItemType Directory -Force -Path $workspace | Out-Null

function Copy-Entry {
    param([string]$Source, [string]$Destination)
    $parent = Split-Path -Parent $Destination
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    if ((Get-Item -LiteralPath $Source).PSIsContainer) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
    } else {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    }
}

function New-ConsumerFixture {
    param(
        [string]$Path,
        [switch]$WithIssues
    )

    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Push-Location $Path
    try {
        git init --quiet | Out-Null
        foreach ($skillName in @('design-review','design-debate','craft-quality')) {
            Copy-Entry (Join-Path $repoRoot "skills\$skillName") (Join-Path $Path ".github\skills\$skillName")
        }
        Copy-Entry (Join-Path $repoRoot 'agents\design-reviewer.agent.md') (Join-Path $Path '.github\agents\design-reviewer.agent.md')
        Copy-Entry (Join-Path $repoRoot 'agents\design-reviewer.agent.eval.yaml') (Join-Path $Path '.github\agents\design-reviewer.agent.eval.yaml')
        Copy-Entry (Join-Path $repoRoot 'instructions\sheen-10-core-design-principles.instructions.md') (Join-Path $Path '.github\instructions\sheen-10-core-design-principles.instructions.md')
        Copy-Entry (Join-Path $repoRoot 'tokens') (Join-Path $Path 'sheen\tokens')
        New-Item -ItemType Directory -Force -Path (Join-Path $Path '.github\prompts') | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $Path 'sheen\templates') | Out-Null

        @"
source: https://example.com/basecoat-sheen.git
ref: main
skills:
  - design-review
  - design-debate
  - craft-quality
agents:
  - design-reviewer
instructions:
  - sheen-10-core-design-principles
themes:
  - light
  - dark
  - high-contrast
"@ | Set-Content -LiteralPath (Join-Path $Path '.sheen.yml') -Encoding utf8

        if ($WithIssues) {
            New-Item -ItemType Directory -Force -Path (Join-Path $Path 'vendor\basecoat\skills\design-review') | Out-Null

            $semanticPath = Join-Path $Path 'sheen\tokens\semantic\color.tokens.json'
            $semantic = Get-Content -LiteralPath $semanticPath -Raw | ConvertFrom-Json
            $semantic.color.foreground.'$value' = '{color.missing}'
            $semantic.color.muted.'$value' = '{color.foreground}'
            ($semantic | ConvertTo-Json -Depth 32) | Set-Content -LiteralPath $semanticPath -Encoding utf8

            $themePath = Join-Path $Path 'sheen\tokens\themes\light.tokens.json'
            $theme = Get-Content -LiteralPath $themePath -Raw | ConvertFrom-Json
            $theme.color.primary.'$value' = '{color.on-primary}'
            $theme.color.'on-primary'.'$value' = '{color.primary}'
            ($theme | ConvertTo-Json -Depth 32) | Set-Content -LiteralPath $themePath -Encoding utf8
        }
    }
    finally {
        Pop-Location
    }
}

function Assert-Exit {
    param([int]$Actual, [int]$Expected, [string]$Label, [string]$Output = '')
    if ($Actual -ne $Expected) {
        throw "$Label expected exit code $Expected but got $Actual`n$Output"
    }
}

function Invoke-Diagnostics {
    param([string]$Path, [string]$ScriptName, [switch]$Json, [string]$Shell = $null)
    Push-Location $Path
    try {
        $scriptPath = Join-Path $repoRoot $ScriptName
        if ($Shell) {
            $scriptPath = (Resolve-Path -LiteralPath $scriptPath).Path.Replace('\','/')
        }
        $invokeArgs = @()
        if ($Json) { $invokeArgs += '-Json' }
        if ($Shell) {
            $output = & $Shell $scriptPath @invokeArgs 2>&1
        } else {
            $output = & pwsh -NoLogo -NoProfile -File $scriptPath @invokeArgs 2>&1
        }
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join "`n") }
    }
    finally {
        Pop-Location
    }
}

try {
    $clean = Join-Path $workspace 'consumer-clean'
    $dirty = Join-Path $workspace 'consumer-dirty'
    New-ConsumerFixture -Path $clean
    New-ConsumerFixture -Path $dirty -WithIssues

    $cleanResult = Invoke-Diagnostics -Path $clean -ScriptName 'scripts\diagnose-sheen.ps1'
    Assert-Exit -Actual $cleanResult.ExitCode -Expected 0 -Label 'PowerShell clean fixture' -Output $cleanResult.Output

    $cleanJson = Invoke-Diagnostics -Path $clean -ScriptName 'scripts\diagnose-sheen.ps1' -Json
    Assert-Exit -Actual $cleanJson.ExitCode -Expected 0 -Label 'PowerShell clean fixture JSON' -Output $cleanJson.Output
    $cleanReport = $cleanJson.Output | ConvertFrom-Json
    if (-not $cleanReport.config.valid -or -not $cleanReport.tokens.valid) { throw 'PowerShell JSON report did not validate clean fixture' }

    $dirtyResult = Invoke-Diagnostics -Path $dirty -ScriptName 'scripts\diagnose-sheen.ps1'
    Assert-Exit -Actual $dirtyResult.ExitCode -Expected 1 -Label 'PowerShell dirty fixture' -Output $dirtyResult.Output
    if ($dirtyResult.Output -notmatch 'Duplicate skill name collides with vendored basecoat') {
        throw 'PowerShell dirty fixture did not report the collision'
    }
    if ($dirtyResult.Output -notmatch 'Semantic token') {
        throw 'PowerShell dirty fixture did not report token errors'
    }

    $bashAvailable = $false
    if (Get-Command bash -ErrorAction SilentlyContinue) {
        & bash --version >$null 2>$null
        $bashAvailable = ($LASTEXITCODE -eq 0)
    }
    if ($bashAvailable) {
        $cleanShell = Invoke-Diagnostics -Path $clean -ScriptName 'scripts\diagnose-sheen.sh' -Shell 'bash'
        Assert-Exit -Actual $cleanShell.ExitCode -Expected 0 -Label 'Bash clean fixture' -Output $cleanShell.Output
        $dirtyShell = Invoke-Diagnostics -Path $dirty -ScriptName 'scripts\diagnose-sheen.sh' -Shell 'bash'
        Assert-Exit -Actual $dirtyShell.ExitCode -Expected 1 -Label 'Bash dirty fixture' -Output $dirtyShell.Output
    }

    Write-Host 'diagnose-sheen self-test: OK'
}
finally {
    if (Test-Path -LiteralPath $workspace) { Remove-Item -LiteralPath $workspace -Recurse -Force }
}

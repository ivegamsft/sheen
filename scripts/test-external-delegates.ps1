# Source-shaped fixtures exercise the same registry and section-4 resolver as the audit.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'external-delegates-lib.ps1')
$root = Split-Path $PSScriptRoot
$fixture = Join-Path $root ('dist/external-delegates-' + [guid]::NewGuid().ToString('N'))
$script:assertions = 0
$script:cases = 0
function Assert-Test {
    param([bool]$Condition, [string]$Message)
    $script:assertions++
    if (-not $Condition) { throw $Message }
}
function Write-Fixture {
    param([string]$Path, [string]$Text)
    $full = Join-Path $fixture $Path
    [void][IO.Directory]::CreateDirectory((Split-Path $full))
    [IO.File]::WriteAllText($full, $Text)
}
$valid = '{"schema_version":1,"dependencies":[{"provider":"basecoat","kind":"skill","name":"frontend-dev","path":".github/skills/frontend-dev/SKILL.md"}]}'
$header = "---`nname: frontend-dev`n---`n"
$assets = @([pscustomobject]@{ path = 'skills/example/SKILL.md'; content = "## Delegates / pairs with`n- ``frontend-dev```n" })
function Get-Resolution {
    param([string[]]$LocalSkills = @(), [string[]]$LocalAgents = @())
    $registry = Get-ExternalDelegateRegistry -RepoRoot $fixture
    $result = Invoke-SourceDelegateAudit -Assets $assets -SkillNames $LocalSkills -AgentNames $LocalAgents -Registry $registry
    return [pscustomobject]@{ registry = $registry; result = $result }
}
try {
    Write-Fixture 'scripts/external-delegates.json' $valid
    Write-Fixture '.github/skills/frontend-dev/SKILL.md' $header
    Assert-Test (@(Get-ChildItem -LiteralPath (Join-Path $fixture '.github') -Recurse -File -Force).Count -eq 1) 'Hidden fixture scope must be nonempty on Linux'
    $ok = Get-Resolution
    $script:cases++
    Assert-Test ($ok.registry.diagnostics.Count -eq 0) 'Valid registry must have no diagnostics'
    Assert-Test ($ok.result.external_resolutions.Count -eq 1 -and $ok.result.findings.Count -eq 0) 'Valid declared external handoff must resolve'
    Assert-Test ($ok.result.external_resolutions[0].provider -eq 'basecoat' -and $ok.result.external_resolutions[0].kind -eq 'skill') 'Resolution must preserve provider/kind'
    Assert-Test (($ok | ConvertTo-Json -Depth 10 -Compress) -ceq ((Get-Resolution) | ConvertTo-Json -Depth 10 -Compress)) 'Results must be deterministic'
    foreach ($kind in @('skill', 'agent')) {
        $script:cases++
        $local = if ($kind -eq 'skill') { Get-Resolution -LocalSkills frontend-dev } else { Get-Resolution -LocalAgents frontend-dev }
        Assert-Test ($local.result.external_resolutions.Count -eq 0 -and $local.result.findings.Count -eq 0) "Local $kind takes precedence"
    }
    $script:cases++
    Remove-Item -LiteralPath (Join-Path $fixture '.github/skills/frontend-dev/SKILL.md')
    $missing = Get-Resolution
    Assert-Test ($missing.registry.diagnostics[0].severity -eq 'warning' -and $missing.registry.diagnostics[0].message -match 'unavailable') 'Missing target stays advisory and distinguishable'
    Assert-Test ($missing.result.findings.Count -eq 1 -and $missing.result.external_resolutions.Count -eq 0) 'Missing target cannot resolve'
    foreach ($badHeader in @("---`nname: other`n---`nname: frontend-dev", "name: frontend-dev", "---`nname: frontend-dev`nname: frontend-dev`n---", "---`nname: frontend-dev", ('x' * 40000), ("---`n" + ('x' * 40000) + "`nname: frontend-dev`n---"))) {
        $script:cases++
        Write-Fixture '.github/skills/frontend-dev/SKILL.md' $badHeader
        $bad = Get-Resolution
        Assert-Test ($bad.registry.verified.Count -eq 0 -and $bad.registry.diagnostics[0].message -match 'identity-mismatch') 'Only exact bounded frontmatter identity may resolve'
        Assert-Test ($bad.result.findings.Count -eq 1) 'Mismatched target must retain handoff warning'
    }
    Write-Fixture '.github/skills/frontend-dev/SKILL.md' $header
    $script:cases++
    Write-Fixture '.github/skills/frontend-dev/SKILL.md' "---`r`nname: `"frontend-dev`"`r`n---"
    $quoted = Get-Resolution
    Assert-Test ($quoted.registry.verified.Count -eq 1 -and $quoted.registry.diagnostics.Count -eq 0) 'Quoted identity and EOF closing delimiter must resolve'
    Write-Fixture '.github/skills/frontend-dev/SKILL.md' $header
    $script:cases++
    $originalParser = (Get-Command Get-AssetFrontmatter).ScriptBlock
    $propagated = $false
    try {
        Set-Item -Path Function:Get-AssetFrontmatter -Value { throw [InvalidOperationException]::new('unexpected parser failure') }
        try { $null = Get-Resolution } catch [InvalidOperationException] { $propagated = $true }
        Assert-Test $propagated 'Unexpected implementation failures must not become advisory availability findings'
    } finally {
        Set-Item -Path Function:Get-AssetFrontmatter -Value $originalParser
    }
    foreach ($badConfig in @(
        '',
        '{',
        'null',
        '{}',
        '{"schema_version":"1","dependencies":[]}',
        '{"schema_version":1,"dependencies":{} }',
        $valid.Replace('"schema_version":1', '"schema_version":1,"schema_version":1'),
        $valid.Replace('"provider":"basecoat"', '"provider":"basecoat","extra":true'),
        $valid.Replace('"provider":"basecoat"', '"provider":null'),
        $valid.Replace('"kind":"skill"', '"kind":"instruction"'),
        $valid.Replace('"name":"frontend-dev"', '"name":"Frontend-Dev"'),
        $valid.Replace('"kind":"skill"', '"kind":"agent"'),
        $valid.Replace('.github/skills/frontend-dev/SKILL.md', '../outside/SKILL.md'),
        $valid.Replace('.github/skills/frontend-dev/SKILL.md', '/etc/passwd'),
        $valid.Replace('.github/skills/frontend-dev/SKILL.md', 'C:/outside/SKILL.md'),
        $valid.Replace('.github/skills/frontend-dev/SKILL.md', '//server/share/SKILL.md'),
        $valid.Replace('.github/skills/frontend-dev/SKILL.md', '.github/skills/../frontend-dev/SKILL.md'),
        $valid.Replace('.github/skills/frontend-dev/SKILL.md', 'vendor/basecoat/skills/frontend-dev/SKILL.md'),
        $valid.Replace('.github/skills/frontend-dev/SKILL.md', '.github/skills/frontend-dev/OTHER.md'),
        $valid.Replace(']}', ',{"provider":"other","kind":"skill","name":"frontend-dev","path":".github/skills/frontend-dev/SKILL.md"}]}'),
        $valid.Replace(']}', ',{"provider":"basecoat","kind":"agent","name":"frontend-dev","path":".github/agents/frontend-dev.agent.md"}]}')
    )) {
        $script:cases++
        Write-Fixture 'scripts/external-delegates.json' $badConfig
        $bad = Get-Resolution
        Assert-Test ($bad.registry.diagnostics.Count -eq 1 -and $bad.registry.diagnostics[0].severity -eq 'error') 'Malformed/unsafe/ambiguous registry must error'
        Assert-Test ($bad.registry.verified.Count -eq 0 -and $bad.result.findings.Count -eq 1) 'Invalid registry cannot silently resolve'
    }
    $script:cases++
    Remove-Item -LiteralPath (Join-Path $fixture 'scripts/external-delegates.json')
    $absent = Get-Resolution
    Assert-Test ($absent.registry.diagnostics[0].severity -eq 'error' -and $absent.result.findings.Count -eq 1) 'Missing registry must be visible'
    $script:cases++
    Write-Fixture 'scripts/external-delegates.json' '{"schema_version":1,"dependencies":[]}'
    $unknown = Get-Resolution
    Assert-Test ($unknown.registry.diagnostics.Count -eq 0 -and $unknown.result.findings.Count -eq 1) 'Unregistered installed asset still warns'
    $script:cases++
    Write-Fixture 'scripts/external-delegates.json' ($valid.Replace('"kind":"skill"', '"kind":"agent"').Replace('.github/skills/frontend-dev/SKILL.md', '.github/agents/frontend-dev.agent.md'))
    Write-Fixture '.github/agents/frontend-dev.agent.md' $header
    $agent = Get-Resolution
    Assert-Test ($agent.registry.diagnostics.Count -eq 0 -and $agent.result.external_resolutions[0].kind -eq 'agent') 'Declared agent path/identity resolves'
    $script:cases++
    Write-Fixture 'scripts/external-delegates.json' $valid
    $assets[0].content = "## Workflow`n- ``unknown-prose```n## Delegates / pairs with`n- Feeds: ``frontend-dev```n- ``truly-unknown```n"
    $mixed = Get-Resolution
    Assert-Test ($mixed.result.external_resolutions.Count -eq 1 -and $mixed.result.findings.Count -eq 1) 'Real warnings persist alongside external resolutions; parser scope unchanged'
    Assert-Test ($mixed.result.findings[0].message -match 'truly-unknown') 'Warn for actual unregistered handoff, not arbitrary prose'
    $script:cases++
    $target = Join-Path $fixture '.github/skills/frontend-dev'
    Remove-Item -LiteralPath $target -Recurse -Force
    Write-Fixture 'outside/SKILL.md' $header
    $linkType = if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }
    [void](New-Item -ItemType $linkType -Path $target -Target (Join-Path $fixture 'outside'))
    try {
        $linked = Get-Resolution
        Assert-Test ($linked.registry.verified.Count -eq 0 -and $linked.registry.diagnostics[0].message -match 'unsafe-link') 'Link escape must not resolve'
        Assert-Test ($linked.result.findings.Count -eq 2) 'Unsafe target remains unresolved'
    } finally { Remove-Item -LiteralPath $target -Force }
    # Verify the source integration itself, not only fabricated constants.
    $script:cases++
    $actual = Get-ExternalDelegateRegistry -RepoRoot $root
    $sourceAssets = @(Get-ChildItem -LiteralPath (Join-Path $root 'skills') -Directory | ForEach-Object {
        [pscustomobject]@{ path = "skills/$($_.Name)/SKILL.md"; content = Get-Content -LiteralPath (Join-Path $_.FullName 'SKILL.md') -Raw }
    })
    $source = Invoke-SourceDelegateAudit -Assets $sourceAssets -SkillNames @(Get-ChildItem (Join-Path $root 'skills') -Directory | ForEach-Object Name) -AgentNames @(Get-ChildItem (Join-Path $root 'agents') -Filter '*.agent.md' | ForEach-Object { $_.Name -replace '\.agent\.md$', '' }) -Registry $actual
    Assert-Test ($sourceAssets.Count -gt 0 -and $actual.verified.Count -eq 3 -and $actual.diagnostics.Count -eq 0) 'Actual declared source headers must verify'
    Assert-Test ($source.external_resolutions.Count -eq 4 -and $source.findings.Count -eq 0) 'Actual four external handoffs resolve without suppressing unknowns'
    $script:cases++
    $reportPath = Join-Path $fixture 'audit-report.json'
    & pwsh -NoProfile -NonInteractive -File (Join-Path $PSScriptRoot 'audit-skills-agents.ps1') -Quiet -OutFile $reportPath
    Assert-Test ($LASTEXITCODE -eq 0) 'Actual source audit must succeed'
    $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    Assert-Test (($report.external_resolutions | ConvertTo-Json -Depth 5 -Compress) -ceq ($source.external_resolutions | ConvertTo-Json -Depth 5 -Compress)) 'Section 4 must actually integrate shared resolutions'
    Assert-Test ($report.warning_count -eq 0 -and $report.error_count -eq 0) 'Actual source warnings/errors must be zero'
    Write-Host "External delegates: $script:cases cases, $script:assertions assertions passed."
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}

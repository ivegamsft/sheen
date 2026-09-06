#!/usr/bin/env pwsh
# Real diagnostic executions over isolated source/consumer-shaped assets.
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'eval-routing-lib.ps1')
$root = Split-Path -Parent $PSScriptRoot
$fixtureRoot = Join-Path $root "dist/warn-rules-tests-$([guid]::NewGuid().ToString('N'))"
$assertions = 0

function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
    $script:assertions++
}

function Write-Fixture([string]$Base, [string]$Path, [string]$Content) {
    $full = Join-Path $Base $Path
    New-Item -ItemType Directory -Path (Split-Path -Parent $full) -Force | Out-Null
    [IO.File]::WriteAllText($full, $Content)
}

function New-Skill([string]$Name, [string]$Pairs = '', [string]$Body = 'Purpose.') {
    return @'
---
name: {0}
description: "USE FOR: design. DO NOT USE FOR: backend."
---
# Fixture
{1}
## Delegates / pairs with
{2}
## Other evidence
Not a routing declaration.
'@ -f $Name, $Body, $Pairs
}

function New-Eval([string]$Name, [string]$Scenarios, [string]$PathPrefix = 'skills') {
    return @'
name: "{0}-routing"
description: "Fixture."
skill: "{2}/{0}/SKILL.md"
scenarios:
{1}
'@ -f $Name, $Scenarios, $PathPrefix
}

$positive = @'
  - id: positive-keyboard
    input: "Specify keyboard navigation for the component."
    expect_activation: true
'@
$negative = @'
  - id: negative-keyboard
    input: "Audit keyboard and ARIA behavior with accessibility-auditor."
    expect_activation: false
'@
$ordinary = @'
  - id: ordinary
    input: "Specify the palette variants."
    expect_activation: true
'@
$inline = '  - { id: positive-aria, input: "Audit ARIA behavior.", expect_activation: true }'
$agent = @'
---
name: accessibility-auditor
description: "USE FOR: auditing. DO NOT USE FOR: branding."
composes:
  skills:
    - accessibility-audit
    - color-contrast-check
  instructions:
    - not-a-specialist
allowed-tools: []
---
# Auditor
'@
$cases = @(
    @{ id = 'negative-only'; scenarios = "$ordinary`n$negative"; pairs = ''; warnings = 0 }
    @{ id = 'unresolved'; scenarios = $positive; pairs = ''; warnings = 1 }
    @{ id = 'literal-agent-in-eval'; scenarios = "$positive`n$negative"; pairs = ''; warnings = 1 }
    @{ id = 'direct-agent'; scenarios = $positive; pairs = '- agent: `accessibility-auditor`'; warnings = 0 }
    @{ id = 'direct-specialist'; scenarios = $positive; pairs = '- `accessibility-audit`'; warnings = 0 }
    @{ id = 'paired-list'; scenarios = $positive; pairs = '- `ordinary`, `accessibility-audit`'; warnings = 0 }
    @{ id = 'legacy-pairing'; scenarios = $positive; pairs = '- Feeds: `ordinary` (implementation), `accessibility-auditor` (colour + ARIA)'; legacy = $true; warnings = 0 }
    @{ id = 'bare-specialist'; scenarios = $positive; pairs = '- accessibility-audit'; warnings = 0 }
    @{ id = 'table-specialist'; scenarios = $positive; pairs = '| `accessibility-audit` | ARIA and keyboard review |'; warnings = 0 }
    @{ id = 'contrast-specialist'; scenarios = ($positive -replace 'keyboard navigation', 'focus-ring tokens'); pairs = '- `color-contrast-check`'; warnings = 0 }
    @{ id = 'owning-agent'; scenarios = $positive; pairs = ''; name = 'accessibility-audit'; warnings = 0 }
    @{ id = 'inline-eval'; scenarios = $inline; pairs = '- `accessibility-audit`'; warnings = 0 }
    @{ id = 'mixed-block-inline'; scenarios = "$positive`n  - { id: negative, input: `"Other design.`", expect_activation: false }"; pairs = ''; warnings = 1 }
    @{ id = 'broken-specialist'; scenarios = $positive; pairs = '- `accessibility-audit`'; omit = 'skill'; warnings = 1 }
    @{ id = 'broken-agent'; scenarios = $positive; pairs = '- agent: `accessibility-auditor`'; omit = 'agent'; warnings = 1 }
    @{ id = 'invalid-agent-name'; scenarios = $positive; pairs = '- agent: `accessibility-auditor`'; badAgent = $true; warnings = 1 }
    @{ id = 'invalid-specialist-name'; scenarios = $positive; pairs = '- `accessibility-audit`'; badSkill = $true; warnings = 1 }
    @{ id = 'missing-owner'; scenarios = $positive; pairs = '- `accessibility-audit`'; omit = 'owner'; warnings = 1 }
    @{ id = 'mismatched-owner'; scenarios = $positive; pairs = '- `accessibility-audit`'; mismatch = $true; warnings = 1 }
    @{ id = 'no-transitive-route'; scenarios = $positive; pairs = '- `ordinary`'; warnings = 1 }
    @{ id = 'body-mention'; scenarios = $positive; pairs = ''; body = 'Do not use `accessibility-auditor`.'; warnings = 1 }
    @{ id = 'pair-negation'; scenarios = $positive; pairs = '- Do not use `accessibility-auditor`.'; warnings = 1 }
    @{ id = 'pair-prose-mention'; scenarios = $positive; pairs = '- `ordinary` instead of `accessibility-auditor`.'; warnings = 1 }
    @{ id = 'not-composes-skills'; scenarios = $positive; pairs = '- `not-a-specialist`'; warnings = 1 }
    @{ id = 'flow-composition'; scenarios = $positive; pairs = '- `accessibility-audit`'; flow = $true; warnings = 0 }
    @{ id = 'missing-polarity'; scenarios = ($positive -replace 'expect_activation: true', 'expect_activation: maybe'); pairs = '- `accessibility-audit`'; warnings = 1 }
    @{ id = 'malformed-inline'; scenarios = '  - { input: "Keyboard.", expect_activation: true }'; pairs = '- `accessibility-audit`'; warnings = 1 }
    @{ id = 'unsupported-multiline'; scenarios = "  - id: multiline`n    input: |`n      Keyboard audit.`n    expect_activation: true"; pairs = '- `accessibility-audit`'; warnings = 1 }
    @{ id = 'quoted-block-character'; scenarios = ($positive -replace 'Specify keyboard', '> Specify keyboard'); pairs = '- `accessibility-audit`'; warnings = 0 }
    @{ id = 'empty-scenarios'; scenarios = ''; pairs = '- `accessibility-audit`'; warnings = 1 }
)

try {
    foreach ($consumer in @($false, $true)) {
        foreach ($case in $cases) {
            $base = Join-Path $fixtureRoot "$(if ($consumer) { 'consumer' } else { 'source' })-$($case.id)"
            $prefix = if ($consumer) { '.github/' } else { '' }
            $name = if ($case.ContainsKey('name')) { $case.name } else { 'fixture' }
            $body = if ($case.ContainsKey('body')) { $case.body } else { 'Purpose.' }
            $omit = if ($case.ContainsKey('omit')) { $case.omit } else { '' }
            if ($omit -ne 'skill') {
                $skillName = if ($case.ContainsKey('badSkill')) { 'wrong-name' } else { 'accessibility-audit' }
                Write-Fixture $base "${prefix}skills/accessibility-audit/SKILL.md" (New-Skill $skillName)
            }
            Write-Fixture $base "${prefix}skills/color-contrast-check/SKILL.md" (New-Skill 'color-contrast-check')
            Write-Fixture $base "${prefix}skills/ordinary/SKILL.md" (New-Skill 'ordinary' '- `accessibility-audit`')
            Write-Fixture $base "${prefix}skills/not-a-specialist/SKILL.md" (New-Skill 'not-a-specialist')
            if ($omit -ne 'owner') {
                $owner = New-Skill $name $case.pairs $body
                if ($case.ContainsKey('legacy')) { $owner = $owner -replace 'Delegates / pairs with', 'Agent Pairing' }
                Write-Fixture $base "${prefix}skills/$name/SKILL.md" $owner
            }
            if ($omit -ne 'agent') {
                $agentText = $agent
                if ($case.ContainsKey('badAgent')) { $agentText = $agentText -replace 'name: accessibility-auditor', 'name: wrong-agent' }
                if ($case.ContainsKey('flow')) { $agentText = $agentText -replace 'skills:\r?\n    - accessibility-audit\r?\n    - color-contrast-check', 'skills: [accessibility-audit, color-contrast-check]' }
                Write-Fixture $base "${prefix}agents/accessibility-auditor.agent.md" $agentText
            }
            $eval = New-Eval $name $case.scenarios
            if ($case.ContainsKey('mismatch')) { $eval = $eval -replace "skills/$name/SKILL.md", 'skills/ordinary/SKILL.md' }
            Write-Fixture $base "${prefix}skills/$name/eval.yaml" $eval
            if ($consumer) {
                $files = @(Get-ChildItem -LiteralPath $base -File -Recurse -Force | ForEach-Object { [IO.Path]::GetRelativePath($base, $_.FullName).Replace('\', '/') })
                Assert ($files.Count -gt 0) 'Consumer fixture ownership is empty; include hidden .github on Unix.'
                Write-Fixture $base '.sheen/manifest.json' (@{ schema = 'sheen-manifest/v1'; files = $files } | ConvertTo-Json)
                # Installed but not Sheen-owned: must not produce W03/W04/W05.
                Write-Fixture $base '.github/skills/upstream/SKILL.md' (New-Skill 'upstream' '' ('x' * 2600))
                Write-Fixture $base '.github/skills/upstream/eval.yaml' (New-Eval 'upstream' $positive)
            }
            $output = & pwsh -NoProfile -NonInteractive -File (Join-Path $PSScriptRoot 'warn-rules.ps1') -RepoRoot $base 2>&1
            Assert ($LASTEXITCODE -eq 0) "$base failed advisory exit: $output"
            $warnings = @($output | Where-Object { "$_" -match '\[(?:warn/)?W04\]' })
            Assert ($warnings.Count -eq $case.warnings) "$base expected $($case.warnings) W04, got $($warnings.Count): $output"
            Assert (-not ($output -match 'upstream')) "$base scanned an unowned skill."
        }
    }
    $mixed = Parse-EvalFile -Path (Join-Path $fixtureRoot 'source-mixed-block-inline/skills/fixture/eval.yaml') -RepoRoot $fixtureRoot
    Assert ($mixed.scenarios.Count -eq 2 -and $mixed.scenarios[0].expect_activation -eq $true) 'Parser discarded block scenario before inline row.'

    # Explicit consumer-local skill path, missing owned files, and invalid ownership.
    $base = Join-Path $fixtureRoot 'consumer-direct-specialist'
    Write-Fixture $base '.github/skills/fixture/eval.yaml' (New-Eval 'fixture' $positive '.github/skills')
    $output = & pwsh -NoProfile -NonInteractive -File (Join-Path $PSScriptRoot 'warn-rules.ps1') -RepoRoot $base 2>&1
    Assert ($LASTEXITCODE -eq 0 -and -not ($output -match '\[(?:warn/)?W04\]')) "Consumer-local reference failed: $output"
    $manifestPath = Join-Path $base '.sheen/manifest.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $manifest.files += '.github/skills/missing/SKILL.md'
    Write-Fixture $base '.sheen/manifest.json' ($manifest | ConvertTo-Json)
    $output = & pwsh -NoProfile -NonInteractive -File (Join-Path $PSScriptRoot 'warn-rules.ps1') -RepoRoot $base 2>&1
    Assert ($LASTEXITCODE -eq 0 -and ($output -match 'manifest-owned routing asset is missing')) "Missing owned asset was not diagnosed: $output"
    foreach ($invalid in @('', '{}', '{bad json', '{"schema":"sheen-manifest/v1","files":"not-an-array"}', 'null')) {
        Write-Fixture $base '.sheen/manifest.json' $invalid
        $output = & pwsh -NoProfile -NonInteractive -File (Join-Path $PSScriptRoot 'warn-rules.ps1') -RepoRoot $base 2>&1
        Assert ($LASTEXITCODE -eq 0 -and ($output -match 'invalid ownership manifest')) "Invalid ownership did not stay advisory: $output"
    }
    Write-Fixture $base '.sheen/manifest.json' '{"schema":"sheen-manifest/v1","files":[]}'
    $output = & pwsh -NoProfile -NonInteractive -File (Join-Path $PSScriptRoot 'warn-rules.ps1') -RepoRoot $base 2>&1
    Assert ($LASTEXITCODE -eq 0 -and ($output -match '0 warning\(s\)')) "Empty owned set was scanned: $output"
    Write-Fixture $base '.sheen/manifest.json' '{"schema":"sheen-manifest/v1","files":[42]}'
    $output = & pwsh -NoProfile -NonInteractive -File (Join-Path $PSScriptRoot 'warn-rules.ps1') -RepoRoot $base 2>&1
    Assert ($LASTEXITCODE -eq 0 -and ($output -match 'ownership files must contain path strings')) "Invalid ownership entry was ignored: $output"

    $base = Join-Path $fixtureRoot 'source-body-budget'
    foreach ($chars in @(2500, 2501)) {
        # Include a body thematic break: only the first closing frontmatter counts.
        $body = "# Fixture`n---`n" + ('x' * ($chars - 14))
        Assert ($body.Length -eq $chars) 'Invalid size fixture.'
        Write-Fixture $base 'skills/fixture/SKILL.md' "---`nname: fixture`n---`n$body"
        $output = & pwsh -NoProfile -NonInteractive -File (Join-Path $PSScriptRoot 'warn-rules.ps1') -RepoRoot $base 2>&1
        Assert ($LASTEXITCODE -eq 0) "Body budget diagnostics failed: $output"
        $count = @($output | Where-Object { "$_" -match '\[(?:warn/)?W03\]' }).Count
        Assert ($count -eq [int]($chars -gt 2500)) "Body budget changed for $chars characters: $output"
    }
    Write-Fixture $base 'skills/fixture/SKILL.md' ''
    Write-Fixture $base 'skills/fixture/eval.yaml' (New-Eval 'fixture' $positive)
    $output = & pwsh -NoProfile -NonInteractive -File (Join-Path $PSScriptRoot 'warn-rules.ps1') -RepoRoot $base 2>&1
    Assert ($LASTEXITCODE -eq 0 -and ($output -match 'missing, invalid or mismatched skill reference')) "Empty skill did not remain advisory: $output"

    Write-Host "test-warn-rules: OK ($($cases.Count * 2) source/consumer cases; $assertions assertions)."
} finally {
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}

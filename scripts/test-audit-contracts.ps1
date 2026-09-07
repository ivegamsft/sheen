# Deterministic consistency checks of operative documents, not agent/WCAG proof.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$paths = @{
    ai = 'skills/ai-output-governance/references/review-contract.md'
    aiSkill = 'skills/ai-output-governance/SKILL.md'
    ethics = 'skills/ethical-design/references/ethics-contract.md'
    parity = 'skills/design-drift-detection/references/parity-contract.md'
    skill = 'skills/design-drift-detection/SKILL.md'
}
$documents = @{}
foreach ($key in $paths.Keys) { $documents[$key] = Get-Content -LiteralPath (Join-Path $root $paths[$key]) -Raw }

function Assert-Contract {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Get-Example {
    param([string]$Document, [string]$Heading)
    $examples = [regex]::Matches($Document, '(?ms)^```\r?\n(## ' + [regex]::Escape($Heading) + '\r?\n.*?)^```')
    Assert-Contract ($examples.Count -eq 1) "Expected exactly one operative $Heading example"
    return $examples[0].Groups[1].Value
}

function Test-GateContract {
    param([string]$Document, [string]$Kind)
    $schemas = [regex]::Matches($Document, '(?ms)^## Output Schema\r?\n\r?\n```yaml\r?\n(.*?)^```')
    Assert-Contract ($schemas.Count -eq 1) 'Expected one normative output schema'
    $schema = $schemas[0].Groups[1].Value
    foreach ($field in @('status: PASS | FAIL | N/A | UNKNOWN', 'reason: string', 'evidence_refs: [string]')) {
        Assert-Contract ($schema.Contains($field)) "Missing result-shape field: $field"
    }
    if ($Kind -eq 'ai') {
        Assert-Contract ($schema.Contains('dimension_results:') -and $schema.Contains('gate: PASS | WARN | FAIL | UNRESOLVED')) 'AI schema must represent unresolved dimensions and gate'
    } else {
        Assert-Contract ($schema.Contains('checks:') -and $schema.Contains('gate_status: PASS | FAIL | UNRESOLVED') -and $schema.Contains('gate_passed: boolean | null')) 'Parity schema must represent unresolved checks and nullable gate'
    }
    $rows = [regex]::Matches($Document, '(?m)^\| (?<statuses>(?:PASS|FAIL|N/A|UNKNOWN)(?:, (?:PASS|FAIL|N/A|UNKNOWN))*) \| (?<critical>\d+) \| (?<major>\d+) \| (?<gate>PASS|WARN|FAIL|UNRESOLVED) \|(?: (?<passed>true|false|null) \|)?\r?$')
    Assert-Contract ($rows.Count -eq 7) 'Expected seven nonempty worked gate decisions'
    foreach ($row in $rows) {
        $statuses = $row.Groups['statuses'].Value -split ', '
        $critical = [int]$row.Groups['critical'].Value
        $major = [int]$row.Groups['major'].Value
        Assert-Contract (($critical + $major -gt 0) -eq ($statuses -contains 'FAIL')) 'Worked finding counts must match confirmed failures'
        $applicable = $statuses -contains 'PASS' -or $statuses -contains 'FAIL'
        $expected = if ($critical -gt 0) { 'FAIL' }
            elseif ($statuses -contains 'UNKNOWN' -or -not $applicable) { 'UNRESOLVED' }
            elseif ($Kind -eq 'ai' -and $major -gt 0) { 'WARN' }
            else { 'PASS' }
        Assert-Contract ($row.Groups['gate'].Value -ceq $expected) 'Worked gate disagrees with evidence/severity precedence'
        if ($Kind -eq 'parity') {
            $passed = switch ($expected) { 'PASS' { 'true' }; 'FAIL' { 'false' }; 'UNRESOLVED' { 'null' } }
            Assert-Contract ($row.Groups['passed'].Value -ceq $passed) 'Parity gate_passed must distinguish unresolved from failed'
        }
    }
}

function Test-DocumentContracts {
    param([hashtable]$Docs)
    Test-GateContract $Docs.ai 'ai'
    Test-GateContract $Docs.parity 'parity'
    Assert-Contract ($Docs.aiSkill.Contains('PASS/WARN/FAIL/UNRESOLVED gate')) 'AI skill must expose unresolved gate'
    Assert-Contract ($Docs.aiSkill.Contains('Missing evidence is UNKNOWN; return UNRESOLVED unless a known CRITICAL failure already requires FAIL.')) 'AI skill must preserve failure/unknown precedence'
    Assert-Contract ($Docs.skill.Contains('`gate_status` and `gate_passed` (null when unresolved)')) 'Parity skill must expose unresolved result shape'
    $copy = Get-Example $Docs.ai 'AI Copy Review'
    $checkout = Get-Example $Docs.ethics 'Ethical Design Audit: Checkout'
    foreach ($sample in @(
        @{ text = $copy; count = 2 },
        @{ text = $checkout; count = 3 }
    )) {
        $findings = [regex]::Matches($sample.text, '(?m)^(?:[^\r\n]*?:[ \t]*⚠️[ \t]*)?(CRITICAL|MAJOR|MINOR|INFO) —')
        Assert-Contract ($findings.Count -eq $sample.count) 'Example findings missing or unparseable'
        $totals = [regex]::Matches($sample.text, '(?m)^Gate: (PASS|WARN|FAIL) \((\d+) critical, (\d+) major\)\r?$')
        Assert-Contract ($totals.Count -eq 1) 'Missing or ambiguous example gate'
        $critical = @($findings | Where-Object { $_.Groups[1].Value -eq 'CRITICAL' }).Count
        $major = @($findings | Where-Object { $_.Groups[1].Value -eq 'MAJOR' }).Count
        Assert-Contract ($critical -eq [int]$totals[0].Groups[2].Value -and $major -eq [int]$totals[0].Groups[3].Value) 'Example totals disagree with findings'
        Assert-Contract ($critical -gt 0 -and $totals[0].Groups[1].Value -eq 'FAIL') 'Critical findings must fail the gate'
    }
    Assert-Contract ($Docs.ai -match '(?m)^\| Representational fairness \| [^\r\n|]+ \| CRITICAL \|\r?$') 'Fairness table must remain critical'
    Assert-Contract ($copy -match '(?m)^Representational:[^\r\n]*CRITICAL —') 'Fairness example must remain critical'
    $accessibility = [regex]::Matches($Docs.ai, '(?m)^\| Accessibility \| ([^\r\n|]+) \| MAJOR \|\r?$')
    Assert-Contract ($accessibility.Count -eq 1) 'Missing accessibility criterion'
    foreach ($phrase in @('Images require appropriate text alternatives', 'ordinary text needs no image alt attributes', 'components require appropriate accessibility behavior')) {
        Assert-Contract ($accessibility[0].Groups[1].Value.Contains($phrase)) "Accessibility applicability: $phrase"
    }
    Assert-Contract ($copy -match '(?m)^Image alternatives: N/A — text-only copy contains no images; image alt attributes do not apply\.\r?$') 'Text-only image check needs reasoned N/A'
    Assert-Contract ($copy -match '(?m)^Other accessibility: UNKNOWN — rendered context not supplied; no WCAG approval claimed\.\r?$') 'Unknown rendered accessibility cannot pass'
    foreach ($phrase in @('Use N/A only for an inapplicable check, with the reason.', 'Missing evidence is', 'UNKNOWN, not N/A or PASS', 'does not approve other accessibility checks or WCAG')) {
        Assert-Contract ($Docs.ai.Contains($phrase)) "AI evidence guard: $phrase"
    }
    foreach ($pattern in @('Hidden costs', 'Misdirection', 'Confirmshaming')) {
        $rows = [regex]::Matches($Docs.ethics, '(?m)^\| ' + $pattern + ' \| [^\r\n|]+ \| (CRITICAL|MAJOR) \|\r?$')
        Assert-Contract ($rows.Count -eq 1) "Missing ethics taxonomy: $pattern"
        $severity = $rows[0].Groups[1].Value
        Assert-Contract ($checkout -match ('(?m)^' + $severity + ' — ' + $pattern + ':')) "Taxonomy/example disagreement: $pattern"
    }
    Assert-Contract ($Docs.ethics -match '(?m)^\| Hidden costs \| [^\r\n|]+ \| CRITICAL \|\r?$') 'Hidden costs remain critical'
    foreach ($row in @(
        '| CRITICAL | Token value does not reference design system | Block PR |',
        '| CRITICAL | Missing or incorrect required ARIA role, name, or state against the accepted component contract | Block PR |',
        '| MAJOR | Required component state missing (focus, error, loading) | Log issue |',
        '| MINOR | Visual deviation within token-defined range | Log warning |',
        '| INFO | Implementation adds undocumented variant | Document |'
    )) { Assert-Contract ($Docs.parity.Contains($row)) "Parity severity/action row: $row" }
    $parityExample = Get-Example $Docs.parity 'Drift Report: Button'
    Assert-Contract ($parityExample -match '(?m)^\| Required ARIA state \| Toggle: pressed state exposed \| pressed state absent \| ❌ CRITICAL \|\r?$') 'ARIA example must demonstrate required critical drift'
    foreach ($phrase in @('zero CRITICAL drifts (token or ARIA)', 'observed native button has its name but omits the required `aria-pressed`', 'This is CRITICAL and blocks the gate', 'never downgrade an actual required role/name/state violation to MAJOR.', 'optional or irrelevant ARIA is not required.', 'Do not add gratuitous', 'ARIA to native elements or override valid native semantics.', 'Use N/A with a reason for inapplicable ARIA checks.', 'is UNKNOWN, not N/A or PASS', 'passing gate.')) {
        Assert-Contract ($Docs.parity.Contains($phrase)) "Parity guard/evidence: $phrase"
    }
    foreach ($phrase in @('zero CRITICAL token or ARIA drifts', 'missing/incorrect required ARIA role/name/state against the accepted component contract', 'Required ARIA violations override MAJOR missing-state ratings.', 'Respect valid native semantics;', 'optional/irrelevant ARIA is not required.', 'N/A needs a reason; missing evidence is UNKNOWN, never a pass.')) {
        Assert-Contract ($Docs.skill.Contains($phrase)) "Skill guard: $phrase"
    }
}

Test-DocumentContracts $documents
$cases = @(
    @('ai', 'FAIL (1 critical, 1 major)', 'FAIL (2 critical, 1 major)'),
    @('ethics', 'FAIL (1 critical, 2 major)', 'FAIL (2 critical, 2 major)'),
    @('ai', 'Gate: FAIL', 'Gate: PASS'),
    @('ai', '⚠️  CRITICAL —', '⚠️  MAJOR —'),
    @('ai', '| Representational fairness | No stereotyped, exclusionary, or marginalised depictions | CRITICAL |', '| Representational fairness | No stereotyped, exclusionary, or marginalised depictions | MAJOR |'),
    @('ai', 'ordinary text needs no image alt attributes', 'AI copy has alt text'),
    @('ai', 'Images require appropriate text alternatives', 'Images require no text alternatives'),
    @('ai', 'components require appropriate accessibility behavior', 'components need no checks'),
    @('ai', 'N/A — text-only copy contains no images; image alt attributes do not apply.', 'PASS — all WCAG checks passed.'),
    @('ai', 'Other accessibility: UNKNOWN', 'Other accessibility: N/A'),
    @('ai', 'UNKNOWN, not N/A or PASS', 'PASS when evidence is missing'),
    @('ai', 'with the reason.', 'without a reason.'),
    @('ai', 'does not approve other accessibility checks or WCAG', 'approves all WCAG'),
    @('ethics', 'CRITICAL — Hidden costs:', 'MAJOR — Hidden costs:'),
    @('ethics', '## Ethical Design Audit: Checkout', '## Unparseable example'),
    @('ai', '## AI Copy Review', '## Unparseable example'),
    @('parity', '| CRITICAL | Missing or incorrect required ARIA role, name, or state against the accepted component contract | Block PR |', ''),
    @('parity', '| CRITICAL | Missing or incorrect', '| MAJOR | Missing or incorrect'),
    @('parity', '| ❌ CRITICAL |', '| ❌ MAJOR |'),
    @('parity', 'never downgrade an actual required role/name/state violation to MAJOR.', 'Downgrade ARIA state violations to MAJOR.'),
    @('parity', 'optional or irrelevant ARIA is not required.', 'Optional ARIA is required.'),
    @('parity', 'Do not add gratuitous', 'Always add gratuitous'),
    @('parity', 'is UNKNOWN, not N/A or PASS', 'is PASS without evidence'),
    @('parity', 'Use N/A with a reason', 'Use N/A without a reason'),
    @('parity', 'zero CRITICAL drifts (token or ARIA)', 'zero token drifts'),
    @('parity', '## Drift Report: Button', '## No operative example'),
    @('skill', 'Required ARIA violations override MAJOR missing-state ratings.', 'Missing states are always MAJOR.'),
    @('skill', 'missing/incorrect required ARIA role/name/state', 'optional ARIA'),
    @('skill', 'UNKNOWN, never a pass.', 'PASS.'),
    @('skill', 'Respect valid native semantics;', 'Override native semantics;'),
    @('skill', 'optional/irrelevant ARIA is not required.', 'All ARIA is mandatory.'),
    @('ai', 'gate: PASS | WARN | FAIL | UNRESOLVED', 'gate: PASS | WARN | FAIL'),
    @('ai', 'status: PASS | FAIL | N/A | UNKNOWN', 'status: PASS | FAIL'),
    @('ai', '    reason: string', ''),
    @('ai', '    evidence_refs: [string]', ''),
    @('ai', '| FAIL, UNKNOWN | 0 | 1 | UNRESOLVED |', '| FAIL, UNKNOWN | 0 | 1 | WARN |'),
    @('ai', '| N/A | 0 | 0 | UNRESOLVED |', '| N/A | 0 | 0 | PASS |'),
    @('parity', 'gate_passed: boolean | null', 'gate_passed: boolean'),
    @('parity', 'gate_status: PASS | FAIL | UNRESOLVED', 'gate_status: PASS | FAIL'),
    @('parity', '| UNKNOWN | 0 | 0 | UNRESOLVED | null |', '| UNKNOWN | 0 | 0 | UNRESOLVED | false |'),
    @('aiSkill', 'PASS/WARN/FAIL/UNRESOLVED gate', 'PASS/WARN/FAIL gate'),
    @('skill', '`gate_status` and `gate_passed` (null when unresolved)', '`gate_passed`')
)
foreach ($case in $cases) {
    $mutated = $documents.Clone()
    Assert-Contract ($mutated[$case[0]].Contains($case[1])) "Mutation target missing: $($case[1])"
    $mutated[$case[0]] = $mutated[$case[0]].Replace($case[1], $case[2])
    $rejected = $false
    try { Test-DocumentContracts $mutated } catch { $rejected = $true }
    Assert-Contract $rejected "Bad document accepted: $($case -join ' -> ')"
}
$coherentDowngrade = $documents.Clone()
$coherentDowngrade.ai = $coherentDowngrade.ai.Replace('⚠️  CRITICAL —', '⚠️  MAJOR —').Replace('FAIL (1 critical, 1 major)', 'WARN (0 critical, 2 major)')
$rejected = $false
try { Test-DocumentContracts $coherentDowngrade } catch { $rejected = $true }
Assert-Contract $rejected 'Self-consistent totals must not disguise a fairness downgrade'
Write-Host "Audit contracts: 5 operative documents and 14 worked gate decisions passed; $($cases.Count + 1) negative mutations rejected. Document consistency only."

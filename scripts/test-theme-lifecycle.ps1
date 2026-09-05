#!/usr/bin/env pwsh
# Executable worked reasoning examples, not a runtime adapter, LLM evaluation,
# downstream schema validator, or rendered visual-quality test.
param(
    [string]$FixtureDirectory = (Join-Path $PSScriptRoot '..\tests\fixtures\theme-lifecycle'),
    [string]$OutFile = ''
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

function Merge-Input([System.Collections.IDictionary]$Base, [System.Collections.IDictionary]$Patch) {
    $copy = ConvertFrom-Json (ConvertTo-Json $Base -Depth 50) -AsHashtable
    foreach ($key in $Patch.Keys) {
        if ($copy[$key] -is [System.Collections.IDictionary] -and $Patch[$key] -is [System.Collections.IDictionary]) {
            $copy[$key] = Merge-Input $copy[$key] $Patch[$key]
        } else { $copy[$key] = $Patch[$key] }
    }
    return $copy
}

function Same-Set($Left, $Right) {
    return (@(Compare-Object @($Left | Sort-Object -Unique) @($Right | Sort-Object -Unique)).Count -eq 0)
}

function Get-Decision([System.Collections.IDictionary]$InputRecord) {
    $d = $InputRecord
    $t = $d.target
    $s = $d.selection
    $a = $d.application
    $blocks = [System.Collections.Generic.List[string]]::new()
    $out = [ordered]@{
        route = 'theming'; comparison = 'not-assessed'; stateCoverage = 'not-assessed'
        candidateSummaries = @()
        selection = 'pending'; applicability = 'requires authority or reassessment'
        promptRequired = $false; readiness = 'not-assessed'; blockers = @()
        semanticOwner = 'design-tokens'; application = 'handoff'; complete = $false
        unrelatedPreserved = $true
        changedTargets = @($a.changedTargets)
        unchangedTargets = @($t.surfaces | Where-Object { $_ -notin $a.changedTargets })
        recovery = $a.recovery; conditions = @('proposed'); customAction = 'not-requested'
        history = @($d.history); predecessor = $d.revision.predecessor
        affectedConsumers = @($d.revision.affectedConsumers)
        invalidatedEvidence = @($d.revision.staleEvidence); audit = @()
    }
    if ($d.intent -ne 'theme') {
        $out.route = switch ($d.intent) {
            'brand' { 'brand-identity' }
            'reporting' { 'data-visualisation' }
            'documentation' { 'documentation-diagram' }
            default { throw "Unsupported fixture intent: $($d.intent)" }
        }
        $out.application = 'not-in-scope'
        return $out
    }

    $comparable = $true
    $visual = $true
    $stateCoverage = $true
    foreach ($c in $d.candidates) {
        if ($c.content -ne $t.content -or $c.conditions -ne $t.conditions -or
            @($t.modes | Where-Object { $_ -notin $c.modes }).Count -or
            @($t.surfaces | Where-Object { $_ -notin $c.surfaces }).Count) { $comparable = $false }
        if ($t.interactive -and @($t.states | Where-Object { $_ -notin $c.states }).Count) {
            $stateCoverage = $false
        }
        $preview = if ($d.Contains('previewOverride')) { $d.previewOverride } else { $c.preview }
        $out.candidateSummaries += [ordered]@{
            identity = "$($c.id)@$($c.revision)"; purpose = $c.purpose
            maturity = $c.maturity; limitations = @($c.limitations); preview = $preview
        }
        if ($preview -ne 'rendered' -or -not $c.evidence) { $visual = $false }
    }
    if (-not $t.interactive -and -not $t.staticReason) { $stateCoverage = $false }
    $out.stateCoverage = if (-not $stateCoverage) { 'missing' } elseif ($t.interactive) { 'covered' } else { 'not-applicable' }
    if (-not $comparable -or -not $stateCoverage) {
        $out.comparison = 'provisional'; $blocks.Add('comparison')
    } elseif (-not $visual) { $out.comparison = 'logical-only' } else { $out.comparison = 'comparable' }
    if ($t.visualRequired -and -not $visual) { $blocks.Add('visual-evidence') }

    $candidate = @($d.candidates | Where-Object {
        $_.id -eq $s.candidate -and $_.revision -eq $s.revision
    })
    if ($d.brandConflict) { $blocks.Add('brand-conflict') }
    $authority = $s.status -eq 'approved' -and $s.authority -in @('human', 'delegated-agent') -and $s.policy
    if ($authority -and -not $d.brandConflict) {
        $applicable = $candidate.Count -eq 1 -and
            (Same-Set $t.surfaces $s.surfaces) -and (Same-Set $t.modes $s.modes) -and
            (Same-Set $t.states $s.states) -and $t.context -eq $s.context -and
            $t.brand -eq $s.brand -and $t.capability -eq $s.capability -and
            $t.evidenceVersion -eq $s.evidenceVersion -and -not $d.revision.changed
        if ($applicable) {
            $out.selection = 'reuse'
            $out.applicability = 'revision/scope/brand/capability/evidence unchanged'
        } else { $out.selection = 'reassess' }
    }
    if ($out.selection -ne 'reuse') { $blocks.Add('selection') }
    $binding = $d.readinessBinding
    if ($binding.selection -ne $s.id -or $binding.candidate -ne $s.candidate -or
        $binding.revision -ne $s.revision -or $binding.evidenceVersion -ne $t.evidenceVersion) {
        $blocks.Add('readiness-evidence-stale')
    }
    if ($candidate.Count -ne 1 -or
        @($candidate[0].mapping | Where-Object { $_ -notin $t.semanticKeys }).Count -or
        @($t.semanticKeys | Where-Object { $_ -notin $candidate[0].mapping }).Count -or
        $d.mappingCollisions.Count) { $blocks.Add('semantic-mapping') }

    # Missing mandatory rows cannot disappear from the gate by deletion.
    $required = @('semantics', 'capability', 'fontAvailability', 'fontPermission',
        'fontCoverage', 'fontFit', 'accessibility', 'impact', 'recovery')
    foreach ($name in @($required + @($d.requirements.Keys) | Sort-Object -Unique)) {
        $r = $d.requirements[$name]
        $status = if ($null -eq $r) { 'unknown' } else { $r.status }
        if ($null -ne $r -and (-not $r.evidence -or -not $r.observation)) { $status = 'unknown' }
        if ($status -notin @('pass', 'fail', 'unknown', 'not-applicable')) { $status = 'unknown' }
        if (($name -in $required -or $r.mandatory) -and $status -notin @('pass', 'not-applicable')) {
            $blocks.Add("${name}:$status")
        }
    }
    foreach ($pair in $d.accessibility.pairs) {
        if ($pair.Contains('exemption') -and $pair.exemption) { continue }
        $floor = if ($pair.kind -eq 'normal') { 4.5 } else { 3.0 }
        $threshold = [Math]::Max($floor, $pair.required)
        if (-not $pair.evidence -or $null -eq $pair.ratio) { $blocks.Add("contrast:$($pair.id):unknown") }
        elseif ($pair.ratio -lt $threshold) { $blocks.Add("contrast:$($pair.id):$($pair.ratio)<$threshold") }
    }
    if (-not $d.accessibility.pairs.Count) { $blocks.Add('contrast:unknown') }
    if ($d.accessibility.nonColorCues -ne 'pass' -or -not $d.accessibility.cuesEvidence) {
        $blocks.Add('non-color-cues')
    }
    if ($d.task -eq 'custom') {
        $out.customAction = if ($d.custom.existingSuitable) { 'reuse' }
            elseif (-not $d.custom.need -or -not $d.custom.grounding) { 'blocked' }
            elseif ($d.custom.basePurposeValid) { 'extend' } else { 'create' }
        if ($out.customAction -eq 'blocked') { $blocks.Add('custom-prerequisites') }
    }
    $out.blockers = @($blocks | Sort-Object -Unique)
    $out.readiness = if ($blocks.Count) { 'blocked' } else { 'ready' }
    $conditions = [System.Collections.Generic.List[string]]::new()
    if ($out.selection -eq 'reuse') { $conditions.Add('selected') } else { $conditions.Add('proposed') }
    if ($out.readiness -eq 'ready') { $conditions.Add('ready') } else { $conditions.Add('blocked') }

    if ($a.changedTargets.Count) {
        foreach ($field in @('semanticKeys', 'content', 'structure', 'behavior')) {
            $before = ConvertTo-Json -InputObject $a.preservation.before[$field] -Compress
            $after = ConvertTo-Json -InputObject $a.preservation.after[$field] -Compress
            if ($before -cne $after -or $before -eq 'null') { $out.unrelatedPreserved = $false }
        }
    }
    if ($d.task -eq 'audit') {
        $out.application = if ($a.changedTargets.Count) { 'authorization-violation' } else { 'audit-only' }
        if ($a.changedTargets.Count) {
            $conditions.Add('applied')
            if ('blocked' -notin $conditions) { $conditions.Add('blocked') }
        }
        foreach ($observation in $d.observations) {
            $classification = if (-not $observation.evidence) { 'unresolved' }
                elseif ($observation.deviation -and $observation.decision -and $observation.applicable) { 'variant' }
                elseif ($observation.deviation) { 'drift' } else { 'aligned' }
            $out.audit += "$($observation.target):$classification"
        }
    } else {
        $authorized = $a.authorization.granted -and $a.authorization.reference -and
            $a.authorization.mechanism -and $a.authorization.revision -eq $s.revision -and
            $a.authorization.candidate -eq $s.candidate -and $a.authorization.selection -eq $s.id -and
            (Same-Set $t.surfaces $a.authorization.surfaces) -and
            (Same-Set $t.modes $a.authorization.modes) -and
            (Same-Set $t.states $a.authorization.states) -and $t.context -eq $a.authorization.context
        if ($a.changedTargets.Count) {
            $conditions.Add('applied')
            if (-not $authorized -or -not $a.requested -or
                @($a.changedTargets | Where-Object { $_ -notin $a.authorization.surfaces }).Count) {
                $out.application = 'authorization-violation'
            } elseif ($out.readiness -ne 'ready') { $out.application = 'readiness-violation' }
            elseif (-not $out.unrelatedPreserved) { $out.application = 'preservation-violation' }
            elseif ($a.failedTargets.Count -or $a.review -ne 'pass' -or -not $a.reviewEvidence -or
                $out.unchangedTargets.Count) { $out.application = 'partial-failure' }
            else { $out.application = 'reviewed'; $out.complete = $true; $conditions.Add('reviewed') }
            if (-not $out.complete -and 'blocked' -notin $conditions) { $conditions.Add('blocked') }
        } elseif ($a.unchangedReviewed -and $out.readiness -eq 'ready' -and
            $a.review -eq 'pass' -and $a.reviewEvidence) {
            $out.application = 'no-op'; $out.complete = $true; $conditions.Add('reviewed')
        } elseif ($a.requested -and $authorized -and $out.readiness -eq 'ready') {
            $out.application = 'authorized-handoff'
        }
    }
    $out.conditions = @($conditions)
    return $out
}

function Get-Mismatches($Actual, $Expected) {
    foreach ($key in $Expected.Keys) {
        $left = ConvertTo-Json -InputObject $Actual[$key] -Depth 50 -Compress
        $right = ConvertTo-Json -InputObject $Expected[$key] -Depth 50 -Compress
        if ($left -cne $right) { "${key}: expected $right; got $left" }
    }
}

try {
    $baseline = Get-Content -LiteralPath (Join-Path $FixtureDirectory 'baseline.json') -Raw | ConvertFrom-Json -AsHashtable
    $suite = Get-Content -LiteralPath (Join-Path $FixtureDirectory 'scenarios.json') -Raw | ConvertFrom-Json -AsHashtable
    $results = @()
    $assertions = 0
    $mutations = 0
    $ids = @{}
    foreach ($scenario in $suite.scenarios) {
        if ($ids.ContainsKey($scenario.id)) { throw "Duplicate scenario: $($scenario.id)" }
        $ids[$scenario.id] = $true
        $inputRecord = Merge-Input $baseline $scenario.input
        $actual = Get-Decision $inputRecord
        $mismatches = @(Get-Mismatches $actual $scenario.expected)
        if ($mismatches.Count) { throw "$($scenario.id): $($mismatches -join '; ')" }
        $assertions += $scenario.expected.Count
        # Prove each oracle rejects an incorrect result, not merely valid JSON.
        $key = @($scenario.expected.Keys)[0]
        $mutated = Merge-Input $actual @{}
        $mutated[$key] = 'deliberately incorrect contract result'
        if (@(Get-Mismatches $mutated $scenario.expected).Count -eq 0) {
            throw "$($scenario.id): failed to reject mutated output"
        }
        $mutations++
        $results += [ordered]@{ id = $scenario.id; input = $inputRecord; expected = $scenario.expected; actual = $actual }
        Write-Host "PASS $($scenario.id) ($($scenario.expected.Count) assertions; incorrect-output mutation rejected)"
    }
    foreach ($number in 1..14) {
        $prefix = 'T{0:00}-' -f $number
        if (-not @($ids.Keys | Where-Object { $_.StartsWith($prefix) }).Count) { throw "Missing coverage: $prefix" }
    }
    if ($OutFile) {
        $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)
        $null = New-Item -ItemType Directory -Path (Split-Path $path) -Force
        [IO.File]::WriteAllText($path, (ConvertTo-Json -InputObject $results -Depth 50) + "`n")
    }
    Write-Host "Theme lifecycle: $($results.Count) scenarios, $assertions assertions, $mutations rejected mutations; T01-T14 covered."
    exit 0
} catch {
    Write-Host "::error::$($_.Exception.Message)"
    exit 1
}

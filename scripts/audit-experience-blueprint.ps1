#!/usr/bin/env pwsh
# audit-experience-blueprint.ps1 — contract checks for an Experience Blueprint (#169)
#
# Implements the required checks in specs/10-experience-blueprint.spec.md §12.
# The input file is ONE example JSON representation used to prove this
# validation logic works end to end (tests/fixtures/experience-blueprints/).
# The spec is implementation-neutral: a downstream MAY represent its blueprint
# in any format that preserves the same concepts and relationships; this
# script's JSON shape is a reference example, not a mandated schema.
#
# Usage:
#   pwsh scripts/audit-experience-blueprint.ps1 -Path <file.json> [-Quiet]
#
# Exit code: 0 if no error-severity findings, 1 otherwise. Warnings never
# fail the run on their own.

param(
    [Parameter(Mandatory)][string]$Path,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Host "::error::experience blueprint file not found: $Path"
    exit 1
}

try {
    $doc = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
} catch {
    Write-Host "::error::failed to parse '$Path' as JSON: $($_.Exception.Message)"
    exit 1
}

$findings = [System.Collections.Generic.List[object]]::new()
function Add-Finding {
    param(
        [Parameter(Mandatory)][ValidateSet('error', 'warning')][string]$Severity,
        [Parameter(Mandatory)][string]$Rule,
        [Parameter(Mandatory)][string]$Message
    )
    $findings.Add([pscustomobject]@{ severity = $Severity; rule = $Rule; message = $Message })
}

# Required moments per archetype (spec 10 §7). Used only to check that every
# required moment for a declared archetype is represented by >=1 artifact.
$archetypeMoments = @{
    'marketing-home'   = @('hero', 'proof', 'benefits', 'conversion', 'footer')
    'campaign-splash'  = @('message', 'proof', 'primary-action', 'legal')
    'commerce'         = @('discovery', 'detail', 'cart', 'checkout', 'confirmation')
    'dashboard'        = @('overview', 'drill-down', 'filters', 'alerts', 'empty-error')
    'control-tower'    = @('situation-view', 'queue', 'detail', 'action', 'escalation')
    'workflow-app'     = @('start', 'progress', 'validation', 'review', 'completion')
    'docs-knowledge'   = @('browse', 'search', 'article', 'related-content', 'feedback')
    'admin-settings'   = @('overview', 'categories', 'edit', 'validation', 'audit-history')
}

function Get-Prop($obj, [string]$name, $default = $null) {
    if ($null -eq $obj) { return $default }
    $p = $obj.PSObject.Properties[$name]
    if ($null -eq $p) { return $default }
    return $p.Value
}

$mode      = Get-Prop $doc 'mode'
$layouts   = @(Get-Prop $doc 'layouts' @())
$pages     = @(Get-Prop $doc 'pages' @())
$flows     = @(Get-Prop $doc 'flows' @())
$evidence  = @(Get-Prop $doc 'evidence' @())
$findingsIn = @(Get-Prop $doc 'findings' @())
$archetypes = Get-Prop $doc 'archetypes' $null
$moments   = Get-Prop $doc 'moments' $null
$summary   = Get-Prop $doc 'summary' $null

if (-not $mode -or ($mode -ne 'audit' -and $mode -ne 'generate')) {
    Add-Finding -Severity error -Rule 'required-concepts' -Message "top-level 'mode' MUST be 'audit' or 'generate'"
}
if ($layouts.Count -eq 0) { Add-Finding -Severity error -Rule 'required-concepts' -Message "no layouts present" }
if ($pages.Count -eq 0)   { Add-Finding -Severity error -Rule 'required-concepts' -Message "no pages present" }
if ($flows.Count -eq 0)   { Add-Finding -Severity error -Rule 'required-concepts' -Message "no flows present" }

# --- 1. Identifier uniqueness across all artifact collections ---------------
$allIds = [System.Collections.Generic.Dictionary[string,string]]::new()
function Register-Id([string]$id, [string]$kind) {
    if (-not $id) { return }
    if ($allIds.ContainsKey($id)) {
        Add-Finding -Severity error -Rule 'identifier-uniqueness' -Message "duplicate identifier '$id' used by both $($allIds[$id]) and $kind"
    } else {
        $allIds[$id] = $kind
    }
}
foreach ($l in $layouts)  { Register-Id $l.id 'layout' }
foreach ($p in $pages)    { Register-Id $p.id 'page' }
foreach ($f in $flows)    { Register-Id $f.id 'flow' }
foreach ($e in $evidence) { Register-Id $e.id 'evidence' }
foreach ($fi in $findingsIn) { Register-Id $fi.id 'finding' }

$layoutIds = @($layouts | ForEach-Object { $_.id })
$pageIds   = @($pages   | ForEach-Object { $_.id })
$evidenceIds = @($evidence | ForEach-Object { $_.id })

# --- 2. Every page references a valid layout --------------------------------
foreach ($p in $pages) {
    if (-not $p.layout) {
        Add-Finding -Severity error -Rule 'page-layout-reference' -Message "page '$($p.id)' has no layout reference"
    } elseif ($layoutIds -notcontains $p.layout) {
        Add-Finding -Severity error -Rule 'page-layout-reference' -Message "page '$($p.id)' references unknown layout '$($p.layout)'"
    }
}

# --- 3. Every flow step references a valid page or declared external touchpoint --
foreach ($f in $flows) {
    $steps = @(Get-Prop $f 'steps' @())
    if ($steps.Count -eq 0) {
        Add-Finding -Severity error -Rule 'flow-step-reference' -Message "flow '$($f.id)' has no steps"
        continue
    }
    for ($i = 0; $i -lt $steps.Count; $i++) {
        $step = $steps[$i]
        $page = Get-Prop $step 'page'
        $external = Get-Prop $step 'external'
        if ($page) {
            if ($pageIds -notcontains $page) {
                Add-Finding -Severity error -Rule 'flow-step-reference' -Message "flow '$($f.id)' step $($i+1) references unknown page '$page'"
            }
        } elseif (-not $external) {
            Add-Finding -Severity error -Rule 'flow-step-reference' -Message "flow '$($f.id)' step $($i+1) has neither a page nor a declared external touchpoint"
        }
    }
    if (-not (Get-Prop $f 'recovery') -and -not (Get-Prop $f 'cancellation')) {
        Add-Finding -Severity warning -Rule 'flow-recovery' -Message "flow '$($f.id)' declares no recovery or cancellation path"
    }
}

# --- 4. Every responsive page has breakpoint behavior -----------------------
foreach ($p in $pages) {
    if (Get-Prop $p 'responsive') {
        $bp = @(Get-Prop $p 'breakpoints' @())
        if ($bp.Count -eq 0) {
            Add-Finding -Severity error -Rule 'responsive-coverage' -Message "page '$($p.id)' is responsive but declares no breakpoint behavior"
        }
    }
}

# --- 5. Required page states present or explicitly 'not-applicable' --------
$requiredStateSet = @('default', 'loading', 'empty', 'error', 'success', 'permission')
foreach ($p in $pages) {
    $states = Get-Prop $p 'states' $null
    if ($null -eq $states) {
        Add-Finding -Severity error -Rule 'state-coverage' -Message "page '$($p.id)' declares no states"
        continue
    }
    foreach ($s in $requiredStateSet) {
        $val = Get-Prop $states $s $null
        if ($null -eq $val) {
            Add-Finding -Severity error -Rule 'state-coverage' -Message "page '$($p.id)' is missing required state '$s' (or an explicit 'not-applicable')"
        }
    }
}

# --- 6. Audit findings reference valid evidence and artifact IDs -----------
if ($mode -eq 'audit') {
    foreach ($fi in $findingsIn) {
        $evIds = @(Get-Prop $fi 'evidenceIds' @())
        if ($evIds.Count -eq 0) {
            Add-Finding -Severity error -Rule 'finding-evidence-reference' -Message "finding '$($fi.id)' cites no evidence"
        }
        foreach ($ev in $evIds) {
            if ($evidenceIds -notcontains $ev) {
                Add-Finding -Severity error -Rule 'finding-evidence-reference' -Message "finding '$($fi.id)' references unknown evidence '$ev'"
            }
        }
        $artIds = @(Get-Prop $fi 'artifactIds' @())
        if ($artIds.Count -eq 0) {
            Add-Finding -Severity error -Rule 'finding-artifact-reference' -Message "finding '$($fi.id)' references no affected artifact"
        }
        foreach ($art in $artIds) {
            if (-not $allIds.ContainsKey($art)) {
                Add-Finding -Severity error -Rule 'finding-artifact-reference' -Message "finding '$($fi.id)' references unknown artifact '$art'"
            }
        }
    }
}

# --- 7. Generated/rendered summaries identify their authoritative sources --
if ($summary) {
    $sources = @(Get-Prop $summary 'sources' @())
    if ($sources.Count -eq 0) {
        Add-Finding -Severity error -Rule 'documentation-provenance' -Message "summary declares no authoritative sources"
    }
} elseif ($mode -eq 'generate') {
    Add-Finding -Severity error -Rule 'documentation-provenance' -Message "generate-mode blueprint has no summary/provenance section"
}

# --- 8. Archetype-required moments are represented --------------------------
if ($archetypes) {
    $primary = Get-Prop $archetypes 'primary'
    $supporting = @(Get-Prop $archetypes 'supporting' @())
    $selected = @($primary) + $supporting | Where-Object { $_ }
    foreach ($arch in $selected) {
        if (-not $archetypeMoments.ContainsKey($arch)) {
            Add-Finding -Severity warning -Rule 'archetype-moments' -Message "archetype '$arch' is not one of the eight catalog archetypes; skipping required-moment check (declare it as a custom archetype)"
            continue
        }
        foreach ($moment in $archetypeMoments[$arch]) {
            $represented = $null
            if ($moments) { $represented = Get-Prop $moments $moment $null }
            if (-not $represented -or @($represented).Count -eq 0) {
                Add-Finding -Severity error -Rule 'archetype-moments' -Message "archetype '$arch' required moment '$moment' is not represented by any page or flow"
            }
        }
    }
}

# --- 9. Orphan pages (SHOULD) -----------------------------------------------
$referencedPages = [System.Collections.Generic.HashSet[string]]::new()
foreach ($f in $flows) {
    foreach ($step in @(Get-Prop $f 'steps' @())) {
        $page = Get-Prop $step 'page'
        if ($page) { [void]$referencedPages.Add($page) }
    }
}
foreach ($p in $pages) {
    if (-not $referencedPages.Contains($p.id) -and -not (Get-Prop $p 'isEntryPoint')) {
        Add-Finding -Severity warning -Rule 'orphan-page' -Message "page '$($p.id)' is not reached by any flow step and is not marked as an entry point"
    }
}

# --- report ------------------------------------------------------------------
$errorCount = @($findings | Where-Object { $_.severity -eq 'error' }).Count
$warningCount = @($findings | Where-Object { $_.severity -eq 'warning' }).Count

if (-not $Quiet) {
    if ($findings.Count -eq 0) {
        Write-Host "audit-experience-blueprint: no findings for '$Path'"
    } else {
        $findings | Sort-Object severity, rule | Format-Table -Wrap -AutoSize
        Write-Host "audit-experience-blueprint: $errorCount error(s), $warningCount warning(s) for '$Path'"
    }
}

if ($errorCount -gt 0) { exit 1 }
exit 0

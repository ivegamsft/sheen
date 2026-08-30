#!/usr/bin/env pwsh
# audit-skills-agents.ps1 — unified skills/agents audit framework (#131)
#
# Cross-checks structural integrity across skills/, agents/, instructions/,
# skills/_catalog.md, and sheen.vocab.yaml, catching broken references that
# no single existing lint covers (e.g. skills present on disk but missing
# from the catalog — undiscoverable via routing). Also wraps two existing
# validation scripts (lint-router.ps1, audit-evals.ps1) that were previously
# only *referenced* in publish-to-production.yml's strip-list and never
# actually executed as a CI gate.
#
# Usage:
#   pwsh scripts/audit-skills-agents.ps1 [-OutFile <path>] [-MinimumEvalScore <n>] [-Quiet]
#
# Exit code: 0 if no error-severity findings, 1 otherwise. Warnings never
# fail the run on their own.
#
# Output: a JSON findings report (default dist/audit/skills-agents-findings.json,
# git-ignored build output) consumed by scripts/file-audit-issues.ps1 to file
# GitHub issues for open findings.

param(
    [string]$OutFile = 'dist/audit/skills-agents-findings.json',
    [double]$MinimumEvalScore = 7.0,
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'eval-routing-lib.ps1')

$repoRoot = Get-RepoRoot -Start $PSScriptRoot
$skillsDir = Join-Path $repoRoot 'skills'
$agentsDir = Join-Path $repoRoot 'agents'
$instructionsDir = Join-Path $repoRoot 'instructions'
$catalogPath = Join-Path $repoRoot 'skills' '_catalog.md'

$findings = [System.Collections.Generic.List[object]]::new()

function Add-Finding {
    param(
        [Parameter(Mandatory)][ValidateSet('error', 'warning')][string]$Severity,
        [Parameter(Mandatory)][string]$Category,
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$Message
    )
    $id = "$Category|$Target|$Message"
    $hash = [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($id))
    ).Replace('-', '').Substring(0, 16).ToLowerInvariant()
    $findings.Add([pscustomobject]@{
        id       = $hash
        severity = $Severity
        category = $Category
        target   = $Target
        message  = $Message
    })
}

# --- helpers -----------------------------------------------------------

function Get-KebabTokensFromLine {
    param([string]$Line)
    [regex]::Matches($Line, '`([a-z0-9][a-z0-9-]*)`') | ForEach-Object { $_.Groups[1].Value }
}

# --- 1. Skill folder / frontmatter conventions --------------------------

$skillNames = @()
if (Test-Path -LiteralPath $skillsDir) {
    $skillDirs = Get-ChildItem -LiteralPath $skillsDir -Directory
    $skillNames = @($skillDirs | ForEach-Object { $_.Name })
    foreach ($dir in $skillDirs) {
        $name = $dir.Name
        $skillMd = Join-Path $dir.FullName 'SKILL.md'
        if (-not (Test-Path -LiteralPath $skillMd)) {
            Add-Finding -Severity error -Category 'skill-structure' -Target "skills/$name" -Message "Missing SKILL.md"
            continue
        }
        $content = Get-Content -LiteralPath $skillMd -Raw
        if ($content -notmatch "(?m)^name:\s*$name\s*$") {
            Add-Finding -Severity error -Category 'skill-structure' -Target "skills/$name/SKILL.md" -Message "frontmatter 'name' does not equal folder name '$name'"
        }
        if ($content -notmatch 'description:\s*"[^"]*USE FOR:') {
            Add-Finding -Severity warning -Category 'skill-description' -Target "skills/$name/SKILL.md" -Message "description is missing a 'USE FOR:' clause"
        }
        if ($content -notmatch 'DO NOT USE FOR:') {
            Add-Finding -Severity warning -Category 'skill-description' -Target "skills/$name/SKILL.md" -Message "description is missing a 'DO NOT USE FOR:' clause"
        }
        if (-not (Test-Path -LiteralPath (Join-Path $dir.FullName 'eval.yaml'))) {
            Add-Finding -Severity warning -Category 'skill-structure' -Target "skills/$name" -Message "no eval.yaml (routing eval coverage missing)"
        }
    }
}

# --- 2. Agent folder / frontmatter conventions --------------------------

$agentNames = @()
if (Test-Path -LiteralPath $agentsDir) {
    $agentFiles = Get-ChildItem -LiteralPath $agentsDir -Filter '*.agent.md'
    $agentNames = @($agentFiles | ForEach-Object { $_.Name -replace '\.agent\.md$', '' })
    foreach ($file in $agentFiles) {
        $name = $file.Name -replace '\.agent\.md$', ''
        $content = Get-Content -LiteralPath $file.FullName -Raw
        if ($content -notmatch "(?m)^name:\s*$name\s*$") {
            Add-Finding -Severity error -Category 'agent-structure' -Target "agents/$($file.Name)" -Message "frontmatter 'name' does not equal file basename '$name'"
        }
        if ($content -notmatch 'description:\s*"[^"]*USE FOR:') {
            Add-Finding -Severity warning -Category 'agent-description' -Target "agents/$($file.Name)" -Message "description is missing a 'USE FOR:' clause"
        }
        if ($content -notmatch 'DO NOT USE FOR:') {
            Add-Finding -Severity warning -Category 'agent-description' -Target "agents/$($file.Name)" -Message "description is missing a 'DO NOT USE FOR:' clause"
        }
        $evalPath = Join-Path $agentsDir "$name.agent.eval.yaml"
        if (-not (Test-Path -LiteralPath $evalPath)) {
            Add-Finding -Severity warning -Category 'agent-structure' -Target "agents/$($file.Name)" -Message "no $name.agent.eval.yaml (routing eval coverage missing)"
        }

        # --- composes.skills[] / composes.instructions[] must resolve ---
        # NOTE: use [\s\S] (not the (?s) dotall modifier) for the outer,
        # genuinely multi-line capture, and plain '.' (no dotall) for the
        # inner per-bullet regexes so they stay bounded to a single line —
        # mixing (?ms) into both let '.' swallow following lines/sections.
        if ($content -match '(?m)^composes:\s*\n([\s\S]*?)(?=\nallowed-tools:|\n---)') {
            $composeBlock = $Matches[1]
            if ($composeBlock -match '(?m)^\s{2}skills:\s*\n((?:\s{4}-\s*\S.*\n?)*)') {
                foreach ($line in ($Matches[1] -split "`n")) {
                    if ($line -match '^\s{4}-\s*(\S+)') {
                        $ref = $Matches[1].Trim()
                        if ($skillNames -notcontains $ref) {
                            Add-Finding -Severity error -Category 'agent-composes' -Target "agents/$($file.Name)" -Message "composes.skills references unknown skill '$ref'"
                        }
                    }
                }
            }
            if ($composeBlock -match '(?m)^\s{2}instructions:\s*\n((?:\s{4}-\s*\S.*\n?)*)') {
                foreach ($line in ($Matches[1] -split "`n")) {
                    if ($line -match '^\s{4}-\s*(\S+)') {
                        $ref = $Matches[1].Trim()
                        $instrPath = Join-Path $instructionsDir "$ref.instructions.md"
                        if (-not (Test-Path -LiteralPath $instrPath)) {
                            Add-Finding -Severity error -Category 'agent-composes' -Target "agents/$($file.Name)" -Message "composes.instructions references unknown instruction '$ref' (expected $ref.instructions.md)"
                        }
                    }
                }
            }
        }
    }
}

# --- 3. Catalog completeness, both directions ---------------------------

if (Test-Path -LiteralPath $catalogPath) {
    $catalogLines = Get-Content -LiteralPath $catalogPath

    # 3a. Every `skills/<name>/` reference in the catalog exists on disk.
    $catalogRefs = @()
    foreach ($line in $catalogLines) {
        if ($line -match '^\s*-\s+`?skills/([a-z0-9-]+)/?`?\s*$') {
            $catalogRefs += $Matches[1]
        }
    }
    $catalogRefs = @($catalogRefs | Sort-Object -Unique)
    foreach ($ref in $catalogRefs) {
        if ($skillNames -notcontains $ref) {
            Add-Finding -Severity error -Category 'catalog-drift' -Target 'skills/_catalog.md' -Message "references 'skills/$ref/' which does not exist on disk"
        }
    }

    # 3b. Every skill folder on disk is referenced somewhere in the catalog
    #     (new check — the existing CI lint only validates 3a, the inverse
    #     direction, so skills can silently become undiscoverable).
    foreach ($name in $skillNames) {
        if ($catalogRefs -notcontains $name) {
            Add-Finding -Severity error -Category 'catalog-drift' -Target "skills/$name" -Message "skill exists on disk but is not referenced in skills/_catalog.md (undiscoverable via catalog)"
        }
    }
} elseif ($skillNames.Count -gt 0) {
    Add-Finding -Severity error -Category 'catalog-drift' -Target 'skills/_catalog.md' -Message 'skills/ exists but _catalog.md is missing'
}

# --- 4. Skill "Delegates / pairs with" references ------------------------

foreach ($name in $skillNames) {
    $skillMd = Join-Path $skillsDir $name 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillMd)) { continue }
    $content = Get-Content -LiteralPath $skillMd -Raw
    if ($content -notmatch '(?ms)^##\s*Delegates.*?\n(.*?)(\n##|\z)') { continue }
    $section = $Matches[1]
    foreach ($rawLine in ($section -split "`n")) {
        $line = $rawLine.Trim()
        if (-not $line.StartsWith('-')) { continue }
        $line = $line.TrimStart('-').Trim()
        if ($line -match '^spec references?:') { continue }  # file-path refs, not skill/agent names

        $isAgentLine = $line -match '^agent:\s*'
        if ($isAgentLine) { $line = $line -replace '^agent:\s*', '' }

        $tokens = @(Get-KebabTokensFromLine -Line $line)
        if ($tokens.Count -eq 0 -and $line -match '^([a-z0-9][a-z0-9-]*)\s*$') {
            # A bare, unquoted single-token line (no backticks, no prose) —
            # high-confidence reference, e.g. "- logo-usage".
            $tokens = @($Matches[1])
        }
        foreach ($ref in $tokens) {
            if ($ref -like 'specs/*' -or $ref -like '*.md') { continue }
            $known = ($skillNames -contains $ref) -or ($agentNames -contains $ref)
            if (-not $known) {
                Add-Finding -Severity warning -Category 'skill-delegates' -Target "skills/$name/SKILL.md" -Message "'Delegates / pairs with' references unknown skill/agent '$ref'"
            }
        }
    }
}

# --- 5. Wrap lint-router.ps1 -----------------------------------------------

$routerResult = & pwsh -NonInteractive -File (Join-Path $PSScriptRoot 'lint-router.ps1') 2>&1
$routerExit = $LASTEXITCODE
if ($routerExit -ne 0) {
    Add-Finding -Severity error -Category 'router-lint' -Target 'sheen.vocab.yaml' -Message "lint-router.ps1 failed:`n$($routerResult -join "`n")"
}

# --- 6. Wrap audit-evals.ps1 (quality score, not just schema) -------------

$evalResults = Invoke-EvalAudit -RepoRoot $repoRoot -MinimumScore $MinimumEvalScore
foreach ($r in @($evalResults | Where-Object { $_.below_threshold })) {
    Add-Finding -Severity warning -Category 'eval-quality' -Target $r.path -Message ("specificity score {0:n1} is below the minimum {1:n1}" -f $r.score, $MinimumEvalScore)
}

# --- report ---------------------------------------------------------------

$errorCount = @($findings | Where-Object { $_.severity -eq 'error' }).Count
$warningCount = @($findings | Where-Object { $_.severity -eq 'warning' }).Count

if (-not $Quiet) {
    if ($findings.Count -eq 0) {
        Write-Host "audit-skills-agents: no findings across $($skillNames.Count) skills, $($agentNames.Count) agents."
    } else {
        $findings | Sort-Object severity, category, target |
            Select-Object severity, category, target, message |
            Format-Table -Wrap -AutoSize
        Write-Host "audit-skills-agents: $errorCount error(s), $warningCount warning(s) across $($skillNames.Count) skills, $($agentNames.Count) agents."
    }
}

$report = [pscustomobject]@{
    generated_at  = (Get-Date).ToUniversalTime().ToString('o')
    skill_count   = $skillNames.Count
    agent_count   = $agentNames.Count
    error_count   = $errorCount
    warning_count = $warningCount
    findings      = @($findings | Sort-Object severity, category, target)
}

if ($OutFile) {
    $fullOutFile = if ([System.IO.Path]::IsPathRooted($OutFile)) { $OutFile } else { Join-Path $repoRoot $OutFile }
    $dir = Split-Path -Parent $fullOutFile
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $fullOutFile -Encoding UTF8
    if (-not $Quiet) { Write-Host "JSON report: $fullOutFile" }
}

if ($errorCount -gt 0) { exit 1 }
exit 0

#!/usr/bin/env pwsh
# build-system-atlas.ps1 — Generate docs/reference/system-atlas.md: three
# documentation-diagram renders (#113, epic #110) that explain how sheen's
# own agents, skills, and prompts (intents) relate to each other, built
# entirely from real repository data — never fabricated sample content.
#
#   1. Org chart  — sheen router -> 6 pillars/agents -> each agent's
#                    composed skills. Source: .github/skills/sheen/SKILL.md
#                    "Pillars & Agents" table + agents/*.agent.md frontmatter
#                    (composes.skills).
#   2. Treemap    — skill catalog by category, sized by skill count.
#                    Source: skills/_catalog.md.
#   3. Sankey     — prompt routing flow: Prompt -> pillar -> agent. Source:
#                    the same Pillars & Agents table.
#
# This mirrors the icon-gallery.md / build-icons.ps1 pattern: the diagrams
# are rendered to self-contained HTML via render-diagram.ps1, then the
# inline <svg>...</svg> fragment is extracted and inlined directly into the
# generated markdown page so it renders without a build step. Requires
# dist/diagram-skins/<theme>.json and dist/icons/manifest.json to already
# exist (built by build-diagram-skins.ps1 / build-icons.ps1).
#
# Usage:
#   pwsh scripts/build-system-atlas.ps1            # regenerate the page
#   pwsh scripts/build-system-atlas.ps1 -Check      # verify it's up to date

param(
    [switch]$Check,
    [ValidateSet('light', 'dark', 'high-contrast')]
    [string]$Theme = 'light'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$repoRoot = $repoRoot.Trim()

$skillMd    = Join-Path $repoRoot '.github' 'skills' 'sheen' 'SKILL.md'
$catalogMd  = Join-Path $repoRoot 'skills' '_catalog.md'
$agentsDir  = Join-Path $repoRoot 'agents'
$outPath    = Join-Path $repoRoot 'docs' 'reference' 'system-atlas.md'
$renderScript = Join-Path $PSScriptRoot 'render-diagram.ps1'
$workDir    = Join-Path $repoRoot 'dist' 'system-atlas-out'

foreach ($f in @($skillMd, $catalogMd)) {
    if (-not (Test-Path $f)) { throw "Required source file not found: $f" }
}

# ── 1. Parse "Pillars & Agents" table from the sheen router SKILL.md ────────

$skillLines = Get-Content $skillMd
$pillars = @()
$inTable = $false
foreach ($line in $skillLines) {
    if ($line -match '^## Pillars & Agents') { $inTable = $true; continue }
    if ($inTable -and $line -match '^## ') { break }
    if ($inTable -and $line -match '^\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*`@(.+?)`\s*\|\s*$') {
        $pillars += [pscustomobject]@{
            Pillar   = $Matches[1].Trim()
            Keywords = $Matches[2].Trim()
            Agent    = $Matches[3].Trim()
        }
    }
}
if ($pillars.Count -eq 0) { throw "Could not parse Pillars & Agents table from $skillMd" }

# ── 2. Parse each agent's composed skills from its frontmatter ──────────────

function Get-ComposedSkills([string]$agentName) {
    $path = Join-Path $agentsDir "$agentName.agent.md"
    if (-not (Test-Path $path)) { throw "Agent file not found: $path" }
    $lines = Get-Content $path
    $skills = @()
    $inSkills = $false
    foreach ($line in $lines) {
        if ($line -match '^\s*skills:\s*$') { $inSkills = $true; continue }
        if ($inSkills -and $line -match '^\s*-\s*(\S+)\s*$') { $skills += $Matches[1]; continue }
        if ($inSkills -and $line -match '^\s*instructions:\s*$') { break }
        if ($inSkills -and $line -notmatch '^\s*-') { break }
    }
    if ($skills.Count -eq 0) { throw "Could not parse composes.skills for agent '$agentName'" }
    return $skills
}

foreach ($p in $pillars) { $p | Add-Member -NotePropertyName ComposedSkills -NotePropertyValue (Get-ComposedSkills $p.Agent) }

# ── 3. Parse skill catalog categories + counts from skills/_catalog.md ──────

$catalogLines = Get-Content $catalogMd
$categories = [ordered]@{}
$currentCategory = $null
foreach ($line in $catalogLines) {
    if ($line -match '^## (.+)$') { $currentCategory = $Matches[1].Trim(); $categories[$currentCategory] = 0; continue }
    if ($currentCategory -and $line -match '^\s*-\s*skills/') { $categories[$currentCategory] += 1 }
}
if ($categories.Count -eq 0) { throw "Could not parse any categories from $catalogMd" }
$totalSkills = ($categories.Values | Measure-Object -Sum).Sum

# ── 4. Build diagram specs ───────────────────────────────────────────────────

$orgChart = [ordered]@{
    title = 'Sheen router: pillars and agents'
    root  = [ordered]@{
        label    = 'sheen router'
        children = @($pillars | ForEach-Object {
            [ordered]@{ label = "$($_.Pillar) -> @$($_.Agent) ($($_.ComposedSkills.Count) skills)" }
        })
    }
}

$treemap = [ordered]@{
    title = "Sheen skill catalog by category ($totalSkills skills)"
    items = @($categories.GetEnumerator() | ForEach-Object { [ordered]@{ label = $_.Key; value = $_.Value } })
}

$sankeyNodes = @()
$sankeyLinks = @()
$sankeyNodes += [ordered]@{ id = 'prompt'; label = 'Prompt'; column = 0 }
$colIndex = 1
foreach ($p in $pillars) {
    $pillarId = 'pillar-' + ($p.Agent)
    $agentId  = 'agent-' + ($p.Agent)
    $sankeyNodes += [ordered]@{ id = $pillarId; label = $p.Pillar; column = 1 }
    $sankeyNodes += [ordered]@{ id = $agentId; label = "@$($p.Agent)"; column = 2 }
    $sankeyLinks += [ordered]@{ source = 'prompt'; target = $pillarId; value = 1 }
    $sankeyLinks += [ordered]@{ source = $pillarId; target = $agentId; value = 1 }
}
$sankey = [ordered]@{
    title = 'Prompt routing: pillar keyword match -> agent'
    nodes = $sankeyNodes
    links = $sankeyLinks
}

# ── 5. Render each spec, extract inline <svg> fragment ──────────────────────

New-Item -ItemType Directory -Force -Path $workDir | Out-Null

function Render-Spec([string]$type, $spec, [string]$name) {
    $specPath = Join-Path $workDir "$name.json"
    $outHtmlPath = Join-Path $workDir "$name.html"
    ($spec | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath $specPath -Encoding utf8NoBOM
    & pwsh -NonInteractive -File $renderScript -Type $type -SpecPath $specPath -OutPath $outHtmlPath -Theme $Theme -Quiet
    if ($LASTEXITCODE -ne 0) { throw "render-diagram.ps1 failed for '$name' (type=$type)" }
    $html = Get-Content -LiteralPath $outHtmlPath -Raw
    $m = [regex]::Match($html, '(?s)<svg.*?</svg>')
    if (-not $m.Success) { throw "Could not extract <svg> fragment from rendered '$name'" }
    return $m.Value
}

$orgChartSvg = Render-Spec 'org-chart' $orgChart 'org-chart'
$treemapSvg  = Render-Spec 'treemap' $treemap 'treemap'
$sankeySvg   = Render-Spec 'sankey' $sankey 'sankey'

# ── 6. Render the markdown page ──────────────────────────────────────────────

$pillarTableRows = ($pillars | ForEach-Object { "| $($_.Pillar) | @$($_.Agent) | $($_.ComposedSkills.Count) |" }) -join "`n"

$md = @"
---
title: Agents, Skills & Prompts System Atlas
description: Generated diagrams explaining how sheen's agents, skills, and intent routing relate to each other.
---

# Agents, Skills & Prompts System Atlas

> Generated by ``scripts/build-system-atlas.ps1``. Do not hand-edit — re-run
> the script after changing an agent's ``composes.skills``,
> ``skills/_catalog.md``, or the sheen router's Pillars & Agents table.

This page renders sheen's own agent/skill/prompt structure through the
[``documentation-diagram``](https://github.com/IBuySpy-Shared/basecoat-sheen/tree/main/skills/documentation-diagram) skill — every
value below is parsed live from the source files that already define the
system, not hand-authored sample data (issue #149).

## Router structure: pillars and agents

The sheen router (``.github/skills/sheen/SKILL.md``) routes a request to one
of 6 pillar agents; each agent composes a fixed set of skills declared in its
own frontmatter (``composes.skills``, count shown per node below and detailed
in the table beneath the chart).

<figure>
$orgChartSvg
<figcaption>Source: <code>.github/skills/sheen/SKILL.md</code> (Pillars &amp; Agents table) and each agent's <code>composes.skills</code> frontmatter (skill count per node).</figcaption>
</figure>

| Pillar | Agent | Composed skills |
|---|---|---|
$pillarTableRows

## Skill catalog composition

$totalSkills skills are organised into $($categories.Count) categories in
``skills/_catalog.md``. This treemap shows the relative size of each
category — useful for spotting where the catalog is dense (lifecycle /
operations, governance / meta) versus a single-skill category (security &
privacy UX).

<figure>
$treemapSvg
<figcaption>Source: <code>skills/_catalog.md</code>, cross-checked against <code>sheen-metadata.json</code>'s <code>counts.skills</code>.</figcaption>
</figure>

## Prompt routing flow

A prompt is matched against each pillar's keyword list (see the table above)
and routed to exactly one agent. This Sankey traces that fan-out: one
``Prompt`` source flows through all 6 pillars to their agent.

<figure>
$sankeySvg
<figcaption>Source: <code>.github/skills/sheen/SKILL.md</code> Pillars &amp; Agents table.</figcaption>
</figure>

## Related

- [``documentation-diagram`` skill](https://github.com/IBuySpy-Shared/basecoat-sheen/tree/main/skills/documentation-diagram) — the renderer used for every diagram on this page.
- [Skills Catalog](skills-catalog.md) — full skill listing.
- [Agent Roster](agent-roster.md) — agent reference.
- [ADR-005](../decisions/adr-005-diagram-skin-bridge.md) — why diagram colour always comes from DTCG tokens, never a hand-picked hex.
"@

# Normalize line endings before writing/comparing (mirrors build-metadata.ps1's Normalize-JsonText).
function Normalize-Text([string]$text) {
    return (($text -replace "^\uFEFF", '') -replace "`r`n", "`n").TrimEnd() + "`n"
}

$newContent = Normalize-Text $md

if ($Check) {
    if (-not (Test-Path $outPath)) {
        Write-Host "::error::docs/reference/system-atlas.md missing. Run scripts/build-system-atlas.ps1"
        exit 1
    }
    $oldContent = Normalize-Text (Get-Content -LiteralPath $outPath -Raw)
    if ($oldContent -ne $newContent) {
        Write-Host "::error::docs/reference/system-atlas.md is out of date. Run scripts/build-system-atlas.ps1"
        exit 1
    }
    Write-Host "build-system-atlas --check: OK"
    exit 0
}

Set-Content -LiteralPath $outPath -Value $newContent -Encoding utf8NoBOM -NoNewline
Write-Host "build-system-atlas: wrote docs/reference/system-atlas.md ($($pillars.Count) pillars, $totalSkills skills, $($categories.Count) categories)"

#!/usr/bin/env pwsh
param(
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { throw 'Run this inside a git repository' }
Set-Location $repoRoot

# Auto-detect consumer repo: if .sheen/manifest.json present, use consumer asset paths (#87)
$IsConsumer    = Test-Path (Join-Path $repoRoot '.sheen' 'manifest.json')
$SkillsDir     = if ($IsConsumer) { '.github/skills' } else { 'skills' }
$AgentsDir     = if ($IsConsumer) { '.github/agents' } else { 'agents' }
$InstructionsDir = if ($IsConsumer) { '.github/instructions' } else { 'instructions' }
$TokensDir     = if ($IsConsumer) { 'sheen/tokens' } else { 'tokens' }
$PromptsDir    = if ($IsConsumer) { '.github/prompts' } else { 'prompts' }
$TemplatesDir  = if ($IsConsumer) { 'sheen/templates' } else { 'templates' }

$outPath   = Join-Path $repoRoot 'sheen-metadata.json'
$vocabPath = Join-Path $repoRoot 'sheen.vocab.yaml'
$version = if (Test-Path 'version.json') { (Get-Content version.json -Raw | ConvertFrom-Json).version } else { '0.0.0' }

function Get-FrontmatterLines([string]$path) {
    $lines = Get-Content -LiteralPath $path
    if ($lines.Count -lt 3 -or $lines[0].Trim() -ne '---') { return @() }
    $end = -1
    for ($i = 1; $i -lt [Math]::Min(80, $lines.Count); $i++) {
        if ($lines[$i].Trim() -eq '---') { $end = $i; break }
    }
    if ($end -lt 0) { return @() }
    return $lines[1..($end-1)]
}

function Get-FMValue([string[]]$fm, [string]$key) {
    foreach ($line in $fm) {
        if ($line -match "^\s*$([regex]::Escape($key)):\s*(.+?)\s*$") {
            return $Matches[1].Trim().Trim("'`"")
        }
    }
    return $null
}

function Get-Rel([string]$path) {
    return [System.IO.Path]::GetRelativePath($repoRoot, $path).Replace('\','/')
}

function Get-Hash([string]$path) {
    $text = Get-Content -LiteralPath $path -Raw
    $normalized = (($text -replace "^\uFEFF", '') -replace "`r`n", "`n")
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

$skillItems = @()
Get-ChildItem $SkillsDir -Directory -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
    $skillFile = Join-Path $_.FullName 'SKILL.md'
    if (-not (Test-Path $skillFile)) { return }
    $fm = Get-FrontmatterLines $skillFile
    $skillItems += [ordered]@{
        name        = $_.Name
        path        = Get-Rel $skillFile
        folder      = Get-Rel $_.FullName
        category    = Get-FMValue $fm 'category'
        pillar      = Get-FMValue $fm 'pillar'
        maturity    = Get-FMValue $fm 'maturity'
        description = Get-FMValue $fm 'description'
        hash        = Get-Hash $skillFile
    }
}

$agentItems = @()
Get-ChildItem $AgentsDir -Filter '*.agent.md' -File -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
    $fm = Get-FrontmatterLines $_.FullName
    $agentItems += [ordered]@{
        name        = $_.BaseName -replace '\.agent$',''
        path        = Get-Rel $_.FullName
        pillar      = Get-FMValue $fm 'pillar'
        maturity    = Get-FMValue $fm 'maturity'
        description = Get-FMValue $fm 'description'
        hash        = Get-Hash $_.FullName
    }
}

$instructionItems = @()
Get-ChildItem $InstructionsDir -Filter '*.instructions.md' -File -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
    $fm = Get-FrontmatterLines $_.FullName
    $instructionItems += [ordered]@{
        name        = $_.BaseName -replace '\.instructions$',''
        path        = Get-Rel $_.FullName
        band        = Get-FMValue $fm 'band'
        layer       = Get-FMValue $fm 'layer'
        description = Get-FMValue $fm 'description'
        hash        = Get-Hash $_.FullName
    }
}

$themes = @()
Get-ChildItem "$TokensDir\themes" -Filter '*.tokens.json' -File -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
    $themes += [ordered]@{
        name = $_.BaseName -replace '\.tokens$',''
        path = Get-Rel $_.FullName
        hash = Get-Hash $_.FullName
    }
}

$coreCount = (Get-ChildItem "$TokensDir\core" -Filter '*.tokens.json' -File -ErrorAction SilentlyContinue | Measure-Object).Count
$semanticCount = (Get-ChildItem "$TokensDir\semantic" -Filter '*.tokens.json' -File -ErrorAction SilentlyContinue | Measure-Object).Count
$themeCount = $themes.Count
$promptNames = @(
    Get-ChildItem $PromptsDir -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne '.gitkeep' } |
    Sort-Object Name |
    ForEach-Object { $_.BaseName }
)
$templateNames = @(
    Get-ChildItem $TemplatesDir -File -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne '.gitkeep' } |
    Sort-Object FullName |
    ForEach-Object { $_.BaseName }
)

$obj = [ordered]@{
    '$comment' = 'GENERATED FILE — do not hand-edit. Produced by scripts/build-metadata.ps1 from repo-root assets (vendor/ excluded).'
    schema   = 'sheen-metadata/v1'
    name     = 'basecoat-sheen'
    version  = $version
    source = [ordered]@{
        excluded = @('vendor/')
    }
    counts = [ordered]@{
        skills = $skillItems.Count
        agents = $agentItems.Count
        instructions = $instructionItems.Count
        prompts = $promptNames.Count
        templates = $templateNames.Count
        tokens = [ordered]@{
            core = $coreCount
            semantic = $semanticCount
            themes = $themeCount
        }
    }
    assets = [ordered]@{
        skills = @($skillItems | ForEach-Object { $_.name })
        agents = @($agentItems | ForEach-Object { $_.name })
        instructions = @($instructionItems | ForEach-Object { $_.name })
        prompts = $promptNames
        templates = $templateNames
        themes = @($themes | ForEach-Object { $_.name })
    }
    inventory = [ordered]@{
        skills = $skillItems
        agents = $agentItems
        instructions = $instructionItems
        themes = $themes
    }
}

$newJson = ($obj | ConvertTo-Json -Depth 10)
function Normalize-JsonText([string]$text) {
    return (($text -replace "^\uFEFF", '') -replace "`r`n", "`n").TrimEnd()
}

if ($Check) {
    if (-not (Test-Path $outPath)) {
        Write-Host "::error::sheen-metadata.json missing"
        exit 1
    }
    $oldJson = Get-Content $outPath -Raw
    $oldNorm = Normalize-JsonText $oldJson
    $newNorm = Normalize-JsonText $newJson
    if ($oldNorm -ne $newNorm) {
        Write-Host "::error::sheen-metadata.json is out of date. Run scripts/build-metadata.ps1"
        $oldLines = $oldNorm -split "`n"
        $newLines = $newNorm -split "`n"
        $max = [Math]::Max($oldLines.Count, $newLines.Count)
        for ($i = 0; $i -lt $max; $i++) {
            $oldLine = if ($i -lt $oldLines.Count) { $oldLines[$i] } else { '<missing>' }
            $newLine = if ($i -lt $newLines.Count) { $newLines[$i] } else { '<missing>' }
            if ($oldLine -ne $newLine) {
                Write-Host ("::error::first diff at line {0}" -f ($i + 1))
                Write-Host ("::error::expected: {0}" -f $oldLine)
                Write-Host ("::error::actual:   {0}" -f $newLine)
                break
            }
        }
        exit 1
    }
    # Also verify sheen.vocab.yaml is present (content drift check is not needed for
    # the vocab file since it re-derives from the same intents table in this script)
    if (-not (Test-Path $vocabPath)) {
        Write-Host "::error::sheen.vocab.yaml missing. Run scripts/build-metadata.ps1"
        exit 1
    }
    Write-Host "build-metadata --check: OK"
    exit 0
}

Set-Content -LiteralPath $outPath -Value $newJson -Encoding utf8NoBOM
Write-Host "build-metadata: wrote sheen-metadata.json"

# ---------------------------------------------------------------------------
# Emit sheen.vocab.yaml — intent vocabulary derived from skill/agent inventory
# ---------------------------------------------------------------------------

# Static intent definitions keyed to canonical skills and agents.
# When a new intent is needed, add an entry here and re-run this script.
$intents = @(
    [ordered]@{ intent = 'wireframe-a-flow';       keywords = @('wireframe','lo-fi','sketch','flow-diagram');          skill = 'wireframing';         agent = 'ux-designer';               discriminator = 'wireframe' }
    [ordered]@{ intent = 'debate-design-options';  keywords = @('debate','tradeoff','adr','compare','options');        skill = 'design-debate';       agent = 'design-reviewer';           discriminator = 'decision-record' }
    [ordered]@{ intent = 'audit-accessibility';    keywords = @('a11y','accessibility','wcag','aria');                 skill = 'accessibility-audit'; agent = 'accessibility-auditor';     discriminator = 'audit-report' }
    [ordered]@{ intent = 'design-token-schema';    keywords = @('token','tokens','semantic-token','alias');            skill = 'design-tokens';       agent = 'design-system-architect';   discriminator = 'token-spec' }
    [ordered]@{ intent = 'color-system-design';    keywords = @('color','colour','palette','hue');                    skill = 'color-system';        agent = 'design-system-architect';   discriminator = 'token-spec' }
    [ordered]@{ intent = 'typography-scale';       keywords = @('typography','typeface','font','type-scale');         skill = 'typography';          agent = 'design-system-architect';   discriminator = 'token-spec' }
    [ordered]@{ intent = 'theming';                keywords = @('theme','theming','dark-mode','light-mode','high-contrast'); skill = 'theming'; agent = 'design-system-architect';        discriminator = 'token-spec' }
    [ordered]@{ intent = 'css-token-mapping';      keywords = @('css','css-variable','component-token');              skill = 'css-mapping';         agent = 'design-system-architect';   discriminator = 'token-spec' }
    [ordered]@{ intent = 'motion-elevation-design';keywords = @('motion','animation','elevation','shadow');            skill = 'motion-elevation';    agent = 'design-system-architect';   discriminator = 'token-spec' }
    [ordered]@{ intent = 'font-mapping';           keywords = @('font-stack','font-mapping','web-font');              skill = 'font-mapping';        agent = 'design-system-architect';   discriminator = 'token-spec' }
    [ordered]@{ intent = 'brand-identity-review';  keywords = @('brand','brand-identity','visual-identity');          skill = 'brand-identity';      agent = 'brand-steward';             discriminator = 'brand-guide' }
    [ordered]@{ intent = 'logo-usage-review';      keywords = @('logo','logotype','mark','logo-usage');               skill = 'logo-usage';          agent = 'brand-steward';             discriminator = 'brand-guide' }
    [ordered]@{ intent = 'imagery-illustration';   keywords = @('imagery','illustration','photography');              skill = 'imagery-illustration';agent = 'brand-steward';             discriminator = 'brand-guide' }
    [ordered]@{ intent = 'brand-voice-tone';       keywords = @('voice','tone','microcopy','brand-voice');            skill = 'brand-voice-tone';    agent = 'brand-steward';             discriminator = 'brand-guide' }
    [ordered]@{ intent = 'iconography-review';     keywords = @('icon','iconography','pictogram');                    skill = 'iconography';         agent = 'brand-steward';             discriminator = 'brand-guide' }
    [ordered]@{ intent = 'responsive-layout';      keywords = @('responsive','mobile','breakpoint','viewport');       skill = 'responsive-design';   agent = 'ux-designer';               discriminator = 'wireframe' }
    [ordered]@{ intent = 'layout-grid-spacing';    keywords = @('layout','grid','spacing','density');                 skill = 'layout-grid-spacing'; agent = 'ux-designer';               discriminator = 'wireframe' }
    [ordered]@{ intent = 'navigation-design';      keywords = @('navigation','nav','menu','wayfinding');              skill = 'navigation-design';   agent = 'ux-designer';               discriminator = 'ia-artifact' }
    [ordered]@{ intent = 'user-journey-mapping';   keywords = @('user-journey','journey-map','flow','user-flow');    skill = 'user-research';       agent = 'ux-designer';               discriminator = 'audit-report' }
    [ordered]@{ intent = 'ux-writing';             keywords = @('ux-writing','label','cta','help-text','error-text'); skill = 'ux-writing';         agent = 'ux-designer';               discriminator = 'content-spec' }
    [ordered]@{ intent = 'ui-states-interaction';  keywords = @('interaction','state','hover','focus','active');      skill = 'ui-states-interaction'; agent = 'ux-designer';            discriminator = 'component-spec' }
    [ordered]@{ intent = 'landing-page-design';    keywords = @('landing-page','hero','above-fold');                  skill = 'landing-page-design'; agent = 'ux-designer';               discriminator = 'wireframe' }
    [ordered]@{ intent = 'web-usability-review';   keywords = @('usability','heuristic','web-usability');            skill = 'web-usability-review'; agent = 'ux-designer';              discriminator = 'audit-report' }
    [ordered]@{ intent = 'color-contrast-check';   keywords = @('contrast','color-contrast','luminance');            skill = 'color-contrast-check'; agent = 'accessibility-auditor';   discriminator = 'audit-report' }
    [ordered]@{ intent = 'keyboard-focus-audit';   keywords = @('keyboard','focus-ring','tab-order','screen-reader'); skill = 'accessibility-audit'; agent = 'accessibility-auditor';   discriminator = 'audit-report' }
    [ordered]@{ intent = 'usability-mapping';      keywords = @('usability-mapping','usability-score','heuristic-check'); skill = 'usability-mapping'; agent = 'accessibility-auditor'; discriminator = 'audit-report' }
    [ordered]@{ intent = 'ia-taxonomy-design';     keywords = @('taxonomy','classification','hierarchy','category');  skill = 'taxonomy';            agent = 'information-architect';     discriminator = 'ia-artifact' }
    [ordered]@{ intent = 'ontology-design';        keywords = @('ontology','vocabulary','controlled-vocabulary');    skill = 'ontology';            agent = 'information-architect';     discriminator = 'ia-artifact' }
    [ordered]@{ intent = 'sitemap-ia';             keywords = @('ia','information-architecture','sitemap');          skill = 'information-architecture'; agent = 'information-architect'; discriminator = 'ia-artifact' }
    [ordered]@{ intent = 'content-hierarchy';      keywords = @('content-hierarchy','content-model','content-type'); skill = 'content-hierarchy';   agent = 'information-architect';     discriminator = 'ia-artifact' }
    [ordered]@{ intent = 'multilingual-i18n';      keywords = @('multilingual','i18n','l10n','locale','translation'); skill = 'multilingual';        agent = 'information-architect';     discriminator = 'content-spec' }
    [ordered]@{ intent = 'craft-critique';         keywords = @('critique','craft','polish','craft-bar');            skill = 'craft-quality';       agent = 'design-reviewer';           discriminator = 'decision-record' }
    [ordered]@{ intent = 'design-audit';           keywords = @('audit','design-audit','system-audit');              skill = 'design-audit';        agent = 'design-reviewer';           discriminator = 'audit-report' }
    [ordered]@{ intent = 'pattern-library-review'; keywords = @('pattern','pattern-library','component-pattern');   skill = 'pattern-library';     agent = 'design-reviewer';           discriminator = 'component-spec' }
    [ordered]@{ intent = 'secure-ux-review';       keywords = @('secure-ux','privacy-ux','security-design');        skill = 'secure-ux';           agent = 'design-reviewer';           discriminator = 'audit-report' }
    [ordered]@{ intent = 'visual-regression';      keywords = @('regression','visual-regression','snapshot');       skill = 'visual-regression';   agent = 'design-reviewer';           discriminator = 'audit-report' }
    [ordered]@{ intent = 'style-guide-authoring';  keywords = @('style-guide','document-guidelines','component-spec-page'); skill = 'style-guide-authoring'; agent = 'design-reviewer'; discriminator = 'component-spec' }
    [ordered]@{ intent = 'design-system-audit';    keywords = @('design-system-audit','system-health','ds-audit');  skill = 'design-system-audit'; agent = 'design-reviewer';           discriminator = 'audit-report' }
    [ordered]@{ intent = 'component-spec';         keywords = @('component-spec','component-anatomy','spec');       skill = 'component-spec';      agent = 'ux-designer';               discriminator = 'component-spec' }
    [ordered]@{ intent = 'design-handoff';         keywords = @('handoff','design-handoff','dev-handoff');          skill = 'design-handoff';      agent = 'ux-designer';               discriminator = 'handoff-package' }
    [ordered]@{ intent = 'design-exploration';     keywords = @('exploration','ideation','concepts');               skill = 'design-exploration';  agent = 'ux-designer';               discriminator = 'concept-brief' }
    [ordered]@{ intent = 'design-suggest';         keywords = @('suggest','recommend','design-suggest');            skill = 'design-suggest';      agent = 'design-reviewer';           discriminator = 'concept-brief' }
    [ordered]@{ intent = 'design-update';          keywords = @('update','revision','design-update');               skill = 'design-update';       agent = 'design-reviewer';           discriminator = 'design-update' }
    [ordered]@{ intent = 'design-bootstrap';       keywords = @('bootstrap','scaffold','kick-off');                 skill = 'design-bootstrap';    agent = 'design-system-architect';   discriminator = 'design-update' }
    [ordered]@{ intent = 'accessibility-conformance'; keywords = @('conformance','section-508','en-301-549');       skill = 'accessibility-audit'; agent = 'accessibility-auditor';     discriminator = 'audit-report' }
    [ordered]@{ intent = 'i18n-framework-mapping'; keywords = @('i18n-framework','rtl','bidi','language-support');  skill = 'i18n-framework-mapping'; agent = 'information-architect';  discriminator = 'content-spec' }
)

# Validate every intent references a real skill and agent from the inventory
$knownSkills  = $skillItems | ForEach-Object { $_.name }
$knownAgents  = $agentItems | ForEach-Object { $_.name }
$vocabErrors  = @()
foreach ($entry in $intents) {
    if ($entry.skill -notin $knownSkills)  { $vocabErrors += "intent '$($entry.intent)': unknown skill '$($entry.skill)'" }
    if ($entry.agent -notin $knownAgents)  { $vocabErrors += "intent '$($entry.intent)': unknown agent '$($entry.agent)'" }
}
if ($vocabErrors.Count -gt 0) {
    Write-Host "::warning::sheen.vocab.yaml has references to unknown skills/agents:"
    $vocabErrors | ForEach-Object { Write-Host "  $_" }
}

# Emit YAML manually (no external module required)
$vocabLines  = @()
$vocabLines += "# GENERATED FILE — do not hand-edit. Produced by scripts/build-metadata.ps1."
$vocabLines += "# Intent vocabulary for the sheen router (skills/sheen/). Edit intents in"
$vocabLines += "# scripts/build-metadata.ps1 and re-run to update this file."
$vocabLines += "schema: sheen-vocab/v2"
$vocabLines += "version: `"$version`""
$vocabLines += "intents:"
foreach ($entry in $intents) {
    $kws = ($entry.keywords | ForEach-Object { "`"$_`"" }) -join ', '
    $vocabLines += "  - intent: `"$($entry.intent)`""
    $vocabLines += "    keywords: [$kws]"
    $vocabLines += "    skill: `"$($entry.skill)`""
    $vocabLines += "    agent: `"$($entry.agent)`""
    $vocabLines += "    discriminator: `"$($entry.discriminator)`""
}

$vocabContent = $vocabLines -join "`n"
Set-Content -LiteralPath $vocabPath -Value $vocabContent -Encoding utf8NoBOM
Write-Host "build-metadata: wrote sheen.vocab.yaml ($($intents.Count) intents)"
exit 0

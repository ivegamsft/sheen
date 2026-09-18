#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { throw 'Run this inside a git repository' }
Set-Location $repoRoot

$catalogPath = Join-Path $repoRoot 'docs\reference\model-capabilities.json'
if (-not (Test-Path -LiteralPath $catalogPath)) {
    throw 'docs/reference/model-capabilities.json is missing'
}

$catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json -Depth 20
$errors = [System.Collections.Generic.List[string]]::new()
function Add-Err([string]$Message) { [void]$errors.Add($Message) }
function Has-Prop($Object, [string]$Name) {
    if ($null -eq $Object) { return $false }
    return $null -ne ($Object.PSObject.Properties | Where-Object { $_.Name -eq $Name })
}
function Test-TriState($Value) {
    return ($Value -is [bool]) -or ([string]$Value -eq 'unknown')
}
function Get-Frontmatter([string]$Path) {
    $lines = Get-Content -LiteralPath $Path
    if ($lines.Count -lt 3 -or $lines[0] -ne '---') { return '' }
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '---') {
            if ($i -le 1) { return '' }
            return ($lines[1..($i - 1)] -join "`n")
        }
    }
    return ''
}
function Get-ModelPins($Files) {
    $pins = [ordered]@{ total = 0; byModel = @{}; files = @() }
    if ($null -eq $Files) { return $pins }
    foreach ($asset in @($Files)) {
        if ($null -eq $asset) { continue }
        $assetPath = $null
        if ($asset -is [System.IO.FileSystemInfo]) {
            $assetPath = $asset.FullName
        } elseif ($asset -is [string]) {
            $assetPath = $asset
        } elseif ($null -ne $asset -and (Has-Prop $asset 'FullName')) {
            $assetPath = [string]$asset.FullName
        }
        if ([string]::IsNullOrWhiteSpace($assetPath)) {
            $typeName = if ($null -eq $asset) { '<null>' } else { $asset.GetType().FullName }
            Add-Err "model pin scanner received a non-file entry of type $typeName"
            continue
        }
        $frontmatter = Get-Frontmatter $assetPath
        if ($frontmatter -match '(?m)^(model|pinned_model):\s*([^#\r\n]+)') {
            $model = $Matches[2].Trim().Trim('"').Trim("'")
            $pins.total++
            $pins.files += $assetPath
            if (-not $pins.byModel.ContainsKey($model)) { $pins.byModel[$model] = 0 }
            $pins.byModel[$model]++
        }
    }
    return $pins
}
function Get-Files([string]$RelativePath, [string]$Filter, [switch]$Recurse) {
    $path = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    return @(Get-ChildItem -LiteralPath $path -Filter $Filter -File -Recurse:$Recurse -ErrorAction SilentlyContinue)
}
function Assert-Count([string]$Field, [int]$Actual) {
    if (-not (Has-Prop $catalog.assignment_audit $Field)) {
        Add-Err "assignment_audit missing $Field"
        return
    }
    if ([int]$catalog.assignment_audit.$Field -ne $Actual) {
        Add-Err "assignment_audit.$Field is $($catalog.assignment_audit.$Field), expected $Actual"
    }
}

if ($catalog.schema -ne 'basecoat-model-capabilities/v2') { Add-Err 'schema must be basecoat-model-capabilities/v2' }
foreach ($field in @('owner', 'update_cadence', 'generated_at', 'provenance', 'runtime_surfaces', 'capability_contract', 'models', 'family_aliases', 'assignment_audit')) {
    if (-not (Has-Prop $catalog $field)) { Add-Err "missing top-level field: $field" }
}
if (@($catalog.runtime_surfaces).Count -eq 0) { Add-Err 'runtime_surfaces must not be empty' }
if (@($catalog.models).Count -eq 0) { Add-Err 'models must not be empty' }

if ($catalog.provenance) {
    foreach ($field in @('source', 'evidence_time', 'copilot_cli_version', 'copilot_session', 'repository_audit_revision', 'basecoat_release', 'basecoat_commit', 'refresh', 'limits')) {
        if (-not (Has-Prop $catalog.provenance $field)) { Add-Err "missing provenance.$field" }
    }
}

$surfaceKeys = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($surface in @($catalog.runtime_surfaces)) {
    foreach ($field in @('host', 'surface', 'provider', 'evidence', 'entitlement_scope')) {
        if (-not (Has-Prop $surface $field) -or [string]::IsNullOrWhiteSpace([string]$surface.$field)) {
            Add-Err "runtime surface missing $field"
        }
    }
    if ((Has-Prop $surface 'host') -and (Has-Prop $surface 'surface')) {
        [void]$surfaceKeys.Add("$($surface.host)/$($surface.surface)")
    }
}

$modelIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($model in @($catalog.models)) {
    foreach ($field in @('id', 'provider', 'host', 'surfaces')) {
        if (-not (Has-Prop $model $field)) { Add-Err "model entry missing $field" }
    }
    if (Has-Prop $model 'id') { [void]$modelIds.Add([string]$model.id) }
    if (-not $model.surfaces) { continue }
    foreach ($surfaceName in $model.surfaces.PSObject.Properties.Name) {
        $surface = $model.surfaces.$surfaceName
        if (-not $surfaceKeys.Contains("$($model.host)/$surfaceName")) {
            Add-Err "model '$($model.id)' references undeclared surface '$($model.host)/$surfaceName'"
        }
        foreach ($field in @('supported', 'reasoning_effort_configurable', 'supports_tools', 'supports_long_context')) {
            if (-not (Has-Prop $surface $field)) { Add-Err "model '$($model.id)' surface '$surfaceName' missing $field" }
            elseif (-not (Test-TriState $surface.$field)) { Add-Err "model '$($model.id)' surface '$surfaceName' field '$field' must be boolean or 'unknown'" }
        }
        if ((Has-Prop $surface 'reasoning_effort_configurable') -and $surface.reasoning_effort_configurable -eq $true) {
            if (-not (Has-Prop $surface 'supported_reasoning_efforts') -or @($surface.supported_reasoning_efforts).Count -eq 0) {
                Add-Err "model '$($model.id)' surface '$surfaceName' must list supported_reasoning_efforts"
            }
        }
    }
}

$sourceAgentPins = Get-ModelPins (Get-Files 'agents' '*.agent.md')
$sourceSkillPins = Get-ModelPins (Get-Files 'skills' 'SKILL.md' -Recurse)
$sourcePromptPins = Get-ModelPins (Get-Files 'prompts' '*.md')
$vendoredPromptPins = Get-ModelPins (Get-Files 'vendor\basecoat\prompts' '*.md')

Assert-Count 'source_agents_model_pins' $sourceAgentPins.total
Assert-Count 'source_skills_model_pins' $sourceSkillPins.total
Assert-Count 'source_prompts_model_pins' $sourcePromptPins.total
Assert-Count 'vendored_basecoat_prompts_model_pins' $vendoredPromptPins.total

foreach ($modelName in $vendoredPromptPins.byModel.Keys) {
    if (-not $modelIds.Contains($modelName)) {
        Add-Err "vendored BaseCoat prompt pin '$modelName' is not declared in models"
    }
    $declaredCounts = $catalog.assignment_audit.vendored_basecoat_prompt_model_counts
    if (-not (Has-Prop $declaredCounts $modelName)) {
        Add-Err "assignment_audit.vendored_basecoat_prompt_model_counts missing $modelName"
    } elseif ([int]$declaredCounts.$modelName -ne [int]$vendoredPromptPins.byModel[$modelName]) {
        Add-Err "assignment_audit count for $modelName is $($declaredCounts.$modelName), expected $($vendoredPromptPins.byModel[$modelName])"
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) { Write-Host "::error::$errorMessage" }
    Write-Host "test-model-capabilities: FAILED ($($errors.Count) error(s))"
    exit 1
}

Write-Host 'test-model-capabilities: OK'

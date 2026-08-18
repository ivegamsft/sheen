param(
  [string]$OutputPath = "docs/guides/prompts/generated-sample-prompts.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-FirstPositivePrompt {
  param([string]$EvalPath)

  if (-not (Test-Path -LiteralPath $EvalPath)) { return $null }
  $yaml = Get-Content -LiteralPath $EvalPath -Raw | ConvertFrom-Yaml
  if ($null -eq $yaml -or $null -eq $yaml.scenarios) { return $null }

  foreach ($scenario in $yaml.scenarios) {
    if ($scenario.expect_activation -eq $true -and -not [string]::IsNullOrWhiteSpace($scenario.input)) {
      return ($scenario.input -replace '\s+', ' ').Trim()
    }
  }
  return $null
}

$repoRoot = (Resolve-Path ".").Path
$skillsRoot = Join-Path $repoRoot "skills"
$vocabPath = Join-Path $repoRoot "sheen.vocab.yaml"

if (-not (Test-Path -LiteralPath $skillsRoot)) { throw "skills/ directory not found." }
if (-not (Test-Path -LiteralPath $vocabPath)) { throw "sheen.vocab.yaml not found." }

$vocab = Get-Content -LiteralPath $vocabPath -Raw | ConvertFrom-Yaml
$intents = @($vocab.intents)

$skillDirs = Get-ChildItem -LiteralPath $skillsRoot -Directory |
  Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md") } |
  Sort-Object Name

$skillPrompts = [ordered]@{}
foreach ($dir in $skillDirs) {
  $skillName = $dir.Name
  $evalPath = Join-Path $dir.FullName "eval.yaml"
  $prompt = Get-FirstPositivePrompt -EvalPath $evalPath
  if ([string]::IsNullOrWhiteSpace($prompt)) {
    $prompt = "No eval fixture found for this skill. Add a positive scenario in skills/$skillName/eval.yaml."
  }
  $skillPrompts[$skillName] = $prompt
}

$agentNames = @(
  "design-system-architect",
  "brand-steward",
  "ux-designer",
  "accessibility-auditor",
  "information-architect",
  "design-reviewer"
)

$agentPromptMap = [ordered]@{}
foreach ($agent in $agentNames) {
  $agentPrompts = New-Object System.Collections.Generic.List[string]
  $agentIntents = $intents | Where-Object { $_.agent -eq $agent }
  foreach ($intent in $agentIntents) {
    $skill = [string]$intent.skill
    if ($skillPrompts.Contains($skill)) {
      $candidate = [string]$skillPrompts[$skill]
      if (-not [string]::IsNullOrWhiteSpace($candidate) -and -not $agentPrompts.Contains($candidate)) {
        $agentPrompts.Add($candidate)
      }
    }
    if ($agentPrompts.Count -ge 3) { break }
  }
  if ($agentPrompts.Count -eq 0) {
    $agentPrompts.Add("No mapped skill eval prompts found for this agent.")
  }
  $agentPromptMap[$agent] = @($agentPrompts)
}

$factoryPatterns = @(
  @{
    Name = "Parallel Audit"
    Prompt = "bug: /sheen review run Parallel Audit for checkout flow regressions across accessibility, usability, and governance. Return a unified severity matrix with release recommendation."
  },
  @{
    Name = "Serial Decision-Chain"
    Prompt = "feature: /sheen debate run Serial Decision-Chain to choose dashboard navigation, then produce handoff spec and accessibility validation."
  },
  @{
    Name = "Token Cascade"
    Prompt = "pr: /sheen token run Token Cascade on PR #311 token updates; validate brand alignment, state coverage, and final CSS token mapping."
  }
)

$generatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss 'UTC'")
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Generated Sample Prompts — Agents, Skills, and Factory Patterns")
$lines.Add("")
$lines.Add("> Generated from eval/test fixtures (`skills/*/eval.yaml`) and `sheen.vocab.yaml` by `scripts/generate-sample-prompts.ps1`.")
$lines.Add("> Generated at: $generatedAt")
$lines.Add("")
$lines.Add("## Agent samples (derived from mapped skill eval prompts)")
$lines.Add("")

foreach ($agent in $agentPromptMap.Keys) {
  $lines.Add("### @$agent")
  $lines.Add("")
  $index = 1
  foreach ($prompt in $agentPromptMap[$agent]) {
    $lines.Add("$index. $prompt")
    $index++
  }
  $lines.Add("")
}

$lines.Add("## Skill samples (one positive fixture per skill)")
$lines.Add("")
$lines.Add("| Skill | Prompt sample (from eval fixture) |")
$lines.Add("|---|---|")
foreach ($skill in $skillPrompts.Keys) {
  $sample = [string]$skillPrompts[$skill]
  $sample = $sample.Replace("|", "\|")
  $lines.Add("| $skill | $sample |")
}
$lines.Add("")
$lines.Add("## Factory pattern samples")
$lines.Add("")
$lines.Add("| Pattern | Prompt sample |")
$lines.Add("|---|---|")
foreach ($pattern in $factoryPatterns) {
  $prompt = ([string]$pattern.Prompt).Replace("|", "\|")
  $lines.Add("| **$($pattern.Name)** | $prompt |")
}
$lines.Add("")
$lines.Add("## Intent helper examples")
$lines.Add("")
$lines.Add('- `bug:` immediate remediation')
$lines.Add('- `pr:` PR-lifecycle context')
$lines.Add('- `audit:` read-only review')
$lines.Add('- `feature:` new capability design')
$lines.Add('- `later:` deferred planning')
$lines.Add('- `docs:` documentation-first output')
$lines.Add('- `chore:` maintenance and cleanup')

$outputFile = Join-Path $repoRoot $OutputPath
$outputDir = Split-Path -Parent $outputFile
if (-not (Test-Path -LiteralPath $outputDir)) {
  New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

[System.IO.File]::WriteAllLines($outputFile, $lines)
Write-Host "generated: $OutputPath"

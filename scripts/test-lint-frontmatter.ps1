#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { throw 'Run this inside a git repository' }
$repoRoot = (Resolve-Path -LiteralPath $repoRoot).Path
$lintScript = Join-Path $repoRoot 'scripts\lint-frontmatter.ps1'
$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("sheen-frontmatter-test-" + [guid]::NewGuid().ToString('N'))

function Write-TextFile([string]$Path, [string]$Content) {
    $dir = Split-Path -Parent $Path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Set-Content -LiteralPath $Path -Value $Content -NoNewline -Encoding utf8
}

function New-FixtureRoot([string]$Name) {
    $root = Join-Path $tmpRoot $Name
    New-Item -ItemType Directory -Force -Path $root | Out-Null

    Write-TextFile (Join-Path $root 'skills\example-skill\SKILL.md') @'
---
name: example-skill
compatibility:
  - github-copilot-cli
description: >
  Use when validating folded scalar visibility for strict frontmatter checks.
  USE FOR: folded descriptions, schema validation, routing metadata.
  DO NOT USE FOR: invalid fixtures, backend implementation.
category: design
metadata:
  category: design
  maturity: stable
  audience: [designer, developer]
  pillar: components
allowed-tools: []
---

# example-skill
'@

    Write-TextFile (Join-Path $root 'skills\example-skill\eval.yaml') @'
name: "example-skill-routing"
scenarios:
  - id: "pos-1"
    input: "Use folded descriptions"
    expect_activation: true
  - id: "pos-2"
    input: "Validate schema metadata"
    expect_activation: true
  - id: "pos-3"
    input: "Check routing metadata"
    expect_activation: true
  - id: "neg-1"
    input: "Invalid fixture"
    expect_activation: false
  - id: "neg-2"
    input: "Backend implementation"
    expect_activation: false
'@

    Write-TextFile (Join-Path $root 'agents\example-agent.agent.md') @'
---
name: example-agent
compatibility:
  - github-copilot-cli
description: "Example agent for strict frontmatter fixture."
metadata:
  maturity: draft
  pillar: components
composes:
  skills:
    - example-skill
  instructions:
    - sheen-10-example
allowed-tools: []
---

# example-agent
'@

    Write-TextFile (Join-Path $root 'agents\example-agent.agent.eval.yaml') @'
name: "example-agent-routing"
scenarios:
  - id: "pos-1"
    input: "Use the example agent for component work."
    expect_activation: true
  - id: "pos-2"
    input: "Coordinate example skill output."
    expect_activation: true
  - id: "pos-3"
    input: "Route a design-system request."
    expect_activation: true
  - id: "neg-1"
    input: "Backend implementation."
    expect_activation: false
  - id: "neg-2"
    input: "Database migration."
    expect_activation: false
'@

    Write-TextFile (Join-Path $root 'instructions\sheen-10-example.instructions.md') @'
---
name: sheen-10-example
compatibility:
  - github-copilot-cli
description: "Example path-scoped instruction."
applyTo: "docs/**"
metadata:
  band: 10
  layer: example
---

# example
'@

    return $root
}

function Invoke-Lint([string]$Root) {
    $output = & pwsh -NoProfile -File $lintScript -Root $Root 2>&1
    return @{ exitCode = $LASTEXITCODE; output = ($output -join "`n") }
}

function Assert-Pass([string]$Name, [string]$Root) {
    $result = Invoke-Lint $Root
    if ($result.exitCode -ne 0) {
        throw "$Name expected pass, got exit $($result.exitCode):`n$($result.output)"
    }
}

function Assert-Fail([string]$Name, [string]$Root, [string]$Pattern) {
    $result = Invoke-Lint $Root
    if ($result.exitCode -eq 0 -or $result.output -notmatch $Pattern) {
        throw "$Name expected failure matching '$Pattern', got exit $($result.exitCode):`n$($result.output)"
    }
}

try {
    $valid = New-FixtureRoot 'valid-folded-empty-tools'
    Assert-Pass 'valid folded scalar and empty allowed-tools' $valid

    $validBlockArrays = New-FixtureRoot 'valid-block-arrays'
    $skillPath = Join-Path $validBlockArrays 'skills\example-skill\SKILL.md'
    $text = (Get-Content -LiteralPath $skillPath -Raw).Replace('allowed-tools: []', "allowed-tools:`n  - read")
    Set-Content -LiteralPath $skillPath -Value $text -NoNewline
    Assert-Pass 'valid block sequence arrays' $validBlockArrays

    $duplicate = New-FixtureRoot 'duplicate-top-level'
    Add-Content -LiteralPath (Join-Path $duplicate 'skills\example-skill\SKILL.md') -Value ''
    $skillPath = Join-Path $duplicate 'skills\example-skill\SKILL.md'
    $text = Get-Content -LiteralPath $skillPath -Raw
    $text = $text.Replace("category: design`r`nmetadata:", "category: design`r`ncategory: design`r`nmetadata:")
    $text = $text.Replace("category: design`nmetadata:", "category: design`ncategory: design`nmetadata:")
    Set-Content -LiteralPath $skillPath -Value $text -NoNewline
    Assert-Fail 'duplicate top-level key' $duplicate 'duplicate frontmatter key'

    $malformed = New-FixtureRoot 'malformed-scalar'
    $skillPath = Join-Path $malformed 'skills\example-skill\SKILL.md'
    $text = Get-Content -LiteralPath $skillPath -Raw
    $text = $text.Replace('description: >', 'description "missing colon"')
    Set-Content -LiteralPath $skillPath -Value $text -NoNewline
    Assert-Fail 'malformed scalar line' $malformed 'malformed or unsupported frontmatter line'

    $badEscape = New-FixtureRoot 'invalid-quoted-escape'
    $agentPath = Join-Path $badEscape 'agents\example-agent.agent.md'
    $text = (Get-Content -LiteralPath $agentPath -Raw).Replace('description: "Example agent for strict frontmatter fixture."', 'description: "bad\q escape"')
    Set-Content -LiteralPath $agentPath -Value $text -NoNewline
    Assert-Fail 'invalid quoted scalar escape' $badEscape 'invalid YAML escape'

    $inlineComment = New-FixtureRoot 'quoted-inline-comment'
    $agentPath = Join-Path $inlineComment 'agents\example-agent.agent.md'
    $text = (Get-Content -LiteralPath $agentPath -Raw).Replace('description: "Example agent for strict frontmatter fixture."', 'description: "Example agent for strict frontmatter fixture." # contract-compliant comment')
    Set-Content -LiteralPath $agentPath -Value $text -NoNewline
    Assert-Pass 'quoted scalar with inline comment' $inlineComment

    $metadataOmission = New-FixtureRoot 'metadata-omission'
    $skillPath = Join-Path $metadataOmission 'skills\example-skill\SKILL.md'
    $text = Get-Content -LiteralPath $skillPath -Raw
    $text = $text.Replace("  pillar: components`r`n", '')
    $text = $text.Replace("  pillar: components`n", '')
    Set-Content -LiteralPath $skillPath -Value $text -NoNewline
    Assert-Fail 'missing metadata pillar' $metadataOmission 'metadata\.pillar|field ''pillar'''

    $negativeScope = New-FixtureRoot 'instruction-negative-scope'
    $instructionPath = Join-Path $negativeScope 'instructions\sheen-10-example.instructions.md'
    $text = (Get-Content -LiteralPath $instructionPath -Raw).Replace('applyTo: "docs/**"', 'applyTo: "**,docs/**"')
    Set-Content -LiteralPath $instructionPath -Value $text -NoNewline
    Assert-Fail 'invalid universal instruction scope' $negativeScope 'universal scope'

    $badArray = New-FixtureRoot 'invalid-array-type'
    $skillPath = Join-Path $badArray 'skills\example-skill\SKILL.md'
    $text = (Get-Content -LiteralPath $skillPath -Raw).Replace('  - github-copilot-cli', '  - github-copilot-cli' + "`n  - true")
    Set-Content -LiteralPath $skillPath -Value $text -NoNewline
    Assert-Fail 'invalid array item type' $badArray 'must contain only non-empty strings'

    $nestedBlockDuplicate = New-FixtureRoot 'nested-block-duplicate'
    $skillPath = Join-Path $nestedBlockDuplicate 'skills\example-skill\SKILL.md'
    $text = (Get-Content -LiteralPath $skillPath -Raw).Replace('  pillar: components', "  pillar: >`n    components`n  pillar: components")
    Set-Content -LiteralPath $skillPath -Value $text -NoNewline
    Assert-Fail 'nested block duplicate key' $nestedBlockDuplicate 'duplicate frontmatter key'

    $badFilename = New-FixtureRoot 'bad-instruction-filename'
    Move-Item -LiteralPath (Join-Path $badFilename 'instructions\sheen-10-example.instructions.md') -Destination (Join-Path $badFilename 'instructions\sheen-00-example.instructions.md')
    Assert-Fail 'invalid instruction band filename' $badFilename 'invalid naming'

    $badComposes = New-FixtureRoot 'invalid-composes-type'
    $agentPath = Join-Path $badComposes 'agents\example-agent.agent.md'
    $text = Get-Content -LiteralPath $agentPath -Raw
    $start = $text.IndexOf("composes:")
    $end = $text.IndexOf("allowed-tools:", $start)
    $text = $text.Substring(0, $start) + "composes: true`n" + $text.Substring($end)
    Set-Content -LiteralPath $agentPath -Value $text -NoNewline
    Assert-Fail 'invalid composes type does not throw' $badComposes 'missing or invalid mapping field ''composes'''

    $inlineArrayContinuation = New-FixtureRoot 'inline-array-continuation'
    $skillPath = Join-Path $inlineArrayContinuation 'skills\example-skill\SKILL.md'
    $text = Get-Content -LiteralPath $skillPath -Raw
    $text = $text.Replace('allowed-tools: []', "allowed-tools: []`n  - read")
    Set-Content -LiteralPath $skillPath -Value $text -NoNewline
    Assert-Fail 'inline array cannot continue as block array' $inlineArrayContinuation 'malformed or unsupported frontmatter line'

    $nullScalar = New-FixtureRoot 'null-description-scalar'
    $agentPath = Join-Path $nullScalar 'agents\example-agent.agent.md'
    $text = (Get-Content -LiteralPath $agentPath -Raw).Replace('description: "Example agent for strict frontmatter fixture."', 'description: null')
    Set-Content -LiteralPath $agentPath -Value $text -NoNewline
    Assert-Fail 'null scalar fails string schema' $nullScalar 'description'

    $floatScalar = New-FixtureRoot 'float-description-scalar'
    $agentPath = Join-Path $floatScalar 'agents\example-agent.agent.md'
    $text = (Get-Content -LiteralPath $agentPath -Raw).Replace('description: "Example agent for strict frontmatter fixture."', 'description: 1.5')
    Set-Content -LiteralPath $agentPath -Value $text -NoNewline
    Assert-Fail 'float scalar fails string schema' $floatScalar 'description'

    $zeroBand = New-FixtureRoot 'zero-band-mismatch'
    $instructionPath = Join-Path $zeroBand 'instructions\sheen-10-example.instructions.md'
    $text = (Get-Content -LiteralPath $instructionPath -Raw).Replace('  band: 10', '  band: 0')
    Set-Content -LiteralPath $instructionPath -Value $text -NoNewline
    Assert-Fail 'zero band mismatch' $zeroBand 'metadata\.band'

    Write-Host 'test-lint-frontmatter: OK'
} finally {
    Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
}

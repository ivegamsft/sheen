#!/usr/bin/env pwsh
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$instructionRoot = Join-Path $repoRoot 'instructions'

$instructionNames = @(
    'sheen-10-core-accessibility'
    'sheen-10-core-design-principles'
    'sheen-20-tokens-naming'
    'sheen-30-components-states'
    'sheen-40-web-usability'
    'sheen-50-brand-voice'
    'sheen-60-ia-navigation'
    'sheen-70-taxonomy-ontology'
    'sheen-80-content-multilingual'
    'sheen-90-standards-conformance'
)

$formerlyUniversalNames = @($instructionNames | Where-Object { $_ -ne 'sheen-20-tokens-naming' })

function Get-ApplyToPatterns([string]$path) {
    $lines = Get-Content -LiteralPath $path
    $line = $lines | Where-Object { $_ -match '^applyTo:\s*["''](.+)["'']\s*$' } | Select-Object -First 1
    if (-not $line) { throw "Missing scalar applyTo frontmatter in '$path'." }
    $value = [regex]::Match($line, '^applyTo:\s*["''](.+)["'']\s*$').Groups[1].Value
    return @($value -split ',' | ForEach-Object { $_.Trim().Replace('\', '/') } | Where-Object { $_ })
}

function Convert-GlobToRegex([string]$glob) {
    $escaped = [regex]::Escape($glob.Replace('\', '/'))
    $escaped = $escaped.Replace('\*\*/', '__DSS__')
    $escaped = $escaped.Replace('\*\*', '__DS__')
    $escaped = $escaped.Replace('\*', '__S__')
    $escaped = $escaped.Replace('\?', '__Q__')
    $escaped = $escaped.Replace('__DSS__', '(?:.*/)?')
    $escaped = $escaped.Replace('__DS__', '.*')
    $escaped = $escaped.Replace('__S__', '[^/]*')
    $escaped = $escaped.Replace('__Q__', '[^/]')
    return "^$escaped$"
}

function Test-PathMatch([string]$path, [string[]]$patterns) {
    $normalized = $path.Replace('\', '/')
    foreach ($pattern in $patterns) {
        if ($normalized -match (Convert-GlobToRegex $pattern)) { return $true }
    }
    return $false
}

$scopes = @{}
foreach ($name in $instructionNames) {
    $path = Join-Path $instructionRoot "$name.instructions.md"
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing scoped instruction '$name'." }
    $patterns = Get-ApplyToPatterns $path
    if ($patterns -contains '**' -or $patterns -contains '**/*') {
        throw "$name retains a universal applyTo pattern."
    }
    $scopes[$name] = $patterns
}

$positiveCases = [ordered]@{
    'sheen-10-core-accessibility'       = 'src/components/Button.tsx'
    'sheen-10-core-design-principles'   = 'tokens/themes/light.tokens.json'
    'sheen-20-tokens-naming'            = 'sheen/tokens/themes/light.tokens.json'
    'sheen-30-components-states'        = 'src/components/Button.tsx'
    'sheen-40-web-usability'            = 'src/pages/Home.tsx'
    'sheen-50-brand-voice'              = 'assets/logo.svg'
    'sheen-60-ia-navigation'            = 'src/navigation/routes.ts'
    'sheen-70-taxonomy-ontology'        = '.github/skills/example/SKILL.md'
    'sheen-80-content-multilingual'      = 'locales/en-US/common.json'
    'sheen-90-standards-conformance'    = 'tokens/themes/light.tokens.json'
}

foreach ($name in $positiveCases.Keys) {
    $sample = $positiveCases[$name]
    if (-not (Test-PathMatch $sample $scopes[$name])) {
        throw "$name does not match its representative design/UI path '$sample'."
    }
}

$negativePaths = @(
    'src/services/BillingService.cs'
    'infra/main.bicep'
    'database/migrations/001-create-user.sql'
    'server/api.ts'
    'src/backend/worker.js'
)

foreach ($sample in $negativePaths) {
    $matches = @($instructionNames | Where-Object { Test-PathMatch $sample $scopes[$_] })
    if ($matches.Count -gt 0) {
        throw "Non-design path '$sample' unexpectedly matches: $($matches -join ', ')."
    }
}

$tsxMatches = @($formerlyUniversalNames | Where-Object { Test-PathMatch 'src/components/Button.tsx' $scopes[$_] })
if ($tsxMatches.Count -lt 7) {
    throw "Representative TSX component loads only $($tsxMatches.Count) scoped instructions; expected at least 7 relevant layers."
}

Write-Host "test-instruction-scopes: OK - $($instructionNames.Count) scoped instructions validated, $($formerlyUniversalNames.Count) universal scopes removed; backend/IaC/data samples match 0; TSX sample matches $($tsxMatches.Count)."

#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Cross-asset coherence check for BaseCoat guidance assets.

.DESCRIPTION
    Scans all agents, skills, and instructions for contradictory guidance,
    overlapping scope, deprecated references, and orphaned skill/tool links.

    Runs as a non-blocking warning in CI — exits 0 even when issues are found
    unless -Strict is specified.

.PARAMETER Path
    Root of the BaseCoat repository. Defaults to the current directory.

.PARAMETER Format
    Output format: 'table' (default), 'json', or 'markdown'.

.PARAMETER Strict
    Exit with code 1 if any conflicts are found (for blocking CI gates).

.PARAMETER Category
    Limit checks to a category: 'conflicts', 'scope', 'orphans', 'deprecated', 'all' (default).

.EXAMPLE
    pwsh scripts/check-coherence.ps1
    pwsh scripts/check-coherence.ps1 -Format markdown
    pwsh scripts/check-coherence.ps1 -Strict -Category conflicts
#>
[CmdletBinding()]
param(
    [string]$Path = (Get-Location).Path,
    [ValidateSet("table", "json", "markdown")]
    [string]$Format = "table",
    [switch]$Strict,
    [ValidateSet("conflicts", "scope", "orphans", "deprecated", "all")]
    [string]$Category = "all"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Set-Location $Path

$issues = @()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Get-Frontmatter {
    param([string]$FilePath)
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return @{} }
    if ($content -match "(?s)^---\s*\n(.+?)\n---") {
        $yaml = $Matches[1]
        $result = @{}
        foreach ($line in ($yaml -split "\n")) {
            if ($line -match "^(\w[\w\-]*)\s*:\s*(.+)$") {
                $result[$Matches[1].Trim()] = $Matches[2].Trim()
            }
        }
        return $result
    }
    return @{}
}

function Get-BodyText {
    param([string]$FilePath)
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return "" }
    # Strip frontmatter
    if ($content -match "(?s)^---\s*\n.+?\n---\s*\n(.*)$") {
        return $Matches[1]
    }
    return $content
}

function New-Issue {
    param(
        [string]$Type,
        [string]$Severity,
        [string]$File1,
        [string]$File2 = "",
        [string]$Message
    )
    return [PSCustomObject]@{
        Type     = $Type
        Severity = $Severity
        File1    = $File1 -replace [regex]::Escape($Path + "\"), "" -replace "\\", "/"
        File2    = $File2 -replace [regex]::Escape($Path + "\"), "" -replace "\\", "/"
        Message  = $Message
    }
}

# ---------------------------------------------------------------------------
# Load all assets
# ---------------------------------------------------------------------------

$agents       = Get-ChildItem agents -Filter "*.agent.md" -File -ErrorAction SilentlyContinue
$skillDirs    = Get-ChildItem skills -Directory -ErrorAction SilentlyContinue
$skillFiles   = $skillDirs | ForEach-Object { Get-Item (Join-Path $_.FullName "SKILL.md") -ErrorAction SilentlyContinue } | Where-Object { $_ }
$instructions = Get-ChildItem instructions -Filter "*.instructions.md" -File -ErrorAction SilentlyContinue

$allFiles = @($agents) + @($skillFiles) + @($instructions)

# ---------------------------------------------------------------------------
# CHECK 1: Orphaned allowed_skills references
# ---------------------------------------------------------------------------

if ($Category -in @("orphans", "all")) {
    if ($Format -ne "json") { Write-Host "Checking orphaned skill references..." -ForegroundColor Cyan }

    $knownSkills = $skillDirs | Select-Object -ExpandProperty Name

    foreach ($agent in $agents) {
        $fm = Get-Frontmatter $agent.FullName
        $allowedSkills = $fm["allowed_skills"]
        if (-not $allowedSkills) { continue }

        # Parse list values (comma-separated or YAML list)
        $skillRefs = $allowedSkills -split "[,\[\]`n]" |
            ForEach-Object { $_.Trim().Trim('"').Trim("'") } |
            Where-Object { $_ -ne "" }

        foreach ($ref in $skillRefs) {
            if ($ref -notin $knownSkills) {
                $issues += New-Issue -Type "orphan" -Severity "warning" `
                    -File1 $agent.FullName `
                    -Message "allowed_skills references '$ref' but no skills/$ref/ directory exists"
            }
        }
    }
}

# ---------------------------------------------------------------------------
# CHECK 2: Keyword contradictions (always X / never X patterns)
# ---------------------------------------------------------------------------

if ($Category -in @("conflicts", "all")) {
    if ($Format -ne "json") { Write-Host "Checking keyword contradictions..." -ForegroundColor Cyan }

    # Extract "always <verb> <noun>" and "never <verb> <noun>" patterns
    $directives = @()
    foreach ($file in $allFiles) {
        $body = Get-BodyText $file.FullName
        $lines = $body -split "\n"
        foreach ($line in $lines) {
            $clean = $line.Trim().ToLower() -replace "[`*_``#]", ""
            if ($clean -match "\b(always|never|do not|must not|must|do)\b (.{5,60})") {
                $polarity = if ($Matches[1] -in @("always","must","do")) { "positive" } else { "negative" }
                $topic = $Matches[2].Trim() -replace "[^\w\s]", "" -replace "\s+", " "
                # Only keep 3-6 word topics for signal quality
                $words = ($topic -split "\s+").Count
                if ($words -ge 2 -and $words -le 6) {
                    $directives += [PSCustomObject]@{
                        File     = $file.FullName
                        Polarity = $polarity
                        Topic    = $topic
                        Line     = $line.Trim()
                    }
                }
            }
        }
    }

    # Find conflicting pairs: same topic, opposite polarity, different files
    $grouped = $directives | Group-Object Topic
    foreach ($group in $grouped) {
        if ($group.Count -lt 2) { continue }
        $pos = $group.Group | Where-Object { $_.Polarity -eq "positive" }
        $neg = $group.Group | Where-Object { $_.Polarity -eq "negative" }
        if ($pos -and $neg) {
            # Only flag if from different files
            $posFiles = $pos | Select-Object -ExpandProperty File -Unique
            $negFiles = $neg | Select-Object -ExpandProperty File -Unique
            $crossFile = $false
            foreach ($pf in $posFiles) {
                foreach ($nf in $negFiles) {
                    if ($pf -ne $nf) { $crossFile = $true; break }
                }
            }
            if ($crossFile) {
                $posFile = $posFiles | Select-Object -First 1
                $negFile = $negFiles | Select-Object -First 1
                $issues += New-Issue -Type "conflict" -Severity "warning" `
                    -File1 $posFile -File2 $negFile `
                    -Message "Contradictory directives on '$($group.Name)': affirmative in $(Split-Path $posFile -Leaf), negative in $(Split-Path $negFile -Leaf)"
            }
        }
    }
}

# ---------------------------------------------------------------------------
# CHECK 3: Overlapping applyTo scope in instructions
# ---------------------------------------------------------------------------

if ($Category -in @("scope", "all")) {
    if ($Format -ne "json") { Write-Host "Checking overlapping instruction scope..." -ForegroundColor Cyan }

    $instrMeta = foreach ($instr in $instructions) {
        $fm = Get-Frontmatter $instr.FullName
        $applyTo = $fm["applyTo"]
        if ($applyTo -and $applyTo -ne '""' -and $applyTo -ne "''") {
            [PSCustomObject]@{ File = $instr.FullName; ApplyTo = $applyTo.Trim('"').Trim("'") }
        }
    }

    # Flag exact duplicate applyTo values across different files
    $scopeGroups = $instrMeta | Group-Object ApplyTo | Where-Object { $_.Count -gt 1 }
    foreach ($group in $scopeGroups) {
        $files = $group.Group | Select-Object -ExpandProperty File
        for ($i = 0; $i -lt $files.Count - 1; $i++) {
            $issues += New-Issue -Type "scope-overlap" -Severity "info" `
                -File1 $files[$i] -File2 $files[$i + 1] `
                -Message "Identical applyTo '$($group.Name)' — potential rule conflicts between these instruction files"
        }
    }

    # Flag overly broad catch-all scope when more specific ones exist
    $broadFiles = $instrMeta | Where-Object { $_.ApplyTo -eq "**/*" }
    $specificFiles = $instrMeta | Where-Object { $_.ApplyTo -ne "**/*" }
    if ($broadFiles -and $specificFiles.Count -gt 3) {
        foreach ($broad in $broadFiles) {
            $issues += New-Issue -Type "scope-broad" -Severity "info" `
                -File1 $broad.File `
                -Message "applyTo '**/*' catches all files — rules here may silently override $($specificFiles.Count) more specific instruction files"
        }
    }
}

# ---------------------------------------------------------------------------
# CHECK 4: Deprecated references
# ---------------------------------------------------------------------------

if ($Category -in @("deprecated", "all")) {
    if ($Format -ne "json") { Write-Host "Checking deprecated references..." -ForegroundColor Cyan }

    # Known deprecated patterns: old path patterns, renamed tools, old conventions
    $deprecatedPatterns = @(
        @{ Pattern = "\.basecoat/";          Message = "References '.basecoat/' — current sync target is '.github/base-coat/'" }
        @{ Pattern = "copilot-instructions"; Message = "References 'copilot-instructions' — prefer '.github/copilot-instructions.md' (full path)" }
        @{ Pattern = "\bmaster\b";           Message = "References 'master' branch — prefer 'main'" }
        @{ Pattern = "gpt-4\b(?!o|-o|-turbo|-vision)"; Message = "References 'gpt-4' without variant — consider 'gpt-4o' or current model" }
        @{ Pattern = "openai/gpt-3";         Message = "References GPT-3 family — outdated model reference" }
    )

    foreach ($file in $allFiles) {
        $body = Get-BodyText $file.FullName
        foreach ($dp in $deprecatedPatterns) {
            if ($body -match $dp.Pattern) {
                $issues += New-Issue -Type "deprecated" -Severity "info" `
                    -File1 $file.FullName `
                    -Message $dp.Message
            }
        }
    }
}

# ---------------------------------------------------------------------------
# CHECK 5: Duplicate frontmatter descriptions
# ---------------------------------------------------------------------------

if ($Category -in @("conflicts", "all")) {
    if ($Format -ne "json") { Write-Host "Checking duplicate descriptions..." -ForegroundColor Cyan }

    $descriptions = @()
    foreach ($file in $allFiles) {
        $fm = Get-Frontmatter $file.FullName
        $desc = $fm["description"]
        if ($desc -and $desc.Length -gt 20) {
            $descriptions += [PSCustomObject]@{ File = $file.FullName; Desc = $desc.ToLower().Trim() }
        }
    }

    $descGroups = $descriptions | Group-Object Desc | Where-Object { $_.Count -gt 1 }
    foreach ($group in $descGroups) {
        $files = $group.Group | Select-Object -ExpandProperty File
        $issues += New-Issue -Type "duplicate-desc" -Severity "warning" `
            -File1 $files[0] -File2 $files[1] `
            -Message "Identical description found in $($group.Count) assets — may indicate copy-paste without customisation"
    }
}

# ---------------------------------------------------------------------------
# Summary and output
# ---------------------------------------------------------------------------

$errorCount   = @($issues | Where-Object { $_.Severity -eq "error" }).Count
$warnCount    = @($issues | Where-Object { $_.Severity -eq "warning" }).Count
$infoCount    = @($issues | Where-Object { $_.Severity -eq "info" }).Count

switch ($Format) {
    "json" {
        @{
            timestamp  = [datetime]::UtcNow.ToString("o")
            total      = $issues.Count
            errors     = $errorCount
            warnings   = $warnCount
            info       = $infoCount
            issues     = $issues
        } | ConvertTo-Json -Depth 5
    }

    "markdown" {
        $lines = @()
        $lines += "## BaseCoat Coherence Report"
        $lines += ""
        $lines += "| Severity | Count |"
        $lines += "|----------|-------|"
        $lines += "| ⛔ Error   | $errorCount |"
        $lines += "| ⚠️ Warning | $warnCount |"
        $lines += "| ℹ️ Info    | $infoCount |"
        $lines += ""
        if ($issues.Count -eq 0) {
            $lines += "_No coherence issues found._"
        } else {
            $lines += "| Type | Severity | File | File 2 | Message |"
            $lines += "|------|----------|------|--------|---------|"
            foreach ($issue in $issues | Sort-Object Severity, Type) {
                $icon = switch ($issue.Severity) { "error" { "⛔" } "warning" { "⚠️" } default { "ℹ️" } }
                $f2 = if ($issue.File2) { $issue.File2 } else { "—" }
                $lines += "| $($issue.Type) | $icon | ``$($issue.File1)`` | ``$f2`` | $($issue.Message) |"
            }
        }
        $lines -join "`n"
    }

    default {
        if ($issues.Count -eq 0) {
            Write-Host "`n  No coherence issues found." -ForegroundColor Green
        } else {
            Write-Host ""
            foreach ($issue in $issues | Sort-Object Severity, Type) {
                $color = switch ($issue.Severity) { "error" { "Red" } "warning" { "Yellow" } default { "DarkGray" } }
                $icon  = switch ($issue.Severity) { "error" { "✗" } "warning" { "⚠" } default { "ℹ" } }
                Write-Host "  $icon [$($issue.Type.ToUpper())] $($issue.Message)" -ForegroundColor $color
                Write-Host "      $($issue.File1)" -ForegroundColor DarkGray
                if ($issue.File2) {
                    Write-Host "      $($issue.File2)" -ForegroundColor DarkGray
                }
            }
        }
        Write-Host ""
        Write-Host "  Coherence check: $($issues.Count) issue(s) — $errorCount error(s), $warnCount warning(s), $infoCount info" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } elseif ($warnCount -gt 0) { "Yellow" } else { "Green" })
    }
}

if ($Strict -and $issues.Count -gt 0) {
    exit 1
}

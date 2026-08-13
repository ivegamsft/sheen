#Requires -Version 5.1
<#
.SYNOPSIS
    Scans session-state for recurring fix patterns and suggests memory candidates.
.PARAMETER SessionPath
    Path to session-state directory. Default: ~/.copilot/session-state
.PARAMETER MinFrequency
    Minimum number of occurrences to flag as a candidate. Default: 2
.PARAMETER Format
    Output format: table (default), json
#>
param(
    [string]$SessionPath = (Join-Path $HOME ".copilot\session-state"),
    [int]$MinFrequency = 2,
    [ValidateSet("table", "json")]
    [string]$Format = "table"
)

# Known high-value fix patterns to scan for
$Patterns = @(
    @{ Name = "PowerShell CRLF corruption"; Keywords = @("Set-Content", "CRLF", "line endings", "Out-File"); Category = "PowerShell" },
    @{ Name = "PowerShell backtick stripping"; Keywords = @("backtick", "-c arg", "escape character", "stripped"); Category = "PowerShell" },
    @{ Name = "Where-Object null array"; Keywords = @("Where-Object", ".Count", "null", "wrap.*@()"); Category = "PowerShell" },
    @{ Name = "gh issue body multiline"; Keywords = @("--body-file", "body.*hang", "heredoc.*PowerShell"); Category = "GitHub CLI" },
    @{ Name = "JSON stdout pollution"; Keywords = @("Write-Host.*json", "progress.*stdout", "Format.*json"); Category = "PowerShell" },
    @{ Name = "ConvertFrom-Json joined string"; Keywords = @("ConvertFrom-Json", "join.*newline", "-join"); Category = "PowerShell" }
)

$Results = @()

if (-not (Test-Path $SessionPath)) {
    Write-Warning "Session path not found: $SessionPath"
    exit 0
}

$CheckpointFiles = Get-ChildItem $SessionPath -Recurse -Filter "*.md" -ErrorAction SilentlyContinue

foreach ($Pattern in $Patterns) {
    $Matches = @()
    foreach ($File in $CheckpointFiles) {
        $Content = Get-Content $File.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $Content) { continue }
        $found = $false
        foreach ($Keyword in $Pattern.Keywords) {
            if ($Content -match $Keyword) { $found = $true; break }
        }
        if ($found) { $Matches += $File.FullName }
    }

    if ($Matches.Count -ge $MinFrequency) {
        $Results += [PSCustomObject]@{
            Pattern   = $Pattern.Name
            Category  = $Pattern.Category
            Frequency = $Matches.Count
            Files     = $Matches -join "; "
            Score     = if ($Matches.Count -ge 4) { "High" } elseif ($Matches.Count -ge 2) { "Medium" } else { "Low" }
        }
    }
}

$Results = $Results | Sort-Object -Property Frequency -Descending

if ($Format -eq "json") {
    $Results | ConvertTo-Json -Depth 3
} else {
    if ($Results.Count -eq 0) {
        Write-Host "No repeat fix patterns found (threshold: $MinFrequency occurrences)"
    } else {
        Write-Host "`nRepeat Fix Patterns — Memory Candidates`n" -ForegroundColor Cyan
        $Results | Format-Table Pattern, Category, Frequency, Score -AutoSize
        Write-Host "`n$($Results.Count) candidate(s) found. Consider promoting high/medium frequency patterns to BaseCoat memory.`n"
    }
}

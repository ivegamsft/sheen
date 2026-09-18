#!/usr/bin/env pwsh
# Portable, skill-local canonical-input and freshness helpers for
# style-guide-authoring (#228). Bundled under skills/style-guide-authoring/
# so a copied skill folder works without any top-level repository script
# (spec 14 section 5.2, H14, H21). Test-GuideFreshness never writes the
# guide, its sources or any metadata/timestamp. Invoke-GuideRefresh also
# remains read-only until an authorized content-regeneration capability is
# provided; it never advances provenance while stale prose remains in place.

Set-StrictMode -Version 3

# Canonical permitted source kinds and their treatment (spec 14 section 5.2).
# Kept as data so docs and tooling cannot silently drift apart.
$script:CanonicalSourceKinds = [ordered]@{
    'approved-guide' = @{ Statuses = @('APPROVED', 'PROPOSED'); Description = 'Existing approved downstream guide/decision; authority for its stated scope.' }
    'token'          = @{ Statuses = @('APPROVED', 'DERIVED');  Description = 'Native design token; mechanical source of truth only when designated by the downstream owner.' }
    'derived'        = @{ Statuses = @('DERIVED');              Description = 'DESIGN.md/AESTHETIC-DIRECTION.md or an equivalent derived artifact; narrative facts require independent approval.' }
    'template'       = @{ Statuses = @('TEMPLATE');             Description = 'Structural recipe only (brand-guidelines/style-guide templates); never a value/asset/identity source.' }
    'placeholder'    = @{ Statuses = @('PROPOSED');              Description = 'Explicitly requested placeholder for template mode only.' }
}
$script:CanonicalStatuses = @('APPROVED', 'PROPOSED', 'DERIVED', 'UNKNOWN', 'TEMPLATE')
$script:SafeSourceIdPattern = '^[A-Za-z0-9][A-Za-z0-9._:-]*\z'

# The ten baseline module IDs from references/module-recipes.md / templates/guide-outline.md.
$script:CanonicalModuleIds = @(
    'orientation', 'foundations', 'identity-assets', 'usage-constraints',
    'visual-foundations', 'typography', 'imagery-illustration', 'voice-messaging',
    'application-patterns', 'resources-governance'
)

# Kinds whose sources materially back a module and therefore require an explicit scope.
$script:ScopeRequiredKinds = @('approved-guide', 'token', 'derived')

function Get-CanonicalSourceKinds {
    <# Returns the canonical source-kind/status map so tests and docs share one definition. #>
    return $script:CanonicalSourceKinds
}

function Get-CanonicalModuleIds {
    <# Returns the ten canonical module/scope IDs. #>
    return @($script:CanonicalModuleIds)
}

function Test-SafeSourceId {
    param([string]$Id)
    return ($Id -is [string]) -and $Id.Trim().Length -gt 0 -and $Id -match $script:SafeSourceIdPattern
}

function Get-FileDigest {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Cannot compute digest; path not found: $Path" }
    $hash = Get-FileHash -LiteralPath $Path -Algorithm SHA256
    return "sha256:$($hash.Hash.ToLowerInvariant())"
}

function Get-TextDigest {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha.ComputeHash($bytes)
        return "sha256:" + (-join ($hashBytes | ForEach-Object { $_.ToString('x2') }))
    } finally { $sha.Dispose() }
}

function Resolve-ManifestSourcePath {
    <#
    .SYNOPSIS
    Resolves a manifest-declared relative path against RepoRoot and confirms
    it stays inside RepoRoot. Never throws: an absolute path or a path that
    escapes RepoRoot (including via '..' traversal) is reported as an
    unresolved path with a Reason, so the caller can degrade the affected
    source to UNKNOWN rather than aborting the whole assessment.
    #>
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$RelativePath)
    try {
        if ([System.IO.Path]::IsPathRooted($RelativePath)) {
            return [ordered]@{ Path = $null; Reason = "absolute path rejected: '$RelativePath'" }
        }
        $rootFull = [System.IO.Path]::GetFullPath($RepoRoot)
        $rootNormalized = $rootFull.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
        $candidateFull = [System.IO.Path]::GetFullPath((Join-Path $rootFull $RelativePath))
    } catch {
        return [ordered]@{ Path = $null; Reason = "invalid source path '$RelativePath': $($_.Exception.Message)" }
    }
    $rootWithSep = $rootNormalized + [System.IO.Path]::DirectorySeparatorChar
    $comparison = if ($IsWindows) { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
    if (-not $candidateFull.Equals($rootNormalized, $comparison) -and -not $candidateFull.StartsWith($rootWithSep, $comparison)) {
        return [ordered]@{ Path = $null; Reason = "path escapes repo root: '$RelativePath'" }
    }

    $current = $rootNormalized
    $candidateRelative = [System.IO.Path]::GetRelativePath($rootNormalized, $candidateFull)
    $segments = $candidateRelative -split '[\\/]'
    foreach ($segment in $segments) {
        if (-not $segment -or $segment -eq '.') { continue }
        $current = Join-Path $current $segment
        try {
            $exists = Test-Path -LiteralPath $current
        } catch {
            return [ordered]@{ Path = $null; Reason = "source path inaccessible: '$RelativePath' ($($_.Exception.Message))" }
        }
        if (-not $exists) { continue }
        try {
            $item = Get-Item -LiteralPath $current -Force
            $isLink = (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
            if ($item.PSObject.Properties['LinkType'] -and $item.LinkType) { $isLink = $true }
            if ($isLink) {
                return [ordered]@{ Path = $null; Reason = "symbolic links and reparse points are not permitted in source paths: '$RelativePath'" }
            }
        } catch {
            return [ordered]@{ Path = $null; Reason = "source path inaccessible: '$RelativePath' ($($_.Exception.Message))" }
        }
    }
    return [ordered]@{ Path = $candidateFull; Reason = $null }
}

function Read-InputsManifest {
    <#
    .SYNOPSIS
    Reads and validates the current-authorized-inputs manifest (JSON).
    Read-only against the manifest itself. Every record is validated before
    use: unique nonempty id, kind in the canonical set, status permitted for
    that kind, scope in the ten canonical module IDs (required for kinds
    that back a module), safe scalar rule/value shape, and a sane
    'equivalentFor' list. Malformed records throw (a manifest-authoring
    defect). A missing/inaccessible/out-of-root source *path* does NOT
    throw; it marks that single source unavailable with a diagnostic
    reason so Test-GuideFreshness can report UNKNOWN for just the affected
    input instead of aborting the whole assessment.
    #>
    param([Parameter(Mandatory)][string]$ManifestPath, [string]$RepoRoot = (Get-Location).Path)
    $raw = Get-Content -LiteralPath $ManifestPath -Raw
    $manifest = $raw | ConvertFrom-Json -AsHashtable
    $sources = @{}
    $index = 0
    foreach ($src in @($manifest.sources)) {
        $index++
        $id = $(if ($src.ContainsKey('id')) { $src.id } else { $null })
        if (-not $id -or -not ($id -is [string]) -or $id.Trim().Length -eq 0) {
            throw "Manifest source #$index has a missing or empty 'id'"
        }
        if (-not (Test-SafeSourceId -Id $id)) {
            throw "Manifest source '$id' has an invalid 'id'; IDs must match $($script:SafeSourceIdPattern)"
        }
        if ($sources.ContainsKey($id)) {
            throw "Manifest source id '$id' is duplicated; rejecting rather than silently overwriting the first definition"
        }

        $kind = $(if ($src.ContainsKey('kind')) { $src.kind } else { $null })
        if (-not $kind -or -not $script:CanonicalSourceKinds.Contains($kind)) {
            throw "Manifest source '$id' has unrecognized kind '$kind'; permitted kinds: $($script:CanonicalSourceKinds.Keys -join ', ')"
        }

        $status = $(if ($src.ContainsKey('status')) { $src.status } else { $null })
        $allowedStatuses = $script:CanonicalSourceKinds[$kind].Statuses
        if (-not $status -or $allowedStatuses -notcontains $status) {
            throw "Manifest source '$id' (kind '$kind') has status '$status', not permitted for this kind; allowed: $($allowedStatuses -join ', ')"
        }

        $scope = $(if ($src.ContainsKey('scope')) { $src.scope } else { $null })
        if ($scope) {
            if ($script:CanonicalModuleIds -notcontains $scope) {
                throw "Manifest source '$id' has scope '$scope', which is not one of the ten canonical module IDs"
            }
        } elseif ($script:ScopeRequiredKinds -contains $kind) {
            throw "Manifest source '$id' (kind '$kind') requires a 'scope' naming one of the ten canonical module IDs"
        }

        $rule = $(if ($src.ContainsKey('rule')) { $src.rule } else { $null })
        if ($null -ne $rule -and -not ($rule -is [string])) { throw "Manifest source '$id' has a non-string 'rule'" }

        $value = $(if ($src.ContainsKey('value')) { $src.value } else { $null })
        if ($null -ne $value -and -not ($value -is [string])) { throw "Manifest source '$id' has a non-scalar 'value'; it must be a plain string" }

        $guideContent = $(if ($src.ContainsKey('guideContent')) { $src.guideContent } else { $null })
        if ($null -ne $guideContent -and -not ($guideContent -is [string])) { throw "Manifest source '$id' has non-string 'guideContent'" }

        $equivalentFor = @()
        if ($src.ContainsKey('equivalentFor') -and $null -ne $src.equivalentFor) {
            $equivalentFor = @($src.equivalentFor)
            foreach ($e in $equivalentFor) {
                if (-not ($e -is [string]) -or $e.Trim().Length -eq 0) { throw "Manifest source '$id' has an invalid (non-string/empty) 'equivalentFor' entry" }
                if (-not (Test-SafeSourceId -Id $e)) { throw "Manifest source '$id' has an invalid 'equivalentFor' entry '$e'; IDs must match $($script:SafeSourceIdPattern)" }
                if ($e -eq $id) { throw "Manifest source '$id' cannot declare itself in its own 'equivalentFor'" }
            }
            $dup = $equivalentFor | Group-Object | Where-Object { $_.Count -gt 1 }
            if ($dup) { throw "Manifest source '$id' has duplicate 'equivalentFor' entries" }
        }

        $current = [ordered]@{
            id                = $id
            kind              = $kind
            scope             = $scope
            status            = $status
            rule              = $rule
            value             = $value
            guideContent      = $guideContent
            equivalentFor     = $equivalentFor
            available         = $true
            unavailableReason = $null
            revision          = $null
        }

        if ($src.ContainsKey('path') -and $src.path) {
            $resolved = Resolve-ManifestSourcePath -RepoRoot $RepoRoot -RelativePath $src.path
            if (-not $resolved.Path) {
                $current.available = $false
                $current.unavailableReason = $resolved.Reason
            } else {
                try {
                    if (Test-Path -LiteralPath $resolved.Path -PathType Leaf) {
                        $current.revision = Get-FileDigest -Path $resolved.Path
                    } else {
                        $current.available = $false
                        $current.unavailableReason = "source file not found: $($src.path)"
                    }
                } catch {
                    $current.available = $false
                    $current.unavailableReason = "source file inaccessible: $($src.path) ($($_.Exception.Message))"
                }
            }
        } elseif ($src.ContainsKey('digest')) {
            if (-not ($src.digest -is [string]) -or $src.digest.Trim().Length -eq 0) {
                throw "Manifest source '$id' has an invalid 'digest'; it must be a non-empty string"
            }
            $current.revision = $src.digest
        } else {
            throw "Manifest source '$id' has neither 'path' nor 'digest'"
        }

        $sources[$id] = $current
    }
    return $sources
}

function ConvertTo-InputManifestSource {
    param([Parameter(Mandatory)][hashtable]$Source, [Parameter(Mandatory)][int]$Index, [string]$RepoRoot = (Get-Location).Path)
    $id = $(if ($Source.ContainsKey('id')) { $Source.id } else { $null })
    if (-not $id -or -not ($id -is [string]) -or $id.Trim().Length -eq 0) {
        throw "Manifest source #$Index has a missing or empty 'id'"
    }
    if (-not (Test-SafeSourceId -Id $id)) {
        throw "Manifest source '$id' has an invalid 'id'; IDs must match $($script:SafeSourceIdPattern)"
    }
    $kind = $(if ($Source.ContainsKey('kind')) { $Source.kind } else { $null })
    if (-not $kind -or -not $script:CanonicalSourceKinds.Contains($kind)) {
        throw "Manifest source '$id' has unrecognized kind '$kind'; permitted kinds: $($script:CanonicalSourceKinds.Keys -join ', ')"
    }
    $status = $(if ($Source.ContainsKey('status')) { $Source.status } else { $null })
    $allowedStatuses = $script:CanonicalSourceKinds[$kind].Statuses
    if (-not $status -or $allowedStatuses -notcontains $status) {
        throw "Manifest source '$id' (kind '$kind') has status '$status', not permitted for this kind; allowed: $($allowedStatuses -join ', ')"
    }
    $scope = $(if ($Source.ContainsKey('scope')) { $Source.scope } else { $null })
    if ($scope) {
        if ($script:CanonicalModuleIds -notcontains $scope) {
            throw "Manifest source '$id' has scope '$scope', which is not one of the ten canonical module IDs"
        }
    } elseif ($script:ScopeRequiredKinds -contains $kind) {
        throw "Manifest source '$id' (kind '$kind') requires a 'scope' naming one of the ten canonical module IDs"
    }
    $rule = $(if ($Source.ContainsKey('rule')) { $Source.rule } else { $null })
    if ($null -ne $rule -and -not ($rule -is [string])) { throw "Manifest source '$id' has a non-string 'rule'" }
    $value = $(if ($Source.ContainsKey('value')) { $Source.value } else { $null })
    if ($null -ne $value -and -not ($value -is [string])) { throw "Manifest source '$id' has a non-scalar 'value'; it must be a plain string" }
    $guideContent = $(if ($Source.ContainsKey('guideContent')) { $Source.guideContent } else { $null })
    if ($null -ne $guideContent -and -not ($guideContent -is [string])) { throw "Manifest source '$id' has non-string 'guideContent'" }
    $equivalentFor = @()
    if ($Source.ContainsKey('equivalentFor') -and $null -ne $Source.equivalentFor) {
        $equivalentFor = @($Source.equivalentFor)
        foreach ($e in $equivalentFor) {
            if (-not ($e -is [string]) -or $e.Trim().Length -eq 0) { throw "Manifest source '$id' has an invalid (non-string/empty) 'equivalentFor' entry" }
            if (-not (Test-SafeSourceId -Id $e)) { throw "Manifest source '$id' has an invalid 'equivalentFor' entry '$e'; IDs must match $($script:SafeSourceIdPattern)" }
            if ($e -eq $id) { throw "Manifest source '$id' cannot declare itself in its own 'equivalentFor'" }
        }
        $dup = $equivalentFor | Group-Object | Where-Object { $_.Count -gt 1 }
        if ($dup) { throw "Manifest source '$id' has duplicate 'equivalentFor' entries" }
    }
    $current = [ordered]@{
        id = $id; kind = $kind; scope = $scope; status = $status; rule = $rule; value = $value
        guideContent = $guideContent; equivalentFor = $equivalentFor
        available = $true; unavailableReason = $null; revision = $null
    }
    if ($Source.ContainsKey('path') -and $Source.path) {
        $resolved = Resolve-ManifestSourcePath -RepoRoot $RepoRoot -RelativePath $Source.path
        if (-not $resolved.Path) {
            $current.available = $false
            $current.unavailableReason = $resolved.Reason
        } else {
            try {
                if (Test-Path -LiteralPath $resolved.Path -PathType Leaf) {
                    $current.revision = Get-FileDigest -Path $resolved.Path
                } else {
                    $current.available = $false
                    $current.unavailableReason = "source file not found: $($Source.path)"
                }
            } catch {
                $current.available = $false
                $current.unavailableReason = "source file inaccessible: $($Source.path) ($($_.Exception.Message))"
            }
        }
    } elseif ($Source.ContainsKey('digest')) {
        if (-not ($Source.digest -is [string]) -or $Source.digest.Trim().Length -eq 0) {
            throw "Manifest source '$id' has an invalid 'digest'; it must be a non-empty string"
        }
        $current.revision = $Source.digest
    } else {
        throw "Manifest source '$id' has neither 'path' nor 'digest'"
    }
    return $current
}

function Read-InputsManifestForFreshness {
    param([Parameter(Mandatory)][string]$ManifestPath, [string]$RepoRoot = (Get-Location).Path)
    $raw = Get-Content -LiteralPath $ManifestPath -Raw
    $manifest = $raw | ConvertFrom-Json -AsHashtable
    $sources = @{}
    $errors = [System.Collections.Generic.List[object]]::new()
    $seenIds = @{}
    $index = 0
    foreach ($src in @($manifest.sources)) {
        $index++
        $id = $(if ($src.ContainsKey('id') -and $src.id -is [string]) { $src.id } else { "source-$index" })
        $scope = $(if ($src.ContainsKey('scope') -and $script:CanonicalModuleIds -contains $src.scope) { $src.scope } else { $null })
        if ($id -and $seenIds.ContainsKey($id)) {
            $priorScope = $(if ($sources.ContainsKey($id)) { $sources[$id].scope } else { $scope })
            $errors.Add([ordered]@{ SourceId = $id; Scope = $priorScope; Reason = "duplicate source id '$id'"; State = 'BLOCKED' })
            continue
        }
        $seenIds[$id] = $true
        try {
            $validated = ConvertTo-InputManifestSource -Source $src -Index $index -RepoRoot $RepoRoot
            $sources[$validated.id] = $validated
        } catch {
            $errors.Add([ordered]@{ SourceId = $id; Scope = $scope; Reason = $_.Exception.Message; State = 'UNKNOWN' })
        }
    }
    return [ordered]@{ Sources = $sources; Errors = @($errors) }
}

function Get-ApprovedInputRows {
    <#
    .SYNOPSIS
    Parses the guide's "Approved inputs" markdown table (guide-outline.md
    shape). Each row also records its own Index/Length in GuideText so
    Invoke-GuideRefresh can splice a precise, targeted replacement without
    touching any other guide content.
    #>
    param([Parameter(Mandatory)][string]$GuideText)
    $rows = [System.Collections.Generic.List[object]]::new()
    $sectionPattern = '(?ims)^###\s+Approved inputs\s*\r?\n(?<section>.*?)(?=^##(?:#)?\s|\z)'
    $sectionMatch = [regex]::Match($GuideText, $sectionPattern)
    if (-not $sectionMatch.Success) { return $rows }
    $sectionText = $sectionMatch.Groups['section'].Value
    $sectionStart = $sectionMatch.Groups['section'].Index
    $expectedHeader = @('Source ID', 'Revision or digest', 'Approval state', 'Supported module or rule')
    $awaitingSeparator = $false
    $tableStarted = $false
    foreach ($m in [regex]::Matches($sectionText, '(?m)^(?<line>.*?)(?:\r?\n|$)')) {
        $line = $m.Groups['line'].Value
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0) { continue }
        if ($tableStarted -and $trimmed -match '^<!--\s*guide-owned:') { break }
        if (-not $tableStarted) {
            if ($trimmed -notmatch '\|') { continue }
            $candidateCells = @($trimmed.Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
            if ($candidateCells.Count -ne 4) { continue }
            $headerMatches = $true
            for ($i = 0; $i -lt $expectedHeader.Count; $i++) {
                if ($candidateCells[$i] -ine $expectedHeader[$i]) { $headerMatches = $false; break }
            }
            if (-not $headerMatches) { continue }
            $awaitingSeparator = $true
            $tableStarted = $true
            continue
        }
        $cells = @($trimmed.Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
        if ($awaitingSeparator) {
            $awaitingSeparator = $false
            if ($cells.Count -eq 4 -and @($cells | Where-Object { $_ -notmatch '^:?-{3,}:?$' }).Count -eq 0) { continue }
            break
        }
        $hasSingleOpeningPipe = $trimmed.StartsWith('|') -and -not $trimmed.StartsWith('||')
        $hasSingleClosingPipe = $trimmed.EndsWith('|') -and -not $trimmed.EndsWith('||')
        if (-not $hasSingleOpeningPipe -or -not $hasSingleClosingPipe -or $cells.Count -ne 4) { continue }
        $rows.Add([ordered]@{
            SourceId       = $cells[0]
            Revision       = $cells[1]
            ApprovalState  = $cells[2]
            SupportedScope = $cells[3]
            Index          = $sectionStart + $m.Index
            Length         = $line.Length
        })
    }
    return $rows
}

function Get-ApprovedInputTableErrors {
    param([Parameter(Mandatory)][string]$GuideText)
    $errors = [System.Collections.Generic.List[object]]::new()
    $sectionPattern = '(?ims)^###\s+Approved inputs\s*\r?\n(?<section>.*?)(?=^##(?:#)?\s|\z)'
    $sectionMatch = [regex]::Match($GuideText, $sectionPattern)
    if (-not $sectionMatch.Success) { return $errors }
    $expectedHeader = @('Source ID', 'Revision or digest', 'Approval state', 'Supported module or rule')
    $tableStarted = $false
    $awaitingSeparator = $false
    $lineNumber = 0
    foreach ($m in [regex]::Matches($sectionMatch.Groups['section'].Value, '(?m)^(?<line>.*?)(?:\r?\n|$)')) {
        $lineNumber++
        $line = $m.Groups['line'].Value
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0) { continue }
        if ($tableStarted -and $trimmed -match '^<!--\s*guide-owned:') { break }
        if (-not $tableStarted) {
            if ($trimmed -notmatch '\|') { continue }
            $candidateCells = @($trimmed.Trim('|') -split '\|')
            $candidateTrimmedCells = @($candidateCells | ForEach-Object { $_.Trim() })
            $candidateFirstCell = if ($candidateTrimmedCells.Count -gt 0) { $candidateTrimmedCells[0] } else { '' }
            if ($candidateFirstCell -ine 'Source ID') {
                if (@($candidateTrimmedCells | Where-Object { $_ -ieq 'Revision or digest' -or $_ -ieq 'Approval state' -or $_ -ieq 'Supported module or rule' }).Count -gt 0) {
                    $errors.Add([ordered]@{ Line = $lineNumber; Scope = ''; Reason = 'malformed-approved-input-header' })
                }
                continue
            }
            $hasSingleOpeningPipe = $trimmed.StartsWith('|') -and -not $trimmed.StartsWith('||')
            $hasSingleClosingPipe = $trimmed.EndsWith('|') -and -not $trimmed.EndsWith('||')
            $headerMatches = $hasSingleOpeningPipe -and $hasSingleClosingPipe -and $candidateTrimmedCells.Count -eq 4
            if ($headerMatches) {
                for ($i = 0; $i -lt $expectedHeader.Count; $i++) {
                    if ($candidateTrimmedCells[$i] -ine $expectedHeader[$i]) { $headerMatches = $false; break }
                }
            }
            if (-not $headerMatches) {
                $errors.Add([ordered]@{ Line = $lineNumber; Scope = ''; Reason = 'malformed-approved-input-header' })
                continue
            }
            $tableStarted = $true
            $awaitingSeparator = $true
            continue
        }
        if ($trimmed -notmatch '\|') {
            $errors.Add([ordered]@{ Line = $lineNumber; Scope = ''; Reason = 'malformed-approved-input-row' })
            continue
        }
        $hasSingleOpeningPipe = $trimmed.StartsWith('|') -and -not $trimmed.StartsWith('||')
        $hasSingleClosingPipe = $trimmed.EndsWith('|') -and -not $trimmed.EndsWith('||')
        $cells = @($trimmed.Trim('|') -split '\|')
        $trimmedCells = @($cells | ForEach-Object { $_.Trim() })
        $firstCell = if ($trimmedCells.Count -gt 0) { $trimmedCells[0] } else { '' }
        if ($awaitingSeparator) {
            $awaitingSeparator = $false
            if (-not $hasSingleOpeningPipe -or -not $hasSingleClosingPipe -or $cells.Count -ne 4 -or
                @($trimmedCells | Where-Object { $_ -notmatch '^:?-{3,}:?$' }).Count -ne 0) {
                $errors.Add([ordered]@{ Line = $lineNumber; Scope = ''; Reason = 'malformed-approved-input-separator' })
            }
            continue
        }
        if (-not $hasSingleOpeningPipe -or -not $hasSingleClosingPipe -or $cells.Count -ne 4) {
            $scope = if ($cells.Count -ge 4) { $cells[3].Trim() } else { '' }
            $errors.Add([ordered]@{ Line = $lineNumber; Scope = $scope; Reason = 'malformed-approved-input-row' })
            continue
        }
        if ($firstCell -ieq 'Source ID' -or @($trimmedCells | Where-Object { $_ -notmatch '^:?-{3,}:?$' }).Count -eq 0) { continue }
    }
    if (-not $tableStarted) {
        $errors.Add([ordered]@{ Line = 0; Scope = ''; Reason = 'missing-approved-input-header' })
    } elseif ($awaitingSeparator) {
        $errors.Add([ordered]@{ Line = $lineNumber; Scope = ''; Reason = 'malformed-approved-input-separator' })
    }
    return $errors
}

function Get-IncludedModuleIds {
    <#
    .SYNOPSIS
    Parses the guide's "Module status" table and returns canonical modules whose
    status explicitly marks them as participating in freshness assessment
    (`included` or `awaiting input`), the per-module statuses, plus whether the
    section exists at all.
    Callers should fall back to other fail-closed heuristics only when the
    section is absent.
    #>
    param([Parameter(Mandatory)][string]$GuideText)
    $modules = [System.Collections.Generic.List[string]]::new()
    $sectionPattern = '(?ims)^###\s+Module status\s*\r?\n(?<section>.*?)(?=^##(?:#)?\s|\z)'
    $sectionMatches = [regex]::Matches($GuideText, $sectionPattern)
    if ($sectionMatches.Count -eq 0) {
        return [ordered]@{ HasSection = $false; IsAuthoritative = $false; IncludedModules = @(); InvalidRows = @(); DuplicateModules = @(); ModuleSourceIds = [ordered]@{}; ModuleStatuses = [ordered]@{} }
    }
    $sectionMatch = $sectionMatches[0]
    $sectionText = $sectionMatch.Groups['section'].Value
    $validStatuses = @('included', 'not applicable', 'awaiting input')
    $expectedHeader = @('Module', 'Status', 'Owner', 'Approved source IDs', 'Missing or proposed items')
    $mentionedModules = [System.Collections.Generic.List[string]]::new()
    $invalidRows = [System.Collections.Generic.List[object]]::new()
    $moduleSourceIds = [ordered]@{}
    $moduleStatuses = [ordered]@{}
    if ($sectionMatches.Count -gt 1) {
        $invalidRows.Add([ordered]@{ Module = $null; Line = 0; Reason = 'duplicate-module-status-section' })
    }
    $lines = $sectionText -split '\r?\n'
    $lineNumber = 0
    $tableStarted = $false
    $awaitingSeparator = $false
    foreach ($line in $lines) {
        $lineNumber++
        $trimmedLine = $line.Trim()
        if ($trimmedLine.Length -eq 0) { continue }
        if (-not $tableStarted) {
            if ($trimmedLine -notmatch '\|') { continue }
            $candidateCells = @($trimmedLine.Trim('|') -split '\|')
            $candidateTrimmedCells = @($candidateCells | ForEach-Object { $_.Trim() })
            $candidateFirstCell = if ($candidateTrimmedCells.Count -gt 0) { $candidateTrimmedCells[0] } else { '' }
            $hasSingleOpeningPipe = $trimmedLine.StartsWith('|') -and -not $trimmedLine.StartsWith('||')
            $hasSingleClosingPipe = $trimmedLine.EndsWith('|') -and -not $trimmedLine.EndsWith('||')
            $looksLikeHeader = @($candidateTrimmedCells | Where-Object { $_ -ieq 'Module' }).Count -gt 0 -and @($candidateTrimmedCells | Where-Object { $_ -ieq 'Status' }).Count -gt 0
            $headerMatches = $hasSingleOpeningPipe -and $hasSingleClosingPipe -and $candidateCells.Count -eq 5 -and $candidateFirstCell -ieq 'Module'
            if ($headerMatches) {
                for ($i = 0; $i -lt $expectedHeader.Count; $i++) {
                    if ($candidateTrimmedCells[$i] -ine $expectedHeader[$i]) { $headerMatches = $false; break }
                }
            }
            if (-not $headerMatches) {
                if ($looksLikeHeader) {
                    $invalidRows.Add([ordered]@{ Module = $null; Line = $lineNumber; Reason = 'malformed-module-status-row' })
                }
                continue
            }
            $tableStarted = $true
            $awaitingSeparator = $true
            continue
        } elseif ($trimmedLine -notmatch '\|') {
            if ($trimmedLine -match '^##(?:#)?\s') { break }
            if ($trimmedLine -match '^<!--\s*/?guide-owned:') { break }
            if ($trimmedLine -match '^<!--') { continue }
            $invalidRows.Add([ordered]@{ Module = $null; Line = $lineNumber; Reason = 'malformed-module-status-row' })
            continue
        }
        $hasOpeningPipe = $trimmedLine.StartsWith('|')
        $hasClosingPipe = $trimmedLine.EndsWith('|')
        $cells = @($trimmedLine.Trim('|') -split '\|')
        $trimmedCells = @($cells | ForEach-Object { $_.Trim() })
        $moduleId = if ($trimmedCells.Count -gt 0) { $trimmedCells[0] } else { '' }
        $hasSingleOpeningPipe = $trimmedLine.StartsWith('|') -and -not $trimmedLine.StartsWith('||')
        $hasSingleClosingPipe = $trimmedLine.EndsWith('|') -and -not $trimmedLine.EndsWith('||')
        if ($awaitingSeparator) {
            $awaitingSeparator = $false
            if (-not $hasSingleOpeningPipe -or -not $hasSingleClosingPipe -or $cells.Count -ne 5 -or
                @($trimmedCells | Where-Object { $_ -notmatch '^:?-{3,}:?$' }).Count -ne 0) {
                $invalidRows.Add([ordered]@{ Module = $null; Line = $lineNumber; Reason = 'malformed-module-status-separator' })
            }
            continue
        }
        if ($moduleId -ieq 'Module' -or @($trimmedCells | Where-Object { $_ -notmatch '^:?-{3,}:?$' }).Count -eq 0) { continue }
        if (-not $hasSingleOpeningPipe -or -not $hasSingleClosingPipe -or $cells.Count -ne 5) {
            $invalidRows.Add([ordered]@{
                Module = $moduleId
                Line = $lineNumber
                Reason = 'malformed-module-status-row'
            })
            continue
        }
        if ($script:CanonicalModuleIds -notcontains $moduleId) {
            $invalidRows.Add([ordered]@{ Module = $moduleId; Line = $lineNumber; Reason = 'invalid-module-status-module' })
            continue
        }
        $status = $trimmedCells[1].ToLowerInvariant()
        if ($validStatuses -notcontains $status) {
            $invalidRows.Add([ordered]@{ Module = $moduleId; Line = $lineNumber; Reason = 'invalid-module-status' })
            continue
        }
        if ($status -eq 'not applicable' -and $trimmedCells[4].Length -eq 0) {
            $invalidRows.Add([ordered]@{ Module = $moduleId; Line = $lineNumber; Reason = 'missing-not-applicable-rationale' })
            continue
        }
        $mentionedModules.Add($moduleId)
        $moduleStatuses[$moduleId] = $status
        $moduleSourceIds[$moduleId] = @($trimmedCells[3] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        if ($status -in @('included', 'awaiting input')) {
            $modules.Add($moduleId)
        }
    }
    if (-not $tableStarted) {
        $invalidRows.Add([ordered]@{ Module = $null; Line = 0; Reason = 'missing-module-status-header' })
    } elseif ($awaitingSeparator) {
        $invalidRows.Add([ordered]@{ Module = $null; Line = $lineNumber; Reason = 'malformed-module-status-separator' })
    }
    $uniqueMentionedModules = @($mentionedModules | Select-Object -Unique)
    $duplicates = @($mentionedModules | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
    $missingModules = @($script:CanonicalModuleIds | Where-Object { $uniqueMentionedModules -notcontains $_ })
    foreach ($missingModule in $missingModules) {
        $invalidRows.Add([ordered]@{ Module = $missingModule; Line = 0; Reason = 'missing-module-status-row' })
    }
    return [ordered]@{
        HasSection = $true
        IsAuthoritative = (
            $invalidRows.Count -eq 0 -and
            $duplicates.Count -eq 0 -and
            $uniqueMentionedModules.Count -eq $script:CanonicalModuleIds.Count -and
            @($script:CanonicalModuleIds | Where-Object { $uniqueMentionedModules -notcontains $_ }).Count -eq 0
        )
        IncludedModules = @($modules | Select-Object -Unique)
        InvalidRows = @($invalidRows)
        DuplicateModules = @($duplicates)
        ModuleSourceIds = $moduleSourceIds
        ModuleStatuses = $moduleStatuses
    }
}

function Get-OwnedRegions {
    <# Parses <!-- guide-owned:ID sources="a,b" revision="sha256:..." --> ... <!-- /guide-owned:ID --> markers. #>
    param([Parameter(Mandatory)][string]$GuideText)
    $regions = [System.Collections.Generic.List[object]]::new()
    $pattern = '(?ms)<!--\s*guide-owned:(?<id>[\w-]+)\s+sources="(?<sources>[^"]*)"\s+revision="(?<rev>[^"]*)"\s*-->(?<body>.*?)<!--\s*/guide-owned:\k<id>\s*-->'
    foreach ($m in [regex]::Matches($GuideText, $pattern)) {
        $regions.Add([ordered]@{
            Id               = $m.Groups['id'].Value
            Sources          = [string[]]@($m.Groups['sources'].Value -split ',' | Where-Object { $_ } | ForEach-Object { $_.Trim() })
            RecordedRevision = $m.Groups['rev'].Value
            Body             = $m.Groups['body'].Value
            HasBody          = $m.Groups['body'].Value.Trim().Length -gt 0
            CurrentBodyDigest = Get-TextDigest -Text $m.Groups['body'].Value
            FullMatch        = $m.Value
            Index            = $m.Index
            Length           = $m.Length
        })
    }
    return $regions
}

function Get-AuthorizedStatusesForApprovalState {
    <#
    .SYNOPSIS
    Maps a guide row's recorded approval state to the set of current
    manifest-source statuses that are authorized to satisfy it. An
    APPROVED-recorded row requires an APPROVED current source; a
    PROPOSED/UNKNOWN current source (direct or equivalent) can never
    satisfy an APPROVED or DERIVED row. Returns $null for 'UNKNOWN' to
    mean "no restriction" (the row already recorded no strong claim).
    #>
    param([string]$ApprovalState)
    switch ($ApprovalState) {
        'APPROVED' { return @('APPROVED') }
        'DERIVED'  { return @('DERIVED', 'APPROVED') }
        'PROPOSED' { return @('PROPOSED', 'DERIVED', 'APPROVED') }
        'TEMPLATE' { return @('TEMPLATE') }
        'UNKNOWN'  { return $null }
        default    { return @($ApprovalState) }
    }
}

function Resolve-RowModuleId {
    param([Parameter(Mandatory)][hashtable]$Row, [Parameter(Mandatory)][hashtable]$ManifestSources)
    if ($script:CanonicalModuleIds -contains $Row.SupportedScope) { return $Row.SupportedScope }
    $candidates = [System.Collections.Generic.List[object]]::new()
    if ($Row.SourceId -and $ManifestSources.ContainsKey($Row.SourceId)) {
        $candidates.Add($ManifestSources[$Row.SourceId])
    }
    if ($Row.SourceId) {
        foreach ($candidate in $ManifestSources.Values) {
            if ($candidate.id -ne $Row.SourceId -and $candidate.equivalentFor -contains $Row.SourceId) {
                $candidates.Add($candidate)
            }
        }
    }
    $scopes = @(
        $candidates |
            Where-Object { $_.rule -eq $Row.SupportedScope } |
            ForEach-Object { $_.scope } |
            Where-Object { $script:CanonicalModuleIds -contains $_ } |
            Select-Object -Unique
    )
    if ($scopes.Count -eq 1) { return $scopes[0] }
    return $null
}

function Resolve-SourceForRow {
    <#
    .SYNOPSIS
    Finds the manifest source that backs a guide row: a direct ID match, or
    an approved equivalent declared via 'equivalentFor' for the same named
    (possibly absent) artifact (spec 14 H16). Verifies scope compatibility
    and that the resolved source's status is authorized for the row's
    recorded approval state -- a PROPOSED/UNKNOWN source, or an unapproved
    equivalent, must never satisfy an APPROVED/DERIVED recorded row.
    #>
    param([Parameter(Mandatory)][hashtable]$Row, [Parameter(Mandatory)][hashtable]$ManifestSources)
    $rowScope = Resolve-RowModuleId -Row $Row -ManifestSources $ManifestSources
    if (-not $Row.SourceId -or -not $rowScope -or
        $script:CanonicalStatuses -notcontains $Row.ApprovalState) {
        return [ordered]@{ Found = $false; Reason = 'invalid-provenance'; Source = $null }
    }
    $candidates = [System.Collections.Generic.List[object]]::new()
    $useEquivalents = $true
    if ($ManifestSources.ContainsKey($Row.SourceId)) {
        $direct = $ManifestSources[$Row.SourceId]
        $candidates.Add($direct)
        $useEquivalents = -not $direct.available
    }
    if ($useEquivalents) {
        foreach ($candidate in $ManifestSources.Values) {
            if ($candidate.id -ne $Row.SourceId -and $candidate.equivalentFor -contains $Row.SourceId) {
                $candidates.Add($candidate)
            }
        }
    }

    if ($candidates.Count -eq 0) { return [ordered]@{ Found = $false; Reason = 'not-found'; Source = $null } }

    $allowed = Get-AuthorizedStatusesForApprovalState -ApprovalState $Row.ApprovalState
    $failures = [System.Collections.Generic.List[object]]::new()
    $eligible = [System.Collections.Generic.List[object]]::new()
    foreach ($candidate in $candidates) {
        $failure = $null
        if (-not $candidate.available) {
            $failure = 'unavailable'
        } elseif ($candidate.scope -ne $rowScope) {
            $failure = 'scope-mismatch'
        } elseif (($script:CanonicalModuleIds -notcontains $Row.SupportedScope) -and $candidate.rule -ne $Row.SupportedScope) {
            $failure = 'rule-mismatch'
        } elseif ($allowed -and $allowed -notcontains $candidate.status) {
            $failure = 'unauthorized'
        }
        if (-not $failure) {
            $eligible.Add($candidate)
            continue
        }
        $failures.Add([ordered]@{ Found = $false; Reason = $failure; Source = $candidate })
    }
    if ($eligible.Count -eq 1) {
        return [ordered]@{ Found = $true; Reason = $null; Source = $eligible[0] }
    }
    if ($eligible.Count -gt 1) {
        $revisionMatches = @($eligible | Where-Object { $_.revision -eq $Row.Revision })
        if ($revisionMatches.Count -eq 1) {
            return [ordered]@{ Found = $true; Reason = $null; Source = $revisionMatches[0] }
        }
        return [ordered]@{ Found = $false; Reason = 'ambiguous-equivalent'; Source = $null }
    }
    $priority = @{ unauthorized = 4; 'rule-mismatch' = 3; 'scope-mismatch' = 2; unavailable = 1 }
    return $failures | Sort-Object { $priority[$_.Reason] } -Descending | Select-Object -First 1
}

function Find-SourceConflicts {
    <# Two APPROVED manifest sources sharing scope+rule with different recorded
       'value' are a conflicting-approved-rule (spec 14 section 3): BLOCKED. #>
    param([Parameter(Mandatory)][hashtable]$ManifestSources)
    $conflicts = [System.Collections.Generic.List[object]]::new()
    $byKey = @{}
    foreach ($src in $ManifestSources.Values) {
        if ($src.status -ne 'APPROVED' -or -not $src.rule -or $null -eq $src.value) { continue }
        $key = "$($src.scope)::$($src.rule)"
        if (-not $byKey.ContainsKey($key)) { $byKey[$key] = [System.Collections.Generic.List[object]]::new() }
        $byKey[$key].Add($src)
    }
    foreach ($key in $byKey.Keys) {
        $group = $byKey[$key]
        $values = @($group | ForEach-Object { $_.value } | Select-Object -Unique)
        if ($values.Count -gt 1) {
            $conflicts.Add([ordered]@{ Scope = $key; Sources = @($group.id); Values = $values })
        }
    }
    return $conflicts
}

function Find-IncompleteConflictEvidenceScopes {
    param([Parameter(Mandatory)][hashtable]$ManifestSources)
    $scopes = [System.Collections.Generic.List[string]]::new()
    $approvedByScope = @{}
    foreach ($src in $ManifestSources.Values) {
        if ($src.status -ne 'APPROVED' -or -not ($script:CanonicalModuleIds -contains $src.scope)) { continue }
        if (-not $approvedByScope.ContainsKey($src.scope)) { $approvedByScope[$src.scope] = [System.Collections.Generic.List[object]]::new() }
        $approvedByScope[$src.scope].Add($src)
    }
    foreach ($scope in $approvedByScope.Keys) {
        $approvedSources = @($approvedByScope[$scope])
        if ($approvedSources.Count -le 1) { continue }
        $incomplete = @($approvedSources | Where-Object { -not $_.rule -or $null -eq $_.value })
        if ($incomplete.Count -gt 0) { $scopes.Add($scope) }
    }
    return @($scopes | Select-Object -Unique)
}

function Test-GuideFreshness {
    <#
    .SYNOPSIS
    Read-only freshness assessment. Never writes the guide, its sources or
    any metadata/timestamp. Returns CURRENT, STALE, UNKNOWN or BLOCKED per
    module plus an overall state using BLOCKED > STALE > UNKNOWN > CURRENT
    precedence. A missing/inaccessible/out-of-root source path degrades
    only the affected module to UNKNOWN; it never aborts the assessment.
    An unauthorized resolved source (e.g. a PROPOSED source backing an
    APPROVED-recorded row) reports STALE, never CURRENT.
    #>
    param(
        [Parameter(Mandatory)][string]$GuidePath,
        [Parameter(Mandatory)][string]$ManifestPath,
        [string]$RepoRoot = (Get-Location).Path
    )
    $guideText = Get-Content -LiteralPath $GuidePath -Raw
    $rows = Get-ApprovedInputRows -GuideText $guideText
    $approvedInputErrors = Get-ApprovedInputTableErrors -GuideText $guideText
    $moduleSelection = Get-IncludedModuleIds -GuideText $guideText
    $includedModules = @($moduleSelection.IncludedModules)
    $includedModuleSet = @{}
    foreach ($moduleId in $includedModules) { $includedModuleSet[$moduleId] = $true }
    $owned = Get-OwnedRegions -GuideText $guideText
    $guideReferencedSourceIds = @(
        @($rows | ForEach-Object { $_.SourceId })
        @($owned | ForEach-Object { $_.Sources })
        @($moduleSelection.ModuleSourceIds.Values | ForEach-Object { $_ })
    ) | Where-Object { $_ } | Select-Object -Unique
    $guideReferencedScopes = @(
        @($rows | ForEach-Object { $_.SupportedScope } | Where-Object { $script:CanonicalModuleIds -contains $_ })
        @($owned | ForEach-Object { $_.Id } | Where-Object { $script:CanonicalModuleIds -contains $_ })
    ) | Select-Object -Unique
    $moduleStates = [ordered]@{}
    $reasons = [System.Collections.Generic.List[string]]::new()
    $precedence = @{ BLOCKED = 3; STALE = 2; UNKNOWN = 1; CURRENT = 0 }
    $conflicts = @()
    $manifestUnavailable = $false

    try {
        $manifestResult = Read-InputsManifestForFreshness -ManifestPath $ManifestPath -RepoRoot $RepoRoot
        $manifestSources = $manifestResult.Sources
        foreach ($recordError in @($manifestResult.Errors)) {
            $recordScope = $recordError['Scope']
            $recordSourceId = $recordError['SourceId']
            $recordState = $recordError['State']
            $recordReason = $recordError['Reason']
            $hasParticipatingScope = $false
            if ($recordScope -and $script:CanonicalModuleIds -contains $recordScope) {
                $hasParticipatingScope = if ($moduleSelection.IsAuthoritative) {
                    $includedModuleSet.ContainsKey($recordScope)
                } else {
                    $guideReferencedScopes -contains $recordScope
                }
            }
            $hasReferencedSource = $guideReferencedSourceIds -contains $recordSourceId
            if ($moduleSelection.IsAuthoritative) {
                if (-not $hasParticipatingScope -and -not $hasReferencedSource) { continue }
            } elseif (-not $hasParticipatingScope -and -not $hasReferencedSource) {
                continue
            }
            $errorId = if ($recordScope -and $script:CanonicalModuleIds -contains $recordScope) { $recordScope } else { $recordSourceId }
            $errorState = if ($recordState) { $recordState } else { 'UNKNOWN' }
            if (-not $moduleStates.Contains($errorId) -or
                $precedence[$errorState] -gt $precedence[$moduleStates[$errorId]]) {
                $moduleStates[$errorId] = $errorState
            }
            $reasons.Add("Manifest source '$recordSourceId' is malformed and cannot be trusted as input evidence: $recordReason")
        }
    } catch {
        $manifestSources = @{}
        $manifestUnavailable = $true
        $affectedModules = if ($moduleSelection.IsAuthoritative) {
            $includedModules
        } else {
            @(
                $rows | ForEach-Object { $_.SupportedScope } | Where-Object { $script:CanonicalModuleIds -contains $_ }
                $owned | ForEach-Object { $_.Id } | Where-Object { $script:CanonicalModuleIds -contains $_ }
                $approvedInputErrors | ForEach-Object { $_.Scope } | Where-Object { $script:CanonicalModuleIds -contains $_ }
            ) | Select-Object -Unique
        }
        if (@($affectedModules).Count -eq 0) { $affectedModules = @('manifest-evidence') }
        foreach ($moduleId in $affectedModules) { $moduleStates[$moduleId] = 'UNKNOWN' }
        $reasons.Add("Current inputs manifest is unavailable or malformed: $($_.Exception.Message)")
    }
    $conflicts = Find-SourceConflicts -ManifestSources $manifestSources
    $conflictedScopes = @($conflicts | ForEach-Object { ($_.Scope -split '::')[0] })
    $incompleteConflictEvidenceScopes = Find-IncompleteConflictEvidenceScopes -ManifestSources $manifestSources
    $provenanceScopes = @($rows | ForEach-Object { Resolve-RowModuleId -Row $_ -ManifestSources $manifestSources } | Where-Object { $script:CanonicalModuleIds -contains $_ } | Select-Object -Unique)
    foreach ($scope in $incompleteConflictEvidenceScopes) {
        if ($moduleSelection.IsAuthoritative -and -not $includedModuleSet.ContainsKey($scope)) { continue }
        if (-not $moduleSelection.IsAuthoritative -and $provenanceScopes -notcontains $scope) { continue }
        if (-not $moduleStates.Contains($scope) -or
            $precedence['UNKNOWN'] -gt $precedence[$moduleStates[$scope]]) {
            $moduleStates[$scope] = 'UNKNOWN'
        }
        $reasons.Add("Module '$scope' has multiple approved sources but incomplete rule/value evidence for conflict comparison.")
    }

    foreach ($errorRow in $approvedInputErrors) {
        $invalidId = if ($script:CanonicalModuleIds -contains $errorRow.Scope) { $errorRow.Scope } else { "approved-input-row-$($errorRow.Line)" }
        if (-not $moduleStates.Contains($invalidId) -or
            $precedence['UNKNOWN'] -gt $precedence[$moduleStates[$invalidId]]) {
            $moduleStates[$invalidId] = 'UNKNOWN'
        }
        $reasons.Add("Approved-input table row $($errorRow.Line) is malformed and cannot be trusted as provenance evidence.")
    }

    foreach ($invalidRow in @($moduleSelection.InvalidRows)) {
        $invalidId = if ($script:CanonicalModuleIds -contains $invalidRow.Module) { $invalidRow.Module } else { "module-status-row-$($invalidRow.Line)" }
        if (-not $moduleStates.Contains($invalidId) -or
            $precedence['UNKNOWN'] -gt $precedence[$moduleStates[$invalidId]]) {
            $moduleStates[$invalidId] = 'UNKNOWN'
        }
        $targetLabel = if ($invalidRow.Module) { "'$($invalidRow.Module)'" } else { 'an unidentified module' }
        $reasons.Add("Module status row $($invalidRow.Line) for $targetLabel is malformed or uses an invalid status.")
    }

    foreach ($duplicateModule in @($moduleSelection.DuplicateModules)) {
        $moduleStates[$duplicateModule] = 'BLOCKED'
        $reasons.Add("Module status table contains duplicate rows for '$duplicateModule'.")
    }

    foreach ($moduleId in @($moduleSelection.ModuleStatuses.Keys)) {
        if ($moduleSelection.ModuleStatuses[$moduleId] -ne 'awaiting input') { continue }
        if (-not $moduleStates.Contains($moduleId)) { $moduleStates[$moduleId] = 'CURRENT' }
        if ($moduleStates[$moduleId] -ne 'BLOCKED' -and
            $precedence['UNKNOWN'] -gt $precedence[$moduleStates[$moduleId]]) {
            $moduleStates[$moduleId] = 'UNKNOWN'
        }
        $reasons.Add("Module '$moduleId' is marked awaiting input in the Module status table.")
    }

    $openingMarkers = @([regex]::Matches($guideText, '<!--\s*guide-owned:(?<id>[\w-]+)\b'))
    $closingMarkers = @([regex]::Matches($guideText, '<!--\s*/guide-owned:(?<id>[\w-]+)\s*-->'))
    $boundaryMarkers = @([regex]::Matches($guideText, '<!--\s*(?<close>/)?guide-owned:(?<id>[\w-]+)\b[^>]*-->'))
    $openingIds = @($openingMarkers | ForEach-Object { $_.Groups['id'].Value })
    $closingIds = @($closingMarkers | ForEach-Object { $_.Groups['id'].Value })
    $duplicateIds = @($openingIds | Group-Object | Where-Object { $_.Count -gt 1 })
    $boundaryInvalid = $false
    $openStack = [System.Collections.Generic.Stack[string]]::new()
    foreach ($marker in $boundaryMarkers) {
        $markerId = $marker.Groups['id'].Value
        if (-not $marker.Groups['close'].Success) {
            $openStack.Push($markerId)
            continue
        }
        if ($openStack.Count -eq 0 -or $openStack.Peek() -ne $markerId) {
            $boundaryInvalid = $true
            break
        }
        [void]$openStack.Pop()
    }
    if ($openStack.Count -gt 0) { $boundaryInvalid = $true }
    if (@($openingIds).Count -ne @($closingIds).Count -or
        @($owned).Count -ne @($openingIds).Count -or
        $boundaryInvalid -or
        (@($openingIds | Where-Object { $closingIds -notcontains $_ }).Count -gt 0) -or
        @($duplicateIds).Count -gt 0) {
        $moduleStates['ownership-boundaries'] = 'BLOCKED'
        $reasons.Add('Guide-owned markers are unbalanced, mismatched, or duplicated; ownership is ambiguous.')
    }

    $rowNumber = 0
    foreach ($row in $rows) {
        $rowNumber++
        $moduleId = Resolve-RowModuleId -Row $row -ManifestSources $manifestSources
        if (-not $row.SourceId -or -not $row.Revision -or -not $moduleId -or
            $script:CanonicalStatuses -notcontains $row.ApprovalState) {
            $invalidId = if ($moduleId -and $script:CanonicalModuleIds -contains $moduleId) { $moduleId } else { "provenance-row-$rowNumber" }
            if (-not $moduleStates.Contains($invalidId) -or
                $precedence['UNKNOWN'] -gt $precedence[$moduleStates[$invalidId]]) {
                $moduleStates[$invalidId] = 'UNKNOWN'
            }
            $reasons.Add("Approved-input row $rowNumber has missing or noncanonical source, scope, or approval-state provenance.")
            continue
        }
        if ($moduleSelection.IsAuthoritative -and -not $includedModuleSet.ContainsKey($moduleId)) {
            if (-not $moduleStates.Contains($moduleId) -or
                $precedence['UNKNOWN'] -gt $precedence[$moduleStates[$moduleId]]) {
                $moduleStates[$moduleId] = 'UNKNOWN'
            }
            $reasons.Add("Approved-input row $rowNumber targets canonical module '$moduleId' excluded by the authoritative Module status selection.")
            continue
        }
        if (-not $moduleStates.Contains($moduleId)) { $moduleStates[$moduleId] = 'CURRENT' }
        if ($conflictedScopes -contains $moduleId) {
            $moduleStates[$moduleId] = 'BLOCKED'
            $reasons.Add("Module '$moduleId' has conflicting approved rules for the same scope.")
            continue
        }
        if ($manifestUnavailable) { continue }
        $match = Resolve-SourceForRow -Row $row -ManifestSources $manifestSources
        if (-not $match.Found) {
            $newState = switch ($match.Reason) {
                'ambiguous-equivalent' { 'BLOCKED' }
                'unauthorized'         { 'STALE' }
                default                { 'UNKNOWN' }
            }
            if ($moduleStates[$moduleId] -ne 'BLOCKED' -and
                $precedence[$newState] -gt $precedence[$moduleStates[$moduleId]]) {
                $moduleStates[$moduleId] = $newState
            }
            $detail = switch ($match.Reason) {
                'ambiguous-equivalent' { "input '$($row.SourceId)' has multiple eligible current sources and no unique recorded-revision match" }
                'not-found'      { "input '$($row.SourceId)' has no current authorized source and no approved equivalent" }
                'unavailable'    { "input '$($row.SourceId)' resolved source is unavailable ($($match.Source.unavailableReason))" }
                'scope-mismatch' { "input '$($row.SourceId)' resolved source scope '$($match.Source.scope)' does not match recorded scope '$moduleId'" }
                'rule-mismatch'  { "input '$($row.SourceId)' resolved source rule '$($match.Source.rule)' does not match recorded rule '$($row.SupportedScope)'" }
                'unauthorized'   { "input '$($row.SourceId)' resolved source status '$($match.Source.status)' is not authorized for a recorded '$($row.ApprovalState)' input" }
                'invalid-provenance' { "input '$($row.SourceId)' has invalid source, scope, or approval-state provenance" }
                default          { "input '$($row.SourceId)' could not be resolved" }
            }
            $reasons.Add("Module '$moduleId' $detail.")
            continue
        }
        if ($match.Source.revision -ne $row.Revision) {
            if ($moduleStates[$moduleId] -notin @('BLOCKED')) { $moduleStates[$moduleId] = 'STALE' }
            $reasons.Add("Module '$moduleId' input '$($row.SourceId)' recorded revision '$($row.Revision)' does not match current '$($match.Source.revision)'.")
        }
        if ($match.Source.status -ne $row.ApprovalState) {
            if ($moduleStates[$moduleId] -notin @('BLOCKED')) { $moduleStates[$moduleId] = 'STALE' }
            $reasons.Add("Module '$moduleId' input '$($row.SourceId)' recorded approval state '$($row.ApprovalState)' does not match current '$($match.Source.status)'.")
        }
    }
    $ownedRegionIds = @($owned | ForEach-Object { $_.Id })
    $ownedRegionIds = @($owned | ForEach-Object { $_.Id })
    $scopesRequiringOwnedEvidence = if ($moduleSelection.IsAuthoritative) {
        $includedModules
    } else {
        $provenanceScopes
    }
    foreach ($scope in $scopesRequiringOwnedEvidence) {
        if ($conflictedScopes -contains $scope) {
            $moduleStates[$scope] = 'BLOCKED'
            $reasons.Add("Module '$scope' has conflicting approved rules for the same scope.")
            continue
        }
        if ($ownedRegionIds -contains $scope) { continue }
        if (-not $moduleStates.Contains($scope)) { $moduleStates[$scope] = 'CURRENT' }
        if ($moduleStates[$scope] -ne 'BLOCKED' -and
            $precedence['UNKNOWN'] -gt $precedence[$moduleStates[$scope]]) {
            $moduleStates[$scope] = 'UNKNOWN'
        }
        if ($provenanceScopes -contains $scope) {
            $reasons.Add("Module '$scope' has approved-input provenance but no guide-owned artifact evidence.")
        } else {
            $reasons.Add("Module '$scope' is included by Module status but has no approved-input provenance or guide-owned artifact evidence.")
        }
    }

    if ($moduleSelection.IsAuthoritative) {
        foreach ($scope in $includedModules) {
            $declaredSourceIds = @($moduleSelection.ModuleSourceIds[$scope])
            $rowSourceIds = @($rows | Where-Object { (Resolve-RowModuleId -Row $_ -ManifestSources $manifestSources) -eq $scope } | ForEach-Object { $_.SourceId } | Select-Object -Unique)
            $regionSourceIds = @($owned | Where-Object { $_.Id -eq $scope } | ForEach-Object { $_.Sources } | Select-Object -Unique)
            $evidenceSourceIds = @($rowSourceIds + $regionSourceIds | Where-Object { $_ } | Select-Object -Unique)
            if (@($declaredSourceIds | Where-Object { $evidenceSourceIds -notcontains $_ }).Count -gt 0 -or
                @($evidenceSourceIds | Where-Object { $declaredSourceIds -notcontains $_ }).Count -gt 0) {
                if (-not $moduleStates.Contains($scope)) { $moduleStates[$scope] = 'CURRENT' }
                if ($moduleStates[$scope] -ne 'BLOCKED' -and
                    $precedence['UNKNOWN'] -gt $precedence[$moduleStates[$scope]]) {
                    $moduleStates[$scope] = 'UNKNOWN'
                }
                $reasons.Add("Module '$scope' Module status approved source IDs do not match approved-input rows and owned-region sources.")
            }
        }
    }

    foreach ($region in $owned) {
        if ($moduleSelection.IsAuthoritative -and
            $script:CanonicalModuleIds -contains $region.Id -and
            -not $includedModuleSet.ContainsKey($region.Id)) {
            continue
        }
        if (-not $moduleStates.Contains($region.Id)) { $moduleStates[$region.Id] = 'CURRENT' }
        if ($conflictedScopes -contains $region.Id) { $moduleStates[$region.Id] = 'BLOCKED'; continue }
        if ($region.Sources.Count -eq 0) {
            if ($moduleStates[$region.Id] -ne 'BLOCKED' -and
                $precedence['UNKNOWN'] -gt $precedence[$moduleStates[$region.Id]]) {
                $moduleStates[$region.Id] = 'UNKNOWN'
            }
            $reasons.Add("Module '$($region.Id)' owned region has no input provenance sources.")
        }
        if ($region.Body.Length -eq 0) {
            if ($moduleStates[$region.Id] -ne 'BLOCKED' -and
                $precedence['UNKNOWN'] -gt $precedence[$moduleStates[$region.Id]]) {
                $moduleStates[$region.Id] = 'UNKNOWN'
            }
            $reasons.Add("Module '$($region.Id)' owned region is empty and has no verifiable generated content.")
        }
        $moduleRowSourceIds = @($rows | Where-Object { (Resolve-RowModuleId -Row $_ -ManifestSources $manifestSources) -eq $region.Id } | ForEach-Object { $_.SourceId } | Select-Object -Unique)
        foreach ($rowSourceId in $moduleRowSourceIds) {
            if ($region.Sources -notcontains $rowSourceId) {
                if ($moduleStates[$region.Id] -ne 'BLOCKED' -and
                    $precedence['UNKNOWN'] -gt $precedence[$moduleStates[$region.Id]]) {
                    $moduleStates[$region.Id] = 'UNKNOWN'
                }
                $reasons.Add("Module '$($region.Id)' approved-input source '$rowSourceId' is not mapped by its owned region.")
            }
        }
        foreach ($sourceId in $region.Sources) {
            $row = $rows | Where-Object { $_.SourceId -eq $sourceId -and (Resolve-RowModuleId -Row $_ -ManifestSources $manifestSources) -eq $region.Id } | Select-Object -First 1
            if (-not $row) {
                if ($moduleStates[$region.Id] -ne 'BLOCKED' -and
                    $precedence['UNKNOWN'] -gt $precedence[$moduleStates[$region.Id]]) {
                    $moduleStates[$region.Id] = 'UNKNOWN'
                }
                $reasons.Add("Module '$($region.Id)' owned region source '$sourceId' has no matching approved-input provenance row.")
                continue
            }
            if ($manifestUnavailable) { continue }
            $match = Resolve-SourceForRow -Row $row -ManifestSources $manifestSources
            if (-not $match.Found) {
                $newState = switch ($match.Reason) {
                    'ambiguous-equivalent' { 'BLOCKED' }
                    'unauthorized'         { 'STALE' }
                    default                { 'UNKNOWN' }
                }
                if ($moduleStates[$region.Id] -ne 'BLOCKED' -and
                    $precedence[$newState] -gt $precedence[$moduleStates[$region.Id]]) {
                    $moduleStates[$region.Id] = $newState
                }
                $reasons.Add("Module '$($region.Id)' owned region source '$sourceId' lacks current authorized input evidence.")
            }
        }
        if (-not $region.HasBody) {
            if ($moduleStates[$region.Id] -ne 'BLOCKED' -and
                $precedence['UNKNOWN'] -gt $precedence[$moduleStates[$region.Id]]) {
                $moduleStates[$region.Id] = 'UNKNOWN'
            }
            $reasons.Add("Module '$($region.Id)' owned region has empty guide-owned artifact evidence.")
            continue
        }
        if (-not $region.RecordedRevision -or $region.RecordedRevision -notmatch '^sha256:[a-f0-9]{64}$') {
            if ($moduleStates[$region.Id] -ne 'BLOCKED' -and
                $precedence['UNKNOWN'] -gt $precedence[$moduleStates[$region.Id]]) {
                $moduleStates[$region.Id] = 'UNKNOWN'
            }
            $reasons.Add("Module '$($region.Id)' owned region has missing or malformed recorded digest evidence.")
            continue
        }
        if ($region.CurrentBodyDigest -ne $region.RecordedRevision) {
            if ($moduleStates[$region.Id] -notin @('BLOCKED')) { $moduleStates[$region.Id] = 'STALE' }
            $reasons.Add("Module '$($region.Id)' owned-artifact evidence changed unexpectedly (recorded '$($region.RecordedRevision)', current '$($region.CurrentBodyDigest)').")
        }
    }

    $overall = 'CURRENT'
    foreach ($state in $moduleStates.Values) {
        if ($precedence[$state] -gt $precedence[$overall]) { $overall = $state }
    }
    if ($moduleStates.Count -eq 0) { $overall = 'UNKNOWN'; $reasons.Add('No approved-input rows or owned regions found; nothing to assess.') }

    $actions = [ordered]@{}
    foreach ($moduleId in $moduleStates.Keys) {
        $actions[$moduleId] = switch ($moduleStates[$moduleId]) {
            'BLOCKED' { 'Resolve conflicting or ambiguous ownership/approval evidence before refresh.' }
            'STALE'   { 'Regenerate the owned module with separately authorized tooling, then reassess.' }
            'UNKNOWN' { 'Supply current authorized input and owned-artifact evidence.' }
            default   { 'No remediation required.' }
        }
    }

    return [ordered]@{
        Overall   = $overall
        Modules   = $moduleStates
        Reasons   = @($reasons)
        Conflicts = @($conflicts)
        Actions   = $actions
    }
}

function Invoke-GuideRefresh {
    <#
    .SYNOPSIS
    Fail-closed refresh wrapper for spec 14 section 5.3. CURRENT guides are a
    no-op; STALE/UNKNOWN guides remain report-only PARTIAL results until a
    separately authorized regeneration capability updates content and evidence.
    #>
    param(
        [Parameter(Mandatory)][string]$GuidePath,
        [Parameter(Mandatory)][string]$ManifestPath,
        [string]$RepoRoot = (Get-Location).Path,
        [switch]$Apply,
        [switch]$Force
    )
    $assessment = Test-GuideFreshness -GuidePath $GuidePath -ManifestPath $ManifestPath -RepoRoot $RepoRoot
    if ($assessment.Overall -eq 'BLOCKED') {
        return [ordered]@{
            Result = 'BLOCKED'; Wrote = $false
            UpdatedModules = @(); SkippedModules = @(); UnresolvedModules = @()
            Reasons = $assessment.Reasons; PostAssessment = $assessment
        }
    }

    if ($assessment.Overall -eq 'CURRENT') {
        return [ordered]@{
            Result = 'NO_OP'; Wrote = $false
            UpdatedModules = @(); SkippedModules = @(); UnresolvedModules = @()
            Reasons = @('All guide-owned modules and approved inputs are already current; refresh is a no-op.')
            PostAssessment = $assessment
        }
    }

    $unresolvedModules = @($assessment.Modules.Keys | Where-Object { $assessment.Modules[$_] -in @('STALE', 'UNKNOWN') })
    $reasons = @("Refresh is fail-closed for $($assessment.Overall) guides; no guide content, provenance, or metadata was rewritten.")
    return [ordered]@{
        Result = 'PARTIAL'; Wrote = $false; UpdatedModules = @()
        SkippedModules = @($unresolvedModules); UnresolvedModules = @($unresolvedModules)
        Reasons = @($assessment.Reasons + $reasons); PostAssessment = $assessment
    }
}

Export-ModuleMember -Function `
    Get-CanonicalSourceKinds, Get-CanonicalModuleIds, Get-FileDigest, Get-TextDigest, `
    Resolve-ManifestSourcePath, Read-InputsManifest, Get-ApprovedInputRows, Get-OwnedRegions, `
    Get-AuthorizedStatusesForApprovalState, Resolve-SourceForRow, Find-SourceConflicts, `
    Test-GuideFreshness, Invoke-GuideRefresh
# Source-only delegate resolution. Never inventories installed dependencies.
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'eval-routing-lib.ps1')

function Assert-UniqueJsonKeys {
    param([System.Text.Json.JsonElement]$Element)
    if ($Element.ValueKind -eq 'Object') {
        $keys = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($property in $Element.EnumerateObject()) {
            if (-not $keys.Add($property.Name)) { throw [IO.InvalidDataException]::new('duplicate JSON property') }
            Assert-UniqueJsonKeys $property.Value
        }
    } elseif ($Element.ValueKind -eq 'Array') {
        foreach ($item in $Element.EnumerateArray()) { Assert-UniqueJsonKeys $item }
    }
}

function Get-ExternalDelegateRegistry {
    param([Parameter(Mandatory)][string]$RepoRoot)
    $diagnostics = [System.Collections.Generic.List[object]]::new()
    $verified = [System.Collections.Generic.List[object]]::new()
    $registryPath = 'scripts/external-delegates.json'
    try {
        foreach ($path in @($RepoRoot, (Join-Path $RepoRoot 'scripts'), (Join-Path $RepoRoot $registryPath))) {
            if ((Get-Item -LiteralPath $path -Force -ErrorAction Stop).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw [IO.InvalidDataException]::new('registry link boundary') }
        }
        $raw = Get-Content -LiteralPath (Join-Path $RepoRoot $registryPath) -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) { throw [IO.InvalidDataException]::new('empty registry') }
        $json = [System.Text.Json.JsonDocument]::Parse($raw)
        try { Assert-UniqueJsonKeys $json.RootElement } finally { $json.Dispose() }
        $config = ConvertFrom-Json -InputObject $raw -AsHashtable
        if ($config -isnot [System.Collections.IDictionary] -or
            ($config.Keys | Sort-Object) -join ',' -cne 'dependencies,schema_version' -or
            $config.schema_version -isnot [long] -or $config.schema_version -ne 1 -or
            $config.dependencies -isnot [array]) { throw [IO.InvalidDataException]::new('invalid registry schema') }
        $names = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($entry in $config.dependencies) {
            if ($entry -isnot [System.Collections.IDictionary] -or
                ($entry.Keys | Sort-Object) -join ',' -cne 'kind,name,path,provider') { throw [IO.InvalidDataException]::new('invalid dependency fields') }
            foreach ($key in @('provider', 'kind', 'name', 'path')) {
                if ($entry[$key] -isnot [string]) { throw [IO.InvalidDataException]::new('dependency fields must be strings') }
            }
            if ($entry.provider -cnotmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$' -or
                $entry.name -cnotmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$' -or
                $entry.kind -cnotin @('skill', 'agent')) { throw [IO.InvalidDataException]::new('invalid provider, kind or name') }
            $expected = if ($entry.kind -eq 'skill') { ".github/skills/$($entry.name)/SKILL.md" } else { ".github/agents/$($entry.name).agent.md" }
            if ($entry.path -cne $expected) { throw [IO.InvalidDataException]::new('path must match the declared installed kind/name boundary') }
            if (-not $names.Add($entry.name)) { throw [IO.InvalidDataException]::new('duplicate or ambiguous dependency name') }
        }
    } catch [IO.InvalidDataException], [Text.Json.JsonException], [IO.IOException], [UnauthorizedAccessException], [System.Management.Automation.ItemNotFoundException] {
        # Do not include parser exceptions: they may echo file contents.
        $diagnostics.Add([pscustomobject]@{ severity = 'error'; category = 'external-registry'; target = $registryPath; message = 'Missing or invalid external registry (schema, duplicate, or path boundary); no external declarations accepted.' })
        return [pscustomobject]@{ diagnostics = @($diagnostics); verified = @() }
    }
    foreach ($entry in @($config.dependencies | Sort-Object name)) {
        $status = 'unavailable'
        $reader = $null
        try {
            $current = [IO.Path]::GetFullPath($RepoRoot)
            # Reject all link/reparse components, including the supplied root.
            foreach ($part in @('') + @($entry.path -split '/')) {
                if ($part) { $current = Join-Path $current $part }
                $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
                if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { $status = 'unsafe-link'; throw [IO.InvalidDataException]::new('link boundary') }
            }
            if ($item.PSIsContainer) { throw [IO.InvalidDataException]::new('not a file') }
            $reader = [IO.File]::OpenText($current)
            $header = [System.Collections.Generic.List[string]]::new()
            $lineBuffer = [Text.StringBuilder]::new()
            $closed = $false
            # Bound reads even when a malformed first line has no newline.
            for ($i = 0; $i -lt 32768 -and $header.Count -lt 128; $i++) {
                $value = $reader.Read()
                if ($value -lt 0 -and $lineBuffer.Length -eq 0) { break }
                if ($value -ge 0 -and $value -ne 10) {
                    [void]$lineBuffer.Append([char]$value)
                    continue
                }
                $line = $lineBuffer.ToString().TrimEnd("`r")
                [void]$lineBuffer.Clear()
                $header.Add($line)
                if ($header.Count -eq 1 -and $line -cne '---') { break }
                if ($header.Count -gt 1 -and $line -ceq '---') { $closed = $true; break }
                if ($value -lt 0) { break }
            }
            $status = 'identity-mismatch'
            $fm = Get-AssetFrontmatter ($header -join "`n")
            $matches = [regex]::Matches($fm, '(?m)^name:[ \t]*(.*)\r?$')
            if (-not $closed -or $matches.Count -ne 1 -or
                (ConvertTo-PlainYamlValue $matches[0].Groups[1].Value) -cne $entry.name) { throw [IO.InvalidDataException]::new('identity mismatch') }
            $verified.Add([pscustomobject]@{ provider = $entry.provider; kind = $entry.kind; name = $entry.name; path = $entry.path })
            continue
        } catch [IO.InvalidDataException], [IO.IOException], [UnauthorizedAccessException], [System.Management.Automation.ItemNotFoundException] {
            $diagnostics.Add([pscustomobject]@{ severity = 'warning'; category = 'external-target'; target = $entry.path; message = "External $($entry.kind) '$($entry.name)' is $status; not verified." })
        } finally {
            if ($reader) { $reader.Dispose() }
        }
    }
    return [pscustomobject]@{ diagnostics = @($diagnostics); verified = @($verified) }
}

function Invoke-SourceDelegateAudit {
    param([object[]]$Assets, [string[]]$SkillNames, [string[]]$AgentNames, [object]$Registry)
    $findings = [System.Collections.Generic.List[object]]::new()
    $resolutions = [System.Collections.Generic.List[object]]::new()
    foreach ($asset in @($Assets | Sort-Object path)) {
        foreach ($ref in @(Get-AssetDelegates $asset.content | Sort-Object -Unique)) {
            if ($SkillNames -contains $ref -or $AgentNames -contains $ref) { continue }
            $external = @($Registry.verified | Where-Object name -CEQ $ref)
            if ($external.Count -eq 1) {
                $resolutions.Add([pscustomobject]@{ source = $asset.path; provider = $external[0].provider; kind = $external[0].kind; name = $ref; path = $external[0].path })
            } else {
                $findings.Add([pscustomobject]@{ severity = 'warning'; category = 'skill-delegates'; target = $asset.path; message = "'Delegates / pairs with' references unknown or unverified skill/agent '$ref'" })
            }
        }
    }
    return [pscustomobject]@{ findings = @($findings); external_resolutions = @($resolutions) }
}

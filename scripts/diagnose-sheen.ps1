#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3
$IsVerbose = $PSBoundParameters.ContainsKey('Verbose')

function New-Section {
    param([string]$Name)
    [pscustomobject][ordered]@{
        name     = $Name
        status   = 'pass'
        valid    = $true
        messages = New-Object System.Collections.Generic.List[object]
    }
}

function Add-Message {
    param(
        [Parameter(Mandatory)]$Section,
        [Parameter(Mandatory)][ValidateSet('pass','warn','error')][string]$Level,
        [Parameter(Mandatory)][string]$Message,
        [string]$Path = $null
    )
    $Section.messages.Add([ordered]@{
        level   = $Level
        path    = $Path
        message = $Message
    }) | Out-Null
    if ($Level -eq 'error') {
        $Section.valid = $false
        $Section.status = 'error'
    } elseif ($Level -eq 'warn' -and $Section.status -eq 'pass') {
        $Section.status = 'warn'
    }
}

function Get-RepoRoot {
    $root = git rev-parse --show-toplevel 2>$null
    if (-not $root) { throw 'Run this inside a git repository' }
    return $root.Trim()
}

function Get-RelativePath {
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Path)
    return [System.IO.Path]::GetRelativePath($Root, $Path).Replace('\','/')
}

function Get-FrontMatterLines {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $lines = Get-Content -LiteralPath $Path
    if ($lines.Count -lt 3 -or $lines[0].Trim() -ne '---') { return $null }
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') {
            return $lines[1..($i - 1)]
        }
    }
    return $null
}

function Get-FMScalar {
    param([string[]]$Lines, [string]$Key)
    foreach ($line in $Lines) {
        if ($line -match "^\s*$([regex]::Escape($Key)):\s*(.*?)\s*(?:#.*)?$") {
            $value = $Matches[1].Trim()
            if ($value -match '^\[(.*)\]$') { return $null }
            if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") { return $Matches[1] }
            return $value
        }
    }
    return $null
}

function Get-FMList {
    param([string[]]$Lines, [string]$Key)
    $capturing = $false
    $baseIndent = 0
    $items = New-Object System.Collections.Generic.List[string]
    foreach ($line in $Lines) {
        if (-not $capturing) {
            if ($line -match "^(?<indent>\s*)$([regex]::Escape($Key)):\s*(?<rest>.*)$") {
                $capturing = $true
                $baseIndent = $Matches.indent.Length
                $rest = $Matches.rest.Trim()
                if ($rest -match '^\[(.*)\]$') {
                    foreach ($item in $Matches[1].Split(',')) {
                        $clean = $item.Trim().Trim("'`"")
                        if ($clean) { $items.Add($clean) | Out-Null }
                    }
                    return @($items)
                }
            }
            continue
        }

        if ($line.Trim() -eq '') { continue }
        if ($line -match '^\s*#') { continue }
        if ($line -match "^(?<indent>\s*)-\s*(?<value>.*?)\s*(?:#.*)?$" -and $Matches.indent.Length -gt $baseIndent) {
            $value = $Matches.value.Trim().Trim("'`"")
            if ($value) { $items.Add($value) | Out-Null }
            continue
        }
        if ($line -match "^\s{$($baseIndent + 1),}\S") { continue }
        break
    }
    return @($items)
}

function Get-TokenFlatMap {
    param([Parameter(Mandatory)]$Node, [string]$Prefix = '')
    $map = [ordered]@{}
    foreach ($prop in $Node.PSObject.Properties) {
        if ($prop.Name.StartsWith('$')) { continue }
        $path = if ($Prefix) { "$Prefix.$($prop.Name)" } else { $prop.Name }
        $value = $prop.Value
        if ($null -ne $value -and $value.PSObject.Properties.Name -contains '$type') {
            $map[$path] = $value
        }
        elseif ($value -is [pscustomobject]) {
            $child = Get-TokenFlatMap -Node $value -Prefix $path
            foreach ($k in $child.Keys) { $map[$k] = $child[$k] }
        }
    }
    return $map
}

function Get-TokenRefs {
    param([Parameter(Mandatory)]$Node)
    $refs = New-Object System.Collections.Generic.List[string]
    if ($null -eq $Node) { return @() }
    if ($Node -is [string]) {
        if ($Node -match '^\{(.+)\}$') { $refs.Add($Matches[1]) | Out-Null }
        return @($refs)
    }
    if ($Node -is [System.Collections.IEnumerable] -and $Node -isnot [string]) {
        foreach ($item in $Node) {
            foreach ($ref in @(Get-TokenRefs -Node $item)) { $refs.Add($ref) | Out-Null }
        }
        return @($refs | Select-Object -Unique)
    }
    if ($Node.PSObject -ne $null) {
        foreach ($prop in $Node.PSObject.Properties) {
            if ($prop.Name.StartsWith('$')) { continue }
            foreach ($ref in @(Get-TokenRefs -Node $prop.Value)) { $refs.Add($ref) | Out-Null }
        }
    }
    return @($refs | Select-Object -Unique)
}

function Resolve-TokenRef {
    param(
        [Parameter(Mandatory)][string]$Ref,
        [Parameter(Mandatory)][hashtable]$Maps,
        [Parameter(Mandatory)][string[]]$Order,
        [Parameter(Mandatory)][hashtable]$Seen,
        [string]$CurrentScope = $null,
        [string]$CurrentKey = $null
    )
    foreach ($scope in $Order) {
        $map = $Maps[$scope]
        if ($map.Contains($Ref)) {
            # A role may intentionally alias to a lower-level token with the
            # same name. Skip only a direct self-alias; other cycles remain
            # errors.
            $candidateRefs = @(Get-TokenRefs -Node $map[$Ref].'$value')
            if ($Ref -eq $CurrentKey -and $candidateRefs -contains $Ref) { continue }
            $seenKey = "$scope`:$Ref"
            if ($Seen.Contains($seenKey)) { return $null }
            $nextSeen = @{}
            foreach ($key in $Seen.Keys) { $nextSeen[$key] = $true }
            $nextSeen[$seenKey] = $true
            foreach ($nested in @(Get-TokenRefs -Node $map[$Ref].'$value')) {
                if (-not (Resolve-TokenRef -Ref $nested -Maps $Maps -Order $Order -Seen $nextSeen -CurrentScope $scope -CurrentKey $Ref)) { return $null }
            }
            return $map[$Ref].'$value'
        }
    }
    return '__MISSING__'
}

function Get-CoreAssets {
    param([Parameter(Mandatory)][string]$Root)
    $skills = @()
    $agents = @()
    $instructions = @()
    $themes = @()
    $sourceLayout = (Test-Path -LiteralPath (Join-Path $Root 'skills')) -or
        (Test-Path -LiteralPath (Join-Path $Root 'agents')) -or
        (Test-Path -LiteralPath (Join-Path $Root 'tokens'))
    $skillRoot = Join-Path $Root '.github\skills'
    if ($sourceLayout -and (Test-Path -LiteralPath (Join-Path $Root 'skills'))) {
        $skillRoot = Join-Path $Root 'skills'
    }
    if (Test-Path -LiteralPath $skillRoot) {
        $skills = @(Get-ChildItem -LiteralPath $skillRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
    }
    $agentRoot = Join-Path $Root '.github\agents'
    if ($sourceLayout -and (Test-Path -LiteralPath (Join-Path $Root 'agents'))) {
        $agentRoot = Join-Path $Root 'agents'
    }
    if (Test-Path -LiteralPath $agentRoot) {
        $agents = @(Get-ChildItem -LiteralPath $agentRoot -Filter '*.agent.md' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.BaseName -replace '\.agent$','' })
    }
    $instructionRoot = Join-Path $Root '.github\instructions'
    if ($sourceLayout -and (Test-Path -LiteralPath (Join-Path $Root 'instructions'))) {
        $instructionRoot = Join-Path $Root 'instructions'
    }
    if (Test-Path -LiteralPath $instructionRoot) {
        $instructions = @(Get-ChildItem -LiteralPath $instructionRoot -Filter '*.instructions.md' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.BaseName -replace '\.instructions$','' })
    }
    $themeRoot = Join-Path $Root 'sheen\tokens\themes'
    if ($sourceLayout -and (Test-Path -LiteralPath (Join-Path $Root 'tokens\themes'))) {
        $themeRoot = Join-Path $Root 'tokens\themes'
    }
    if (Test-Path -LiteralPath $themeRoot) {
        $themes = @(Get-ChildItem -LiteralPath $themeRoot -Filter '*.tokens.json' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.BaseName -replace '\.tokens$','' })
    }
    return [ordered]@{
        skills       = $skills
        agents       = $agents
        instructions = $instructions
        themes       = $themes
    }
}

function Get-ManagedAssetScope {
    <#
      Consumer structure checks must only cover Sheen-managed assets (#93).
      Priority:
        1. Source layout (upstream sheen repo) → validate everything on disk
        2. .sheen/manifest.json → only paths recorded by sync
        3. .sheen.yml allow-lists → only listed skills/agents/instructions
        4. Otherwise → no structure scope (validate everything; fixtures / bare trees)
    #>
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][bool]$SourceLayout,
        $ConfigData
    )

    $scope = [ordered]@{
        scoped       = $false
        skills       = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        agents       = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        instructions = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        source       = 'all'
    }

    if ($SourceLayout) {
        return $scope
    }

    $manifestPath = Join-Path $Root '.sheen' 'manifest.json'
    if (Test-Path -LiteralPath $manifestPath) {
        try {
            $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
            foreach ($item in @($manifest.files)) {
                $rel = [string]$item
                if ($rel -match '(?:^|/)\.github/skills/([^/]+)/') {
                    [void]$scope.skills.Add($Matches[1])
                }
                elseif ($rel -match '(?:^|/)skills/([^/]+)/') {
                    [void]$scope.skills.Add($Matches[1])
                }
                if ($rel -match '(?:^|/)\.github/agents/([^/]+)\.agent\.md$') {
                    [void]$scope.agents.Add($Matches[1])
                }
                elseif ($rel -match '(?:^|/)agents/([^/]+)\.agent\.md$') {
                    [void]$scope.agents.Add($Matches[1])
                }
                if ($rel -match '(?:^|/)\.github/instructions/([^/]+)\.instructions\.md$') {
                    [void]$scope.instructions.Add($Matches[1])
                }
                elseif ($rel -match '(?:^|/)instructions/([^/]+)\.instructions\.md$') {
                    [void]$scope.instructions.Add($Matches[1])
                }
            }
            $scope.scoped = $true
            $scope.source = 'manifest'
            return $scope
        } catch {
            # Fall through to allow-list scoping if the manifest is unreadable.
        }
    }

    $hasAllowList = $false
    foreach ($key in @('skills', 'agents', 'instructions')) {
        if ($ConfigData -is [System.Collections.IDictionary] -and $ConfigData.Contains($key)) {
            $hasAllowList = $true
            foreach ($item in @($ConfigData[$key])) {
                if (-not $item) { continue }
                switch ($key) {
                    'skills'       { [void]$scope.skills.Add([string]$item) }
                    'agents'       { [void]$scope.agents.Add([string]$item) }
                    'instructions' { [void]$scope.instructions.Add([string]$item) }
                }
            }
        }
    }
    if ($hasAllowList) {
        $scope.scoped = $true
        $scope.source = 'allow-list'
    }
    return $scope
}

function Test-InManagedScope {
    param(
        $Scope,
        [Parameter(Mandatory)][ValidateSet('skills','agents','instructions')][string]$Kind,
        [Parameter(Mandatory)][string]$Name
    )
    if (-not $Scope.scoped) { return $true }
    switch ($Kind) {
        'skills'       { return $Scope.skills.Contains($Name) }
        'agents'       { return $Scope.agents.Contains($Name) }
        'instructions' { return $Scope.instructions.Contains($Name) }
    }
    return $true
}

function Parse-SheenConfig {
    param([Parameter(Mandatory)][string]$Path)
    $result = [ordered]@{
        valid  = $true
        errors = New-Object System.Collections.Generic.List[string]
        data   = [ordered]@{}
        raw    = @()
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        $result.valid = $false
        $result.errors.Add('.sheen.yml not found') | Out-Null
        return $result
    }
    $lines = Get-Content -LiteralPath $Path
    $currentKey = $null
    $currentIndent = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $trim = $line.Trim()
        if ($trim -eq '' -or $trim.StartsWith('#')) { continue }
        if ($line -match '^\t') {
            $result.valid = $false
            $result.errors.Add("Line $($i + 1): tabs are not valid YAML indentation") | Out-Null
            continue
        }
        if ($currentKey -eq 'sync') {
            if ($line -match '^(?<indent>\s+)\S' -and $Matches.indent.Length -gt $currentIndent) { continue }
            $currentKey = $null
            $i--
            continue
        }
        if ($line -match '^(?<indent>\s*)(?<key>[A-Za-z][A-Za-z0-9_-]*):\s*(?<rest>.*)$') {
            $indent = $Matches.indent.Length
            $key = $Matches.key
            $rest = $Matches.rest.Trim()
            if ($indent -ne 0 -and $currentKey -ne 'sync') {
                $result.valid = $false
                $result.errors.Add("Line $($i + 1): unexpected indentation for top-level key '$key'") | Out-Null
                continue
            }
            if ($rest -eq '') {
                $currentKey = $key
                $currentIndent = $indent
                if (-not $result.data.Contains($key)) {
                    $result.data[$key] = if ($key -eq 'sync') { [ordered]@{} } else { @() }
                }
                continue
            }
            if ($rest -match '^\[(.*)\]$') {
                $items = @()
                foreach ($item in $Matches[1].Split(',')) {
                    $clean = $item.Trim().Trim("'`"")
                    if ($clean) { $items += $clean }
                }
                $result.data[$key] = $items
                $currentKey = $null
                continue
            }
            $scalar = $rest -replace '\s+#.*$', ''
            if ($scalar -match '^"(.*)"$' -or $scalar -match "^'(.*)'$") { $scalar = $Matches[1] }
            $result.data[$key] = $scalar.Trim()
            $currentKey = $null
            continue
        }

        if ($currentKey -in @('skills','agents','instructions','themes')) {
            if ($line -match '^(?<indent>\s*)-\s*(?<value>.*?)\s*(?:#.*)?$' -and $Matches.indent.Length -gt $currentIndent) {
                $value = $Matches.value.Trim().Trim("'`"")
                if (-not $result.data.Contains($currentKey)) { $result.data[$currentKey] = @() }
                if ($value) { $result.data[$currentKey] = @(@($result.data[$currentKey]) + $value) }
                continue
            }
            if ($trim -eq '' -or $trim.StartsWith('#')) { continue }
            $currentKey = $null
            $i--
            continue
        }

        $result.valid = $false
        $result.errors.Add("Line $($i + 1): unable to parse YAML line '$trim'") | Out-Null
    }
    return $result
}

function Format-StatusLine {
    param([string]$Level, [string]$Message, [string]$Path = $null)
    $prefix = switch ($Level) {
        'pass'  { '[PASS]' }
        'warn'  { '[WARN]' }
        'error' { '[ERROR]' }
    }
    if ($Path) { return "$prefix $Path - $Message" }
    return "$prefix $Message"
}

$repoRoot = $null
$fatalError = $null
try {
    $repoRoot = Get-RepoRoot
    Set-Location $repoRoot

    $configPath = Join-Path $repoRoot '.sheen.yml'
    $configDisplayPath = '.sheen.yml'
    if (-not (Test-Path -LiteralPath $configPath) -and (Test-Path -LiteralPath (Join-Path $repoRoot '.sheen.yml.example'))) {
        $configPath = Join-Path $repoRoot '.sheen.yml.example'
        $configDisplayPath = '.sheen.yml.example'
    }
    $configSection = New-Section 'config'
    $structureSection = New-Section 'structure'
    $tokensSection = New-Section 'tokens'
    $collisionsSection = New-Section 'collisions'

    $config = Parse-SheenConfig -Path $configPath
    if (-not $config.valid) {
        foreach ($err in $config.errors) {
            Add-Message -Section $configSection -Level 'error' -Message $err -Path $configDisplayPath
        }
    }

    $configData = $config.data
    $source = if ($configData.Contains('source')) { $configData['source'] } else { $null }
    $ref = if ($configData.Contains('ref')) { $configData['ref'] } else { $null }
    if (-not $source) { Add-Message -Section $configSection -Level 'error' -Message 'Missing required key source' -Path $configDisplayPath }
    if (-not $ref) { Add-Message -Section $configSection -Level 'error' -Message 'Missing required key ref' -Path $configDisplayPath }

    $assetSets = Get-CoreAssets -Root $repoRoot
    $sourceLayout = (Test-Path -LiteralPath (Join-Path $repoRoot 'skills')) -or
        (Test-Path -LiteralPath (Join-Path $repoRoot 'agents')) -or
        (Test-Path -LiteralPath (Join-Path $repoRoot 'tokens'))
    $managedScope = Get-ManagedAssetScope -Root $repoRoot -SourceLayout:$sourceLayout -ConfigData $configData

    # Disk presence is still used for allow-list membership (entry must exist).
    # Structure/collision checks below are filtered through $managedScope (#93).
    $selectable = @{
        skills       = $assetSets.skills
        agents       = $assetSets.agents
        instructions = $assetSets.instructions
        themes       = $assetSets.themes
    }

    foreach ($key in 'skills','agents','instructions','themes') {
        if ($configData.Contains($key)) {
            $selected = @($configData[$key])
            foreach ($item in $selected) {
                if ($item -and ($selectable[$key] -notcontains $item)) {
                    Add-Message -Section $configSection -Level 'error' -Message "Allow-list entry '$item' for $key does not match any synced asset" -Path $configDisplayPath
                }
            }
        }
    }

    $skillPath = if ($sourceLayout) { 'skills' } else { '.github/skills' }
    $agentPath = if ($sourceLayout) { 'agents' } else { '.github/agents' }
    $instructionPath = if ($sourceLayout) { 'instructions' } else { '.github/instructions' }
    $promptPath = if ($sourceLayout) { 'prompts' } else { '.github/prompts' }
    $templatePath = if ($sourceLayout) { 'templates' } else { 'sheen/templates' }
    $tokenPath = if ($sourceLayout) { 'tokens' } else { 'sheen/tokens' }

    if ($managedScope.scoped -and $IsVerbose) {
        Add-Message -Section $structureSection -Level 'pass' -Message ("Structure scope source=$($managedScope.source); skills=$($managedScope.skills.Count) agents=$($managedScope.agents.Count) instructions=$($managedScope.instructions.Count)")
    }

    $expectedDirs = New-Object System.Collections.Generic.List[object]
    $expectedDirs.Add(@{ path = $skillPath; required = (-not $configData.Contains('skills') -or (@($configData['skills']).Count -gt 0)) }) | Out-Null
    $expectedDirs.Add(@{ path = $agentPath; required = (-not $configData.Contains('agents') -or (@($configData['agents']).Count -gt 0)) }) | Out-Null
    $expectedDirs.Add(@{ path = $instructionPath; required = (-not $configData.Contains('instructions') -or (@($configData['instructions']).Count -gt 0)) }) | Out-Null
    $expectedDirs.Add(@{ path = $promptPath; required = $true }) | Out-Null
    $expectedDirs.Add(@{ path = $templatePath; required = $true }) | Out-Null
    $expectedDirs.Add(@{ path = $tokenPath; required = $true }) | Out-Null
    $expectedDirs.Add(@{ path = "$tokenPath/core"; required = $true }) | Out-Null
    $expectedDirs.Add(@{ path = "$tokenPath/semantic"; required = $true }) | Out-Null
    $expectedDirs.Add(@{ path = "$tokenPath/themes"; required = (-not $configData.Contains('themes') -or (@($configData['themes']).Count -gt 0)) }) | Out-Null

    foreach ($entry in $expectedDirs) {
        $dir = Join-Path $repoRoot $entry.path.Replace('/','\')
        if ($entry.required -and -not (Test-Path -LiteralPath $dir)) {
            Add-Message -Section $structureSection -Level 'error' -Message "Expected directory missing after sync" -Path $entry.path
        }
        elseif (-not $entry.required -and (Test-Path -LiteralPath $dir) -and $IsVerbose) {
            Add-Message -Section $structureSection -Level 'warn' -Message "Optional directory present" -Path $entry.path
        }
    }

    # Skill validation (Sheen-managed assets only in consumers — #93).
    $skillRoot = Join-Path $repoRoot $skillPath.Replace('/','\')
    if (Test-Path -LiteralPath $skillRoot) {
        foreach ($skillDir in Get-ChildItem -LiteralPath $skillRoot -Directory -ErrorAction SilentlyContinue) {
            if (-not (Test-InManagedScope -Scope $managedScope -Kind 'skills' -Name $skillDir.Name)) { continue }
            $skillFile = Join-Path $skillDir.FullName 'SKILL.md'
            $evalFile = Join-Path $skillDir.FullName 'eval.yaml'
            if (-not (Test-Path -LiteralPath $skillFile)) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing SKILL.md' -Path (Get-RelativePath -Root $repoRoot -Path $skillDir.FullName)
                continue
            }
            if (-not (Test-Path -LiteralPath $evalFile)) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing eval.yaml' -Path (Get-RelativePath -Root $repoRoot -Path $skillDir.FullName)
            }
            $fm = Get-FrontMatterLines -Path $skillFile
            if (-not $fm) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing valid frontmatter' -Path (Get-RelativePath -Root $repoRoot -Path $skillFile)
                continue
            }
            $skillName = Get-FMScalar -Lines $fm -Key 'name'
            if (-not $skillName) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing frontmatter name' -Path (Get-RelativePath -Root $repoRoot -Path $skillFile)
            }
            elseif ($skillName -ne $skillDir.Name) {
                Add-Message -Section $structureSection -Level 'error' -Message "Frontmatter name '$skillName' must match folder '$($skillDir.Name)'" -Path (Get-RelativePath -Root $repoRoot -Path $skillFile)
            }
            $desc = Get-FMScalar -Lines $fm -Key 'description'
            if (-not $desc) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing description' -Path (Get-RelativePath -Root $repoRoot -Path $skillFile)
            } else {
                if ($desc -notmatch 'USE FOR:') {
                    Add-Message -Section $structureSection -Level 'error' -Message "Description missing 'USE FOR:' trigger phrases" -Path (Get-RelativePath -Root $repoRoot -Path $skillFile)
                }
                if ($desc -notmatch 'DO NOT USE FOR:') {
                    Add-Message -Section $structureSection -Level 'error' -Message "Description missing 'DO NOT USE FOR:' anti-triggers" -Path (Get-RelativePath -Root $repoRoot -Path $skillFile)
                }
            }
            $skillRefs = @(Get-FMList -Lines $fm -Key 'skills')
            foreach ($refSkill in $skillRefs) {
                if ($assetSets.skills -notcontains $refSkill) {
                    Add-Message -Section $structureSection -Level 'error' -Message "Composed skill '$refSkill' does not resolve to an existing synced skill" -Path (Get-RelativePath -Root $repoRoot -Path $skillFile)
                }
            }
            $instructionRefs = @(Get-FMList -Lines $fm -Key 'instructions')
            foreach ($refInstruction in $instructionRefs) {
                if ($assetSets.instructions -notcontains $refInstruction) {
                    Add-Message -Section $structureSection -Level 'error' -Message "Composed instruction '$refInstruction' does not resolve to an existing synced instruction" -Path (Get-RelativePath -Root $repoRoot -Path $skillFile)
                }
            }
            if (Test-Path -LiteralPath $evalFile) {
                $evalLines = Get-Content -LiteralPath $evalFile
                $positive = @($evalLines | Where-Object { $_ -match 'expect_activation:\s*true' }).Count
                $negative = @($evalLines | Where-Object { $_ -match 'expect_activation:\s*false' }).Count
                if ($positive -lt 3 -or $negative -lt 2) {
                    Add-Message -Section $structureSection -Level 'error' -Message 'eval.yaml requires at least 3 positive and 2 negative scenarios' -Path (Get-RelativePath -Root $repoRoot -Path $evalFile)
                }
            }
        }
    }

    # Agent validation (Sheen-managed assets only in consumers — #93).
    $agentRoot = Join-Path $repoRoot $agentPath.Replace('/','\')
    if (Test-Path -LiteralPath $agentRoot) {
        foreach ($agentFile in Get-ChildItem -LiteralPath $agentRoot -Filter '*.agent.md' -File -ErrorAction SilentlyContinue) {
            $expectedBase = $agentFile.BaseName -replace '\.agent$',''
            if (-not (Test-InManagedScope -Scope $managedScope -Kind 'agents' -Name $expectedBase)) { continue }
            $fm = Get-FrontMatterLines -Path $agentFile.FullName
            if (-not $fm) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing valid frontmatter' -Path (Get-RelativePath -Root $repoRoot -Path $agentFile.FullName)
                continue
            }
            $name = Get-FMScalar -Lines $fm -Key 'name'
            if (-not $name) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing frontmatter name' -Path (Get-RelativePath -Root $repoRoot -Path $agentFile.FullName)
            }
            elseif ($name -ne $expectedBase) {
                Add-Message -Section $structureSection -Level 'error' -Message "Frontmatter name '$name' must match file name '$expectedBase'" -Path (Get-RelativePath -Root $repoRoot -Path $agentFile.FullName)
            }
            $desc = Get-FMScalar -Lines $fm -Key 'description'
            if (-not $desc) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing description' -Path (Get-RelativePath -Root $repoRoot -Path $agentFile.FullName)
            }
            $skillRefs = @(Get-FMList -Lines $fm -Key 'skills')
            foreach ($refSkill in $skillRefs) {
                if ($assetSets.skills -notcontains $refSkill) {
                    Add-Message -Section $structureSection -Level 'error' -Message "Composed skill '$refSkill' does not resolve to an existing synced skill" -Path (Get-RelativePath -Root $repoRoot -Path $agentFile.FullName)
                }
            }
            $instructionRefs = @(Get-FMList -Lines $fm -Key 'instructions')
            foreach ($refInstruction in $instructionRefs) {
                if ($assetSets.instructions -notcontains $refInstruction) {
                    Add-Message -Section $structureSection -Level 'error' -Message "Composed instruction '$refInstruction' does not resolve to an existing synced instruction" -Path (Get-RelativePath -Root $repoRoot -Path $agentFile.FullName)
                }
            }
            $evalFile = Join-Path $agentFile.DirectoryName (($agentFile.BaseName -replace '\.agent$','') + '.agent.eval.yaml')
            if (-not (Test-Path -LiteralPath $evalFile)) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing eval file' -Path (Get-RelativePath -Root $repoRoot -Path $agentFile.FullName)
            }
        }
    }

    # Instruction validation (Sheen-managed assets only in consumers — #93).
    $instructionRoot = Join-Path $repoRoot $instructionPath.Replace('/','\')
    if (Test-Path -LiteralPath $instructionRoot) {
        foreach ($insFile in Get-ChildItem -LiteralPath $instructionRoot -Filter '*.instructions.md' -File -ErrorAction SilentlyContinue) {
            $expectedBase = $insFile.BaseName -replace '\.instructions$',''
            if (-not (Test-InManagedScope -Scope $managedScope -Kind 'instructions' -Name $expectedBase)) { continue }
            $fm = Get-FrontMatterLines -Path $insFile.FullName
            if (-not $fm) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing valid frontmatter' -Path (Get-RelativePath -Root $repoRoot -Path $insFile.FullName)
                continue
            }
            if ($insFile.Name -notmatch '^sheen-[0-9]{2}-[a-z0-9-]+\.instructions\.md$') {
                Add-Message -Section $structureSection -Level 'error' -Message 'Invalid instruction naming convention' -Path (Get-RelativePath -Root $repoRoot -Path $insFile.FullName)
            }
            $name = Get-FMScalar -Lines $fm -Key 'name'
            if (-not $name) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing frontmatter name' -Path (Get-RelativePath -Root $repoRoot -Path $insFile.FullName)
            }
            elseif ($name -ne $expectedBase) {
                Add-Message -Section $structureSection -Level 'error' -Message "Frontmatter name '$name' must match file name '$expectedBase'" -Path (Get-RelativePath -Root $repoRoot -Path $insFile.FullName)
            }
            if (-not (Get-FMScalar -Lines $fm -Key 'description')) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing description' -Path (Get-RelativePath -Root $repoRoot -Path $insFile.FullName)
            }
            if (-not (Get-FMScalar -Lines $fm -Key 'applyTo')) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing applyTo' -Path (Get-RelativePath -Root $repoRoot -Path $insFile.FullName)
            }
            if (-not (Get-FMScalar -Lines $fm -Key 'band')) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing metadata.band' -Path (Get-RelativePath -Root $repoRoot -Path $insFile.FullName)
            }
            if (-not (Get-FMScalar -Lines $fm -Key 'layer')) {
                Add-Message -Section $structureSection -Level 'error' -Message 'Missing metadata.layer' -Path (Get-RelativePath -Root $repoRoot -Path $insFile.FullName)
            }
        }
    }

    # Token validation.
    $tokenRoot = Join-Path $repoRoot $tokenPath.Replace('/','\')
    if (Test-Path -LiteralPath $tokenRoot) {
        $tokenFiles = @(Get-ChildItem -LiteralPath $tokenRoot -Recurse -Filter '*.tokens.json' -File -ErrorAction SilentlyContinue)
        $maps = @{
            core     = [ordered]@{}
            semantic = [ordered]@{}
            theme    = [ordered]@{}
        }
        $parsed = @{}
        foreach ($file in $tokenFiles) {
            try {
                $tokenJson = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json -Depth 50
                $fileKey = [string]$file.FullName
                $parsed[$fileKey] = $tokenJson
            } catch {
                Add-Message -Section $tokensSection -Level 'error' -Message "Invalid JSON: $($_.Exception.Message)" -Path (Get-RelativePath -Root $repoRoot -Path $file.FullName)
                continue
            }
            $flat = Get-TokenFlatMap -Node $tokenJson
            $rel = Get-RelativePath -Root $repoRoot -Path $file.FullName
            if ($rel -like "$tokenPath/core/*") {
                foreach ($k in $flat.Keys) {
                    foreach ($ref in @(Get-TokenRefs -Node $flat[$k].'$value')) {
                        Add-Message -Section $tokensSection -Level 'error' -Message "Core token '$k' contains an alias reference '{$ref}'" -Path $rel
                    }
                }
                foreach ($k in $flat.Keys) { $maps.core[$k] = $flat[$k] }
            }
            elseif ($rel -like "$tokenPath/semantic/*") {
                foreach ($k in $flat.Keys) {
                    foreach ($ref in @(Get-TokenRefs -Node $flat[$k].'$value')) {
                        if (-not $maps.core.Contains($ref)) {
                            Add-Message -Section $tokensSection -Level 'error' -Message "Semantic token '$k' references missing core token '{$ref}'" -Path $rel
                        }
                    }
                }
                foreach ($k in $flat.Keys) { $maps.semantic[$k] = $flat[$k] }
            }
            elseif ($rel -like "$tokenPath/themes/*") {
                foreach ($k in $flat.Keys) { $maps.theme[$k] = $flat[$k] }
            }
        }

        if ($maps.semantic.Count -gt 0) {
            foreach ($k in $maps.semantic.Keys) {
                foreach ($ref in @(Get-TokenRefs -Node $maps.semantic[$k].'$value')) {
                    if (-not $maps.core.Contains($ref)) {
                        Add-Message -Section $tokensSection -Level 'error' -Message "Semantic token '$k' references missing core token '{$ref}'" -Path "$tokenPath/semantic"
                    }
                }
            }
        }

        $expectedThemes = if ($configData.Contains('themes') -and @($configData['themes']).Count -gt 0) { @($configData['themes']) } else { @('light','dark','high-contrast') }
        foreach ($themeName in $expectedThemes) {
            $themePath = Join-Path $tokenRoot "themes\$themeName.tokens.json"
            if (-not (Test-Path -LiteralPath $themePath)) {
                Add-Message -Section $tokensSection -Level 'error' -Message "Expected theme file missing" -Path (Get-RelativePath -Root $repoRoot -Path $themePath)
            }
        }

        $semanticKeys = @($maps.semantic.Keys | Sort-Object -Unique)
        foreach ($file in $tokenFiles | Where-Object { (Get-RelativePath -Root $repoRoot -Path $_.FullName) -like "$tokenPath/themes/*" }) {
            $rel = Get-RelativePath -Root $repoRoot -Path $file.FullName
            $themeName = $file.BaseName -replace '\.tokens$',''
            if ($configData.Contains('themes') -and @($configData['themes']).Count -gt 0 -and ($configData['themes'] -notcontains $themeName)) {
                continue
            }
            $themeJson = $parsed[[string]$file.FullName]
            if ($null -eq $themeJson) {
                Add-Message -Section $tokensSection -Level 'error' -Message 'Theme JSON was not parsed' -Path $rel
                continue
            }
            $themeFlat = Get-TokenFlatMap -Node $themeJson
            foreach ($k in $semanticKeys) {
                if (-not $themeFlat.Contains($k)) {
                    Add-Message -Section $tokensSection -Level 'error' -Message "Theme is missing semantic token '$k'" -Path $rel
                }
            }
            foreach ($k in $themeFlat.Keys) {
                if (-not $maps.semantic.Contains($k)) {
                    Add-Message -Section $tokensSection -Level 'error' -Message "Theme introduces non-semantic token '$k'" -Path $rel
                }
            }
            foreach ($k in $themeFlat.Keys) {
                foreach ($ref in @(Get-TokenRefs -Node $themeFlat[$k].'$value')) {
                    $resolver = Resolve-TokenRef -Ref $ref -Maps $maps -Order @('theme','semantic','core') -Seen @{} -CurrentScope 'theme' -CurrentKey $k
                    if ($resolver -eq '__MISSING__') {
                        Add-Message -Section $tokensSection -Level 'error' -Message "Theme token '$k' references missing token '{$ref}'" -Path $rel
                    }
                    elseif ($null -eq $resolver) {
                        Add-Message -Section $tokensSection -Level 'error' -Message "Theme token '$k' contains a circular reference through '{$ref}'" -Path $rel
                    }
                }
            }
        }
    }

    # Namespace collisions against vendored basecoat (Sheen-managed locals only — #93).
    $vendorRoot = Join-Path $repoRoot 'vendor\basecoat'
    if (Test-Path -LiteralPath $vendorRoot) {
        $localSkills = @($assetSets.skills | Where-Object { Test-InManagedScope -Scope $managedScope -Kind 'skills' -Name $_ })
        $localAgents = @($assetSets.agents | Where-Object { Test-InManagedScope -Scope $managedScope -Kind 'agents' -Name $_ })
        $vendorSkills = @()
        $vendorAgents = @()
        $vendorSkillRoot = Join-Path $vendorRoot 'skills'
        if (Test-Path -LiteralPath $vendorSkillRoot) {
            $vendorSkills = @(Get-ChildItem -LiteralPath $vendorSkillRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
        }
        $vendorAgentRoot = Join-Path $vendorRoot 'agents'
        if (Test-Path -LiteralPath $vendorAgentRoot) {
            $vendorAgents = @(Get-ChildItem -LiteralPath $vendorAgentRoot -Filter '*.agent.md' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.BaseName -replace '\.agent$','' })
        }

        foreach ($name in $localSkills) {
            if ($name -like 'basecoat-*') {
                Add-Message -Section $collisionsSection -Level 'error' -Message "Reserved prefix conflict: local skill '$name' must not use basecoat-* naming" -Path $skillPath
            }
            if ($vendorSkills -contains $name) {
                Add-Message -Section $collisionsSection -Level 'error' -Message "Duplicate skill name collides with vendored basecoat: $name" -Path $skillPath
            }
        }
        foreach ($name in $localAgents) {
            if ($name -like 'basecoat-*') {
                Add-Message -Section $collisionsSection -Level 'error' -Message "Reserved prefix conflict: local agent '$name' must not use basecoat-* naming" -Path $agentPath
            }
            if ($vendorAgents -contains $name) {
                Add-Message -Section $collisionsSection -Level 'error' -Message "Duplicate agent name collides with vendored basecoat: $name" -Path $agentPath
            }
        }
    }

    $sections = @($configSection, $structureSection, $tokensSection, $collisionsSection)
    $summary = [ordered]@{ pass = 0; warn = 0; error = 0; exit_code = 0 }
    foreach ($section in $sections) {
        switch ($section.status) {
            'pass'  { $summary['pass']++ }
            'warn'  { $summary['warn']++ }
            'error' { $summary['error']++ }
        }
    }
    if ($summary['error'] -gt 0) { $summary['exit_code'] = 1 }

    $configSection.valid = ($configSection.status -ne 'error')
    $structureSection.valid = ($structureSection.status -ne 'error')
    $tokensSection.valid = ($tokensSection.status -ne 'error')
    $collisionsSection.valid = ($collisionsSection.status -ne 'error')

    $configSkillCount = if ($configData.Contains('skills')) { @($configData['skills']).Count } else { 0 }
    $configAgentCount = if ($configData.Contains('agents')) { @($configData['agents']).Count } else { 0 }
    $configInstructionCount = if ($configData.Contains('instructions')) { @($configData['instructions']).Count } else { 0 }
    $configThemeCount = if ($configData.Contains('themes')) { @($configData['themes']).Count } else { 0 }
    $configMessages = $configSection.messages.ToArray()
    $structureMessages = $structureSection.messages.ToArray()
    $tokenMessages = $tokensSection.messages.ToArray()
    $collisionMessages = $collisionsSection.messages.ToArray()

    $report = [ordered]@{}
    $report['timestamp'] = (Get-Date).ToUniversalTime().ToString('o')
    $report['config'] = [ordered]@{
        'valid'        = $configSection.valid
        'source'       = $source
        'ref'          = $ref
        'skills'       = $configSkillCount
        'agents'       = $configAgentCount
        'instructions' = $configInstructionCount
        'themes'       = $configThemeCount
        'messages'     = $configMessages
    }
    $report['structure'] = [ordered]@{
        valid    = $structureSection.valid
        messages = $structureMessages
    }
    $report['tokens'] = [ordered]@{
        valid      = $tokensSection.valid
        themes     = @($expectedThemes)
        resolution = [ordered]@{
            core     = @($maps.core.Keys).Count
            semantic = @($maps.semantic.Keys).Count
            themes   = @($maps.theme.Keys).Count
        }
        messages   = $tokenMessages
    }
    $report['collisions'] = [ordered]@{
        found    = (-not $collisionsSection.valid)
        details  = $collisionMessages
        messages = $collisionMessages
    }
    $report['summary'] = $summary

    if ($Json) {
        $report | ConvertTo-Json -Depth 12
    } else {
        Write-Host "sheen diagnostics: $($summary['pass']) pass, $($summary['warn']) warn, $($summary['error']) error"
        foreach ($section in $sections) {
            Write-Host ("[{0}] {1}" -f $section.status.ToUpperInvariant(), $section.name)
            foreach ($message in $section.messages) {
                Write-Host (Format-StatusLine -Level $message.level -Message $message.message -Path $message.path)
            }
        }
        if ($summary['error'] -eq 0) {
            Write-Host 'Recommendations: keep the allow-lists pinned, re-run after each sync, and capture the JSON report in CI.'
        } elseif ($configSection.status -eq 'error') {
            Write-Host 'Recommendations: fix .sheen.yml first, then re-run diagnostics.'
        } elseif ($tokensSection.status -eq 'error') {
            Write-Host 'Recommendations: repair token references and theme completeness before rollout.'
        } elseif ($collisionsSection.status -eq 'error') {
            Write-Host 'Recommendations: rename the colliding local asset or narrow the sync allow-list.'
        }
    }

    exit $summary['exit_code']
}
catch {
    $fatalError = $_
    if ($Json) {
        [ordered]@{
            timestamp = (Get-Date).ToUniversalTime().ToString('o')
            error     = [ordered]@{
                message = $fatalError.Exception.Message
            }
            summary   = [ordered]@{ pass = 0; warn = 0; error = 1; exit_code = 2 }
        } | ConvertTo-Json -Depth 6
    } else {
        Write-Host "[ERROR] diagnostic tool failed: $($fatalError.Exception.Message)"
    }
    exit 2
}

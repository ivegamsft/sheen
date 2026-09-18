#!/usr/bin/env pwsh
# Deterministic, fixture-driven tests for style-guide-authoring's canonical
# input mapping and read-only freshness assessment (#228). Builds small
# synthetic scratch guides/manifests/tokens under $env:TEMP (never inside
# the repo working tree) and exercises GuideInputs.psm1 directly, including
# mutation checks proving each rule actually catches its violation and a
# literal no-write assertion for Check mode. Uses Join-Path with a single
# child segment per call (composed via -AdditionalChildPath) so the module
# path resolves correctly on both Windows and ubuntu-latest runners.
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$repoRoot = Split-Path $PSScriptRoot
$modulePath = Join-Path $repoRoot 'skills' -AdditionalChildPath 'style-guide-authoring', 'scripts', 'GuideInputs.psm1'
Import-Module $modulePath -Force

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "ASSERTION FAILED: $Message" } }
function Assert-Equal { param($Expected, $Actual, [string]$Message) Assert-True ($Expected -eq $Actual) "$Message (expected '$Expected', got '$Actual')" }
function Assert-Throws {
    param([scriptblock]$Script, [string]$Message, [string]$ExpectedSubstring = $null)
    $threw = $false
    $errMsg = $null
    try { & $Script } catch { $threw = $true; $errMsg = $_.Exception.Message }
    Assert-True $threw "$Message (expected an exception, none thrown)"
    if ($ExpectedSubstring) {
        Assert-True ($errMsg -like "*$ExpectedSubstring*") "$Message (exception message '$errMsg' did not contain '$ExpectedSubstring')"
    }
}

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("sga-228-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch -Force | Out-Null
try {
    # --- Shared fixture inputs -------------------------------------------------
    $tokensPath = Join-Path $scratch 'tokens.color.json'
    Set-Content -LiteralPath $tokensPath -Value '{"$type":"color","primary":"#123456"}' -NoNewline
    $tokenDigestV1 = Get-FileDigest -Path $tokensPath

    $brandGuideDigest = 'sha256:' + ('a' * 64)

    function New-Manifest {
        param([string]$Path, [array]$Sources)
        @{ sources = $Sources } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Path -NoNewline
    }

    function New-Guide {
        param(
            [string]$Path,
            [hashtable[]]$Rows,
            [hashtable[]]$OwnedModules,   # each: @{ Id=; Sources=; Body= }
            [hashtable[]]$ModuleStatuses = @(), # each: @{ Module=; Status=; Owner=; Sources=; Missing= }
            [string]$ConsumerNote = "`n## Consumer notes`n`nOur design team added this manually.`n"
        )
        $tableRows = ($Rows | ForEach-Object { "| $($_.SourceId) | $($_.Revision) | $($_.ApprovalState) | $($_.Scope) |" }) -join "`n"
        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.AppendLine('# Fixture Guide')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('### Approved inputs')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('| Source ID | Revision or digest | Approval state | Supported module or rule |')
        [void]$sb.AppendLine('|---|---|---|---|')
        [void]$sb.AppendLine($tableRows)
        [void]$sb.AppendLine('')
        if ($ModuleStatuses.Count -gt 0) {
            $statusRows = ($ModuleStatuses | ForEach-Object {
                $missing = $_.Missing
                if ($_.Status -eq 'not applicable' -and -not $missing) { $missing = 'Not applicable for this fixture.' }
                "| $($_.Module) | $($_.Status) | $($_.Owner) | $($_.Sources) | $missing |"
            }) -join "`n"
            [void]$sb.AppendLine('### Module status')
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('| Module | Status | Owner | Approved source IDs | Missing or proposed items |')
            [void]$sb.AppendLine('|---|---|---|---|---|')
            [void]$sb.AppendLine($statusRows)
            [void]$sb.AppendLine('')
        }
        foreach ($m in $OwnedModules) {
            $body = $m.Body
            $rev = Get-TextDigest -Text $body
            [void]$sb.AppendLine("<!-- guide-owned:$($m.Id) sources=`"$($m.Sources -join ',')`" revision=`"$rev`" -->$body<!-- /guide-owned:$($m.Id) -->")
        }
        [void]$sb.Append($ConsumerNote)
        Set-Content -LiteralPath $Path -Value $sb.ToString() -NoNewline
    }

    # === Scenario 1: conflicting approved sources block readiness ==============
    Write-Host '[1/12] conflicting approved sources -> BLOCKED'
    $manifest1 = Join-Path $scratch 'manifest1.json'
    New-Manifest -Path $manifest1 -Sources @(
        @{ id = 'guide:brand-a'; kind = 'approved-guide'; scope = 'foundations'; rule = 'primary-principle'; status = 'APPROVED'; value = 'clarity-first'; digest = $brandGuideDigest },
        @{ id = 'guide:brand-b'; kind = 'approved-guide'; scope = 'foundations'; rule = 'primary-principle'; status = 'APPROVED'; value = 'boldness-first'; digest = ('sha256:' + ('b' * 64)) }
    )
    $guide1 = Join-Path $scratch 'guide1.md'
    New-Guide -Path $guide1 -Rows @(
        @{ SourceId = 'guide:brand-a'; Revision = $brandGuideDigest; ApprovalState = 'APPROVED'; Scope = 'foundations' }
    ) -OwnedModules @()
    $r1 = Test-GuideFreshness -GuidePath $guide1 -ManifestPath $manifest1 -RepoRoot $scratch
    Assert-Equal 'BLOCKED' $r1.Overall 'Conflicting approved sources for one scope must BLOCK'
    Assert-Equal 'BLOCKED' $r1.Modules['foundations'] 'Conflicted module must report BLOCKED'
    $manifest1EmptyValue = Join-Path $scratch 'manifest1-empty-value.json'
    New-Manifest -Path $manifest1EmptyValue -Sources @(
        @{ id = 'guide:empty'; kind = 'approved-guide'; scope = 'foundations'; rule = 'primary-principle'; status = 'APPROVED'; value = ''; digest = $brandGuideDigest },
        @{ id = 'guide:nonempty'; kind = 'approved-guide'; scope = 'foundations'; rule = 'primary-principle'; status = 'APPROVED'; value = 'clarity-first'; digest = ('sha256:' + ('b' * 64)) }
    )
    $r1EmptyValue = Test-GuideFreshness -GuidePath $guide1 -ManifestPath $manifest1EmptyValue -RepoRoot $scratch
    Assert-Equal 'BLOCKED' $r1EmptyValue.Overall 'Conflicting approved empty and nonempty values for one scope/rule must BLOCK'
    $manifest1IncompleteComparable = Join-Path $scratch 'manifest1-incomplete-comparable.json'
    New-Manifest -Path $manifest1IncompleteComparable -Sources @(
        @{ id = 'guide:brand-a'; kind = 'approved-guide'; scope = 'foundations'; status = 'APPROVED'; digest = $brandGuideDigest },
        @{ id = 'guide:brand-b'; kind = 'approved-guide'; scope = 'foundations'; rule = 'primary-principle'; status = 'APPROVED'; value = 'clarity-first'; digest = $brandGuideDigest }
    )
    $guide1CompleteEvidence = Join-Path $scratch 'guide1-complete-evidence.md'
    New-Guide -Path $guide1CompleteEvidence -Rows @(
        @{ SourceId = 'guide:brand-a'; Revision = $brandGuideDigest; ApprovalState = 'APPROVED'; Scope = 'foundations' }
    ) -OwnedModules @(
        @{ Id = 'foundations'; Sources = @('guide:brand-a'); Body = "`nFoundations evidence is complete except conflict-comparison metadata.`n" }
    )
    $incompleteComparable = Test-GuideFreshness -GuidePath $guide1CompleteEvidence -ManifestPath $manifest1IncompleteComparable -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $incompleteComparable.Overall 'Multiple approved sources with incomplete rule/value conflict metadata must degrade to UNKNOWN, not CURRENT'
    $manifest1Ruleless = Join-Path $scratch 'manifest1-ruleless.json'
    New-Manifest -Path $manifest1Ruleless -Sources @(
        @{ id = 'guide:brand-a'; kind = 'approved-guide'; scope = 'foundations'; status = 'APPROVED'; value = 'clarity-first'; digest = $brandGuideDigest },
        @{ id = 'guide:brand-b'; kind = 'approved-guide'; scope = 'foundations'; status = 'APPROVED'; value = 'boldness-first'; digest = ('sha256:' + ('b' * 64)) }
    )
    $rulelessComparable = Test-GuideFreshness -GuidePath $guide1CompleteEvidence -ManifestPath $manifest1Ruleless -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $rulelessComparable.Overall 'Rule-less approved sources must not be grouped into a false conflicting rule'
    $manifest1UnusedIncompleteComparable = Join-Path $scratch 'manifest1-unused-incomplete-comparable.json'
    New-Manifest -Path $manifest1UnusedIncompleteComparable -Sources @(
        @{ id = 'guide:brand-a'; kind = 'approved-guide'; scope = 'foundations'; status = 'APPROVED'; digest = $brandGuideDigest },
        @{ id = 'guide:type-a'; kind = 'approved-guide'; scope = 'typography'; status = 'APPROVED'; value = 'sans'; digest = $brandGuideDigest },
        @{ id = 'guide:type-b'; kind = 'approved-guide'; scope = 'typography'; status = 'APPROVED'; digest = $brandGuideDigest }
    )
    $unusedIncompleteComparable = Test-GuideFreshness -GuidePath $guide1CompleteEvidence -ManifestPath $manifest1UnusedIncompleteComparable -RepoRoot $scratch
    Assert-Equal 'CURRENT' $unusedIncompleteComparable.Overall 'Fallback freshness must ignore incomplete conflict metadata for manifest scopes not represented by Approved inputs'
    $guide1IncludedNoRows = Join-Path $scratch 'guide1-included-no-rows.md'
    New-Guide -Path $guide1IncludedNoRows -Rows @() -OwnedModules @() -ModuleStatuses @(
        @{ Module = 'orientation'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' },
        @{ Module = 'foundations'; Status = 'included'; Owner = 'brand-identity'; Sources = 'guide:brand-a'; Missing = '' },
        @{ Module = 'identity-assets'; Status = 'not applicable'; Owner = 'brand-steward'; Sources = ''; Missing = '' },
        @{ Module = 'usage-constraints'; Status = 'not applicable'; Owner = 'logo-usage'; Sources = ''; Missing = '' },
        @{ Module = 'visual-foundations'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' },
        @{ Module = 'imagery-illustration'; Status = 'not applicable'; Owner = 'imagery-illustration'; Sources = ''; Missing = '' },
        @{ Module = 'typography'; Status = 'not applicable'; Owner = 'ux-writing'; Sources = ''; Missing = '' },
        @{ Module = 'voice-messaging'; Status = 'not applicable'; Owner = 'brand-voice-tone'; Sources = ''; Missing = '' },
        @{ Module = 'application-patterns'; Status = 'not applicable'; Owner = 'pattern-library'; Sources = ''; Missing = '' },
        @{ Module = 'resources-governance'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' }
    )
    $r1IncludedNoRows = Test-GuideFreshness -GuidePath $guide1IncludedNoRows -ManifestPath $manifest1 -RepoRoot $scratch
    Assert-Equal 'BLOCKED' $r1IncludedNoRows.Overall 'A conflicted included scope must BLOCK even without rows or owned regions'
    # Mutation: resolve the conflict (same value) -> no longer blocked
    New-Manifest -Path $manifest1 -Sources @(
        @{ id = 'guide:brand-a'; kind = 'approved-guide'; scope = 'foundations'; rule = 'primary-principle'; status = 'APPROVED'; value = 'clarity-first'; digest = $brandGuideDigest },
        @{ id = 'guide:brand-b'; kind = 'approved-guide'; scope = 'foundations'; rule = 'primary-principle'; status = 'APPROVED'; value = 'clarity-first'; digest = ('sha256:' + ('b' * 64)) }
    )
    $r1b = Test-GuideFreshness -GuidePath $guide1 -ManifestPath $manifest1 -RepoRoot $scratch
    Assert-True ($r1b.Overall -ne 'BLOCKED') 'Resolving the value conflict must clear BLOCKED (proves real detection, not a false positive)'

    # === Scenario 2: row-only provenance still requires owned evidence ==========
    Write-Host '[2/12] row-only provenance requires owned-artifact evidence'
    $manifest2 = Join-Path $scratch 'manifest2.json'
    New-Manifest -Path $manifest2 -Sources @(
        @{ id = 'tokens:color'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'tokens.color.json' }
    )
    $guide2 = Join-Path $scratch 'guide2.md'
    New-Guide -Path $guide2 -Rows @(
        @{ SourceId = 'tokens:color'; Revision = $tokenDigestV1; ApprovalState = 'DERIVED'; Scope = 'visual-foundations' }
    ) -OwnedModules @()
    $r2current = Test-GuideFreshness -GuidePath $guide2 -ManifestPath $manifest2 -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $r2current.Overall 'A provenance-only row must stay UNKNOWN until matching guide-owned artifact evidence exists'
    # Mutate the token source (simulates a real design-token edit)
    Set-Content -LiteralPath $tokensPath -Value '{"$type":"color","primary":"#654321"}' -NoNewline
    $r2 = Test-GuideFreshness -GuidePath $guide2 -ManifestPath $manifest2 -RepoRoot $scratch
    Assert-Equal 'STALE' $r2.Overall 'Changed mechanical token facts must be reported STALE'
    Assert-Equal 'STALE' $r2.Modules['visual-foundations'] 'Affected module must be enumerated as STALE'
    $guide2MixedEvidence = Join-Path $scratch 'guide2-mixed-evidence.md'
    New-Guide -Path $guide2MixedEvidence -Rows @(
        @{ SourceId = 'tokens:color'; Revision = $tokenDigestV1; ApprovalState = 'DERIVED'; Scope = 'visual-foundations' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('tokens:color', 'tokens:missing-row'); Body = "`nMixed evidence must preserve stale precedence.`n" }
    )
    $r2Mixed = Test-GuideFreshness -GuidePath $guide2MixedEvidence -ManifestPath $manifest2 -RepoRoot $scratch
    Assert-Equal 'STALE' $r2Mixed.Modules['visual-foundations'] 'Missing owned-region provenance must not downgrade an already STALE module to UNKNOWN'
    # restore for later scenarios
    Set-Content -LiteralPath $tokensPath -Value '{"$type":"color","primary":"#123456"}' -NoNewline

    # === Scenario 3: valid equivalents when native artifacts are absent =========
    Write-Host '[3/12] approved equivalent stands in for an absent native artifact'
    $manifest3 = Join-Path $scratch 'manifest3.json'
    New-Manifest -Path $manifest3 -Sources @(
        @{ id = 'design-md'; kind = 'derived'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'missing-design.md' },
        @{ id = 'tokens:color'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'tokens.color.json'; equivalentFor = @('design-md') }
    )
    $guide3 = Join-Path $scratch 'guide3.md'
    New-Guide -Path $guide3 -Rows @(
        @{ SourceId = 'design-md'; Revision = $tokenDigestV1; ApprovalState = 'DERIVED'; Scope = 'visual-foundations' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('design-md'); Body = "`nEquivalent evidence is already reflected in the owned artifact.`n" }
    )
    $r3 = Test-GuideFreshness -GuidePath $guide3 -ManifestPath $manifest3 -RepoRoot $scratch
    Assert-Equal 'CURRENT' $r3.Overall "Absent 'design-md' with an approved equivalent must resolve, not UNKNOWN"
    # Mutation: remove the equivalence declaration -> the same row must now be UNKNOWN
    New-Manifest -Path $manifest3 -Sources @(
        @{ id = 'design-md'; kind = 'derived'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'missing-design.md' },
        @{ id = 'tokens:color'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'tokens.color.json' }
    )
    $r3b = Test-GuideFreshness -GuidePath $guide3 -ManifestPath $manifest3 -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $r3b.Overall 'Without a declared equivalence, a missing named artifact must stay UNKNOWN (proves the equivalence path is load-bearing)'
    # Mutation: an equivalent whose status is unapproved (PROPOSED) must not satisfy a DERIVED/APPROVED row
    $manifest3c = Join-Path $scratch 'manifest3c.json'
    New-Manifest -Path $manifest3c -Sources @(
        @{ id = 'guide:proposed-a'; kind = 'approved-guide'; scope = 'visual-foundations'; status = 'PROPOSED'; digest = $tokenDigestV1; equivalentFor = @('design-md') }
    )
    $r3c = Test-GuideFreshness -GuidePath $guide3 -ManifestPath $manifest3c -RepoRoot $scratch
    Assert-True ($r3c.Overall -ne 'CURRENT') 'An unapproved (PROPOSED) equivalent must not satisfy a DERIVED-recorded row or yield CURRENT'
    $manifest3Template = Join-Path $scratch 'manifest3-template.json'
    New-Manifest -Path $manifest3Template -Sources @(
        @{ id = 'template:brand-guidelines'; kind = 'template'; status = 'TEMPLATE'; digest = $tokenDigestV1 }
    )
    $guide3Template = Join-Path $scratch 'guide3-template.md'
    New-Guide -Path $guide3Template -Rows @(
        @{ SourceId = 'template:brand-guidelines'; Revision = $tokenDigestV1; ApprovalState = 'TEMPLATE'; Scope = 'visual-foundations' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('template:brand-guidelines'); Body = "`nTemplate structure cannot satisfy scoped evidence.`n" }
    )
    $r3Template = Test-GuideFreshness -GuidePath $guide3Template -ManifestPath $manifest3Template -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $r3Template.Overall 'A scope-less template source must not satisfy a scoped module row'
    # Multiple eligible equivalents resolve only when the recorded revision
    # identifies exactly one; otherwise ownership/evidence is ambiguous.
    $manifest3d = Join-Path $scratch 'manifest3d.json'
    New-Manifest -Path $manifest3d -Sources @(
        @{ id = 'tokens:matching'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; digest = $tokenDigestV1; equivalentFor = @('design-md') },
        @{ id = 'tokens:other'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; digest = ('sha256:' + ('c' * 64)); equivalentFor = @('design-md') }
    )
    $r3d = Test-GuideFreshness -GuidePath $guide3 -ManifestPath $manifest3d -RepoRoot $scratch
    Assert-Equal 'CURRENT' $r3d.Overall 'A unique equivalent matching the recorded revision must resolve deterministically'
    $guide3Ambiguous = Join-Path $scratch 'guide3-ambiguous.md'
    New-Guide -Path $guide3Ambiguous -Rows @(
        @{ SourceId = 'design-md'; Revision = ('sha256:' + ('d' * 64)); ApprovalState = 'DERIVED'; Scope = 'visual-foundations' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('design-md'); Body = "`nAmbiguous equivalent guidance.`n" }
    )
    $r3e = Test-GuideFreshness -GuidePath $guide3Ambiguous -ManifestPath $manifest3d -RepoRoot $scratch
    Assert-Equal 'BLOCKED' $r3e.Overall 'Multiple eligible equivalents without a unique recorded-revision match must block'
    $manifest3DirectWins = Join-Path $scratch 'manifest3-direct-wins.json'
    New-Manifest -Path $manifest3DirectWins -Sources @(
        @{ id = 'design-md'; kind = 'derived'; scope = 'visual-foundations'; status = 'DERIVED'; digest = ('sha256:' + ('e' * 64)) },
        @{ id = 'tokens:color'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'tokens.color.json'; equivalentFor = @('design-md') }
    )
    $r3DirectWins = Test-GuideFreshness -GuidePath $guide3 -ManifestPath $manifest3DirectWins -RepoRoot $scratch
    Assert-Equal 'STALE' $r3DirectWins.Overall 'An available direct source must drive freshness instead of a matching equivalent'
    $manifest3ScopeLessEquivalent = Join-Path $scratch 'manifest3-scopeless-equivalent.json'
    New-Manifest -Path $manifest3ScopeLessEquivalent -Sources @(
        @{ id = 'template:visual-foundations'; kind = 'template'; status = 'TEMPLATE'; digest = $tokenDigestV1; equivalentFor = @('design-md') }
    )
    $r3ScopeLessEquivalent = Test-GuideFreshness -GuidePath $guide3 -ManifestPath $manifest3ScopeLessEquivalent -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $r3ScopeLessEquivalent.Overall 'A scope-less source must not satisfy a module row directly or as an equivalent'

    $manifest3d = Join-Path $scratch 'manifest3d.json'
    New-Manifest -Path $manifest3d -Sources @(
        @{ id = 'design-md'; kind = 'derived'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'missing-design.md' },
        @{ id = 'tokens:color-a'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'tokens.color.json'; equivalentFor = @('design-md') },
        @{ id = 'tokens:color-b'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; digest = ('sha256:' + ('c' * 64)); equivalentFor = @('design-md') }
    )
    $r3d = Test-GuideFreshness -GuidePath $guide3 -ManifestPath $manifest3d -RepoRoot $scratch
    Assert-Equal 'CURRENT' $r3d.Overall 'Exactly one eligible equivalent matching the recorded revision must resolve deterministically'

    $manifest3e = Join-Path $scratch 'manifest3e.json'
    New-Manifest -Path $manifest3e -Sources @(
        @{ id = 'design-md'; kind = 'derived'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'missing-design.md' },
        @{ id = 'tokens:color-a'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'tokens.color.json'; equivalentFor = @('design-md') },
        @{ id = 'tokens:color-b'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'tokens.color.json'; equivalentFor = @('design-md') }
    )
    $r3e = Test-GuideFreshness -GuidePath $guide3 -ManifestPath $manifest3e -RepoRoot $scratch
    Assert-Equal 'BLOCKED' $r3e.Overall 'Multiple eligible equivalents with the same recorded revision must block as ambiguous'
    Assert-Equal 'BLOCKED' $r3e.Modules['visual-foundations'] 'Ambiguous equivalent resolution must block the affected module'

    $guide3Selection = Join-Path $scratch 'guide3-selection.md'
    New-Guide -Path $guide3Selection -Rows @(
        @{ SourceId = 'design-md'; Revision = $tokenDigestV1; ApprovalState = 'DERIVED'; Scope = 'visual-foundations' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('design-md'); Body = "`nEquivalent evidence is already reflected in the owned artifact.`n" },
        @{ Id = 'typography'; Sources = @('tokens:type'); Body = "`nLegacy excluded module content must not participate.`n" }
    ) -ModuleStatuses @(
        @{ Module = 'orientation'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' },
        @{ Module = 'foundations'; Status = 'not applicable'; Owner = 'brand-identity'; Sources = ''; Missing = '' },
        @{ Module = 'identity-assets'; Status = 'not applicable'; Owner = 'brand-steward'; Sources = ''; Missing = '' },
        @{ Module = 'usage-constraints'; Status = 'not applicable'; Owner = 'logo-usage'; Sources = ''; Missing = '' },
        @{ Module = 'visual-foundations'; Status = 'included'; Owner = 'design-reviewer'; Sources = 'design-md'; Missing = '' },
        @{ Module = 'imagery-illustration'; Status = 'not applicable'; Owner = 'imagery-illustration'; Sources = ''; Missing = '' },
        @{ Module = 'typography'; Status = 'not applicable'; Owner = 'ux-writing'; Sources = 'tokens:type'; Missing = '' },
        @{ Module = 'voice-messaging'; Status = 'not applicable'; Owner = 'brand-voice-tone'; Sources = ''; Missing = '' },
        @{ Module = 'application-patterns'; Status = 'not applicable'; Owner = 'pattern-library'; Sources = ''; Missing = '' },
        @{ Module = 'resources-governance'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' }
    )
    $selectionManifest = Join-Path $scratch 'manifest3-selection.json'
    New-Manifest -Path $selectionManifest -Sources @(
        @{ id = 'design-md'; kind = 'derived'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'missing-design.md' },
        @{ id = 'tokens:color'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'tokens.color.json'; equivalentFor = @('design-md') }
    )
    $selectedModules = Test-GuideFreshness -GuidePath $guide3Selection -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'CURRENT' $selectedModules.Overall 'Module status selection must limit owned-artifact requirements to explicitly included canonical modules'
    Assert-True ('typography' -notin @($selectedModules.Modules.Keys)) 'Canonical modules excluded by Module status must not participate when no retained approved-input provenance remains'
    $selectionWithExcludedIncompleteConflicts = Join-Path $scratch 'manifest3-selection-excluded-incomplete-conflicts.json'
    New-Manifest -Path $selectionWithExcludedIncompleteConflicts -Sources @(
        @{ id = 'design-md'; kind = 'derived'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'missing-design.md' },
        @{ id = 'tokens:color'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'tokens.color.json'; equivalentFor = @('design-md') },
        @{ id = 'guide:type-a'; kind = 'approved-guide'; scope = 'typography'; status = 'APPROVED'; value = 'sans'; digest = $brandGuideDigest },
        @{ id = 'guide:type-b'; kind = 'approved-guide'; scope = 'typography'; status = 'APPROVED'; digest = $brandGuideDigest }
    )
    $excludedIncompleteConflicts = Test-GuideFreshness -GuidePath $guide3Selection -ManifestPath $selectionWithExcludedIncompleteConflicts -RepoRoot $scratch
    Assert-Equal 'CURRENT' $excludedIncompleteConflicts.Overall 'Incomplete conflict metadata for not-applicable modules must not affect included modules'
    $guide3RuleScoped = Join-Path $scratch 'guide3-rule-scoped.md'
    New-Guide -Path $guide3RuleScoped -Rows @(
        @{ SourceId = 'design-md'; Revision = $tokenDigestV1; ApprovalState = 'DERIVED'; Scope = 'primary-principle' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('design-md'); Body = "`nRule-scoped provenance maps through its manifest module scope.`n" }
    )
    $ruleScopedManifest = Join-Path $scratch 'manifest3-rule-scoped.json'
    New-Manifest -Path $ruleScopedManifest -Sources @(
        @{ id = 'design-md'; kind = 'derived'; scope = 'visual-foundations'; rule = 'primary-principle'; status = 'DERIVED'; path = 'missing-design.md' },
        @{ id = 'tokens:color'; kind = 'token'; scope = 'visual-foundations'; rule = 'primary-principle'; status = 'DERIVED'; path = 'tokens.color.json'; equivalentFor = @('design-md') }
    )
    $ruleScoped = Test-GuideFreshness -GuidePath $guide3RuleScoped -ManifestPath $ruleScopedManifest -RepoRoot $scratch
    Assert-Equal 'CURRENT' $ruleScoped.Overall 'Rule-scoped provenance rows must resolve through a matching manifest source rule'
    $guide3WrongRuleScoped = Join-Path $scratch 'guide3-wrong-rule-scoped.md'
    New-Guide -Path $guide3WrongRuleScoped -Rows @(
        @{ SourceId = 'design-md'; Revision = $tokenDigestV1; ApprovalState = 'DERIVED'; Scope = 'wrong-rule' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('design-md'); Body = "`nRule-scoped provenance with a typo cannot be trusted.`n" }
    )
    $wrongRuleScoped = Test-GuideFreshness -GuidePath $guide3WrongRuleScoped -ManifestPath $ruleScopedManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $wrongRuleScoped.Overall 'Rule-scoped provenance rows must not report CURRENT unless the manifest source declares the recorded rule'
    $guide3WrongModuleSources = Join-Path $scratch 'guide3-wrong-module-sources.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3WrongModuleSources
    $wrongModuleSourcesText = (Get-Content -LiteralPath $guide3WrongModuleSources -Raw) -replace '\| visual-foundations \| included \| design-reviewer \| design-md \|  \|', '| visual-foundations | included | design-reviewer | wrong-source |  |'
    Set-Content -LiteralPath $guide3WrongModuleSources -Value $wrongModuleSourcesText -NoNewline
    $wrongModuleSources = Test-GuideFreshness -GuidePath $guide3WrongModuleSources -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $wrongModuleSources.Overall 'Module status approved source IDs must reconcile with approved-input rows and owned regions'
    $guide3BlankModuleSources = Join-Path $scratch 'guide3-blank-module-sources.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3BlankModuleSources
    $blankModuleSourcesText = (Get-Content -LiteralPath $guide3BlankModuleSources -Raw) -replace '\| visual-foundations \| included \| design-reviewer \| design-md \|  \|', '| visual-foundations | included | design-reviewer |  |  |'
    Set-Content -LiteralPath $guide3BlankModuleSources -Value $blankModuleSourcesText -NoNewline
    $blankModuleSources = Test-GuideFreshness -GuidePath $guide3BlankModuleSources -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $blankModuleSources.Overall 'Blank Module status approved source IDs must still reconcile with evidence sources'
    $guide3ExcludedProvenance = Join-Path $scratch 'guide3-excluded-provenance.md'
    New-Guide -Path $guide3ExcludedProvenance -Rows @(
        @{ SourceId = 'design-md'; Revision = $tokenDigestV1; ApprovalState = 'DERIVED'; Scope = 'visual-foundations' },
        @{ SourceId = 'tokens:type'; Revision = $brandGuideDigest; ApprovalState = 'DERIVED'; Scope = 'typography' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('design-md'); Body = "`nEquivalent evidence is already reflected in the owned artifact.`n" },
        @{ Id = 'typography'; Sources = @('tokens:type'); Body = "`nLegacy excluded module content must not participate.`n" }
    ) -ModuleStatuses @(
        @{ Module = 'orientation'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' },
        @{ Module = 'foundations'; Status = 'not applicable'; Owner = 'brand-identity'; Sources = ''; Missing = '' },
        @{ Module = 'identity-assets'; Status = 'not applicable'; Owner = 'brand-steward'; Sources = ''; Missing = '' },
        @{ Module = 'usage-constraints'; Status = 'not applicable'; Owner = 'logo-usage'; Sources = ''; Missing = '' },
        @{ Module = 'visual-foundations'; Status = 'included'; Owner = 'design-reviewer'; Sources = 'design-md'; Missing = '' },
        @{ Module = 'imagery-illustration'; Status = 'not applicable'; Owner = 'imagery-illustration'; Sources = ''; Missing = '' },
        @{ Module = 'typography'; Status = 'not applicable'; Owner = 'ux-writing'; Sources = 'tokens:type'; Missing = '' },
        @{ Module = 'voice-messaging'; Status = 'not applicable'; Owner = 'brand-voice-tone'; Sources = ''; Missing = '' },
        @{ Module = 'application-patterns'; Status = 'not applicable'; Owner = 'pattern-library'; Sources = ''; Missing = '' },
        @{ Module = 'resources-governance'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' }
    )
    $excludedProvenance = Test-GuideFreshness -GuidePath $guide3ExcludedProvenance -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $excludedProvenance.Overall 'Excluded canonical approved-input rows must remain visible as fail-closed diagnostics'
    Assert-Equal 'UNKNOWN' $excludedProvenance.Modules['typography'] 'Excluded canonical approved-input rows must surface the affected module for remediation'
    $guide3AlignedSeparators = Join-Path $scratch 'guide3-aligned-separators.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3AlignedSeparators
    $alignedSeparatorText = (Get-Content -LiteralPath $guide3AlignedSeparators -Raw).
        Replace('|---|---|---|---|', '| :--- | ---: | :---: | --- |').
        Replace('|---|---|---|---|---|', '| :--- | ---: | :---: | --- | :---: |')
    Set-Content -LiteralPath $guide3AlignedSeparators -Value $alignedSeparatorText -NoNewline
    $alignedSeparators = Test-GuideFreshness -GuidePath $guide3AlignedSeparators -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'CURRENT' $alignedSeparators.Overall 'Standard markdown-aligned separator rows must not be treated as malformed evidence'
    $guide3StatusPreamble = Join-Path $scratch 'guide3-status-preamble.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3StatusPreamble
    $statusPreambleText = (Get-Content -LiteralPath $guide3StatusPreamble -Raw).Replace('### Module status', "### Module status`n`nUse source IDs from Approved inputs | keep module evidence traceable.")
    Set-Content -LiteralPath $guide3StatusPreamble -Value $statusPreambleText -NoNewline
    $statusPreamble = Test-GuideFreshness -GuidePath $guide3StatusPreamble -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'CURRENT' $statusPreamble.Overall 'Pipe-bearing prose above the Module status table must not be treated as malformed table content'
    $guide3HeaderLikePreamble = Join-Path $scratch 'guide3-headerlike-preamble.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3HeaderLikePreamble
    $headerLikePreambleText = (Get-Content -LiteralPath $guide3HeaderLikePreamble -Raw).Replace('### Module status', "### Module status`n`nModule | status values are listed below.")
    Set-Content -LiteralPath $guide3HeaderLikePreamble -Value $headerLikePreambleText -NoNewline
    $headerLikePreamble = Test-GuideFreshness -GuidePath $guide3HeaderLikePreamble -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'CURRENT' $headerLikePreamble.Overall 'Header-like prose must not start Module status table parsing before the real markdown header row'
    $guide3MalformedHeader = Join-Path $scratch 'guide3-malformed-header.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3MalformedHeader
    $malformedHeaderText = (Get-Content -LiteralPath $guide3MalformedHeader -Raw).Replace('| Module | Status | Owner | Approved source IDs | Missing or proposed items |', '|| Module | Status | Owner | Approved source IDs | Missing or proposed items ||')
    Set-Content -LiteralPath $guide3MalformedHeader -Value $malformedHeaderText -NoNewline
    $malformedHeader = Test-GuideFreshness -GuidePath $guide3MalformedHeader -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $malformedHeader.Overall 'Malformed Module status header rows must fail closed instead of being skipped'
    $guide3BlankStatusRows = Join-Path $scratch 'guide3-blank-status-rows.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3BlankStatusRows
    $blankStatusRowsText = (Get-Content -LiteralPath $guide3BlankStatusRows -Raw).Replace("| foundations | not applicable | brand-identity |  | Not applicable for this fixture. |`n| identity-assets | not applicable | brand-steward |  | Not applicable for this fixture. |", "| foundations | not applicable | brand-identity |  | Not applicable for this fixture. |`n`n| identity-assets | not applicable | brand-steward |  | Not applicable for this fixture. |")
    Set-Content -LiteralPath $guide3BlankStatusRows -Value $blankStatusRowsText -NoNewline
    $blankStatusRows = Test-GuideFreshness -GuidePath $guide3BlankStatusRows -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'CURRENT' $blankStatusRows.Overall 'Blank lines inside the Module status table must not terminate parsing before later valid rows'
    $guide3NoncanonicalStatus = Join-Path $scratch 'guide3-noncanonical-status.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3NoncanonicalStatus
    $noncanonicalStatusText = (Get-Content -LiteralPath $guide3NoncanonicalStatus -Raw).Replace("| resources-governance | not applicable | design-reviewer |  | Not applicable for this fixture. |", "| resources-governance | not applicable | design-reviewer |  | Not applicable for this fixture. |`n| resource-governance | not applicable | design-reviewer |  | Not applicable for this fixture. |")
    Set-Content -LiteralPath $guide3NoncanonicalStatus -Value $noncanonicalStatusText -NoNewline
    $noncanonicalStatus = Test-GuideFreshness -GuidePath $guide3NoncanonicalStatus -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $noncanonicalStatus.Overall 'Non-canonical Module status rows must invalidate authoritative selection instead of being ignored'
    $guide3BlankNotApplicableRationale = Join-Path $scratch 'guide3-blank-not-applicable-rationale.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3BlankNotApplicableRationale
    $blankNotApplicableRationaleText = (Get-Content -LiteralPath $guide3BlankNotApplicableRationale -Raw).Replace('| foundations | not applicable | brand-identity |  | Not applicable for this fixture. |', '| foundations | not applicable | brand-identity |  |  |')
    Set-Content -LiteralPath $guide3BlankNotApplicableRationale -Value $blankNotApplicableRationaleText -NoNewline
    $blankNotApplicableRationale = Test-GuideFreshness -GuidePath $guide3BlankNotApplicableRationale -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $blankNotApplicableRationale.Overall 'Not-applicable Module status rows must include a nonempty rationale'
    $guide3RepeatedStatus = Join-Path $scratch 'guide3-repeated-status.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3RepeatedStatus
    Add-Content -LiteralPath $guide3RepeatedStatus -Value @"

### Module status

| Module | Status | Owner | Approved source IDs | Missing or proposed items |
|---|---|---|---|---|
| visual-foundations | awaiting input | design-reviewer | design-md | Conflicting duplicate section. |
"@
    $repeatedStatus = Test-GuideFreshness -GuidePath $guide3RepeatedStatus -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $repeatedStatus.Overall 'Repeated Module status sections must fail closed instead of silently ignoring later contradictory selections'
    $guide3MissingModuleStatus = Join-Path $scratch 'guide3-missing-module-status.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3MissingModuleStatus
    $missingModuleStatusText = (Get-Content -LiteralPath $guide3MissingModuleStatus -Raw) -replace '\| typography \| not applicable \| ux-writing \| tokens:type \| Not applicable for this fixture\. \|\r?\n', ''
    Set-Content -LiteralPath $guide3MissingModuleStatus -Value $missingModuleStatusText -NoNewline
    $missingModuleStatus = Test-GuideFreshness -GuidePath $guide3MissingModuleStatus -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $missingModuleStatus.Overall 'A present Module status table missing a canonical module must fail closed'
    Assert-Equal 'UNKNOWN' $missingModuleStatus.Modules['typography'] 'Missing canonical Module status rows must be keyed by the affected module for remediation'
    $guide3MissingIncluded = Join-Path $scratch 'guide3-missing-included.md'
    New-Guide -Path $guide3MissingIncluded -Rows @() -OwnedModules @() -ModuleStatuses @(
        @{ Module = 'orientation'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' },
        @{ Module = 'foundations'; Status = 'not applicable'; Owner = 'brand-identity'; Sources = ''; Missing = '' },
        @{ Module = 'identity-assets'; Status = 'not applicable'; Owner = 'brand-steward'; Sources = ''; Missing = '' },
        @{ Module = 'usage-constraints'; Status = 'not applicable'; Owner = 'logo-usage'; Sources = ''; Missing = '' },
        @{ Module = 'visual-foundations'; Status = 'awaiting input'; Owner = 'design-reviewer'; Sources = 'design-md'; Missing = '' },
        @{ Module = 'imagery-illustration'; Status = 'not applicable'; Owner = 'imagery-illustration'; Sources = ''; Missing = '' },
        @{ Module = 'typography'; Status = 'not applicable'; Owner = 'ux-writing'; Sources = ''; Missing = '' },
        @{ Module = 'voice-messaging'; Status = 'not applicable'; Owner = 'brand-voice-tone'; Sources = ''; Missing = '' },
        @{ Module = 'application-patterns'; Status = 'not applicable'; Owner = 'pattern-library'; Sources = ''; Missing = '' },
        @{ Module = 'resources-governance'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' }
    )
    $missingIncluded = Test-GuideFreshness -GuidePath $guide3MissingIncluded -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $missingIncluded.Overall 'An included module with no rows or owned region must report UNKNOWN without throwing'
    $guide3AwaitingInput = Join-Path $scratch 'guide3-awaiting-input.md'
    New-Guide -Path $guide3AwaitingInput -Rows @(
        @{ SourceId = 'design-md'; Revision = $tokenDigestV1; ApprovalState = 'DERIVED'; Scope = 'visual-foundations' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('design-md'); Body = "`nEquivalent evidence is already reflected in the owned artifact.`n" }
    ) -ModuleStatuses @(
        @{ Module = 'orientation'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' },
        @{ Module = 'foundations'; Status = 'not applicable'; Owner = 'brand-identity'; Sources = ''; Missing = '' },
        @{ Module = 'identity-assets'; Status = 'not applicable'; Owner = 'brand-steward'; Sources = ''; Missing = '' },
        @{ Module = 'usage-constraints'; Status = 'not applicable'; Owner = 'logo-usage'; Sources = ''; Missing = '' },
        @{ Module = 'visual-foundations'; Status = 'included'; Owner = 'design-reviewer'; Sources = 'design-md'; Missing = '' },
        @{ Module = 'imagery-illustration'; Status = 'not applicable'; Owner = 'imagery-illustration'; Sources = ''; Missing = '' },
        @{ Module = 'typography'; Status = 'awaiting input'; Owner = 'ux-writing'; Sources = ''; Missing = 'Provide approved typography source and generated section.' },
        @{ Module = 'voice-messaging'; Status = 'not applicable'; Owner = 'brand-voice-tone'; Sources = ''; Missing = '' },
        @{ Module = 'application-patterns'; Status = 'not applicable'; Owner = 'pattern-library'; Sources = ''; Missing = '' },
        @{ Module = 'resources-governance'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' }
    )
    $awaitingInput = Test-GuideFreshness -GuidePath $guide3AwaitingInput -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $awaitingInput.Overall 'An authoritative awaiting-input module must participate and keep freshness UNKNOWN until evidence exists'
    Assert-Equal 'UNKNOWN' $awaitingInput.Modules['typography'] 'An authoritative awaiting-input module must be enumerated for remediation'
    Assert-Equal 'Supply current authorized input and owned-artifact evidence.' $awaitingInput.Actions['typography'] 'Awaiting-input modules must surface remediation actions'
    $guide3AwaitingWithEvidence = Join-Path $scratch 'guide3-awaiting-with-evidence.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3AwaitingWithEvidence
    $awaitingWithEvidenceText = (Get-Content -LiteralPath $guide3AwaitingWithEvidence -Raw).Replace('| visual-foundations | included | design-reviewer | design-md |  |', '| visual-foundations | awaiting input | design-reviewer | design-md | Confirm final approval. |')
    Set-Content -LiteralPath $guide3AwaitingWithEvidence -Value $awaitingWithEvidenceText -NoNewline
    $awaitingWithEvidence = Test-GuideFreshness -GuidePath $guide3AwaitingWithEvidence -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $awaitingWithEvidence.Overall 'An awaiting-input module must not report CURRENT even when rows and owned evidence already match'
    Assert-Equal 'UNKNOWN' $awaitingWithEvidence.Modules['visual-foundations'] 'Awaiting-input status must preserve per-module remediation state until changed'
    Assert-Equal 'Supply current authorized input and owned-artifact evidence.' $awaitingWithEvidence.Actions['visual-foundations'] 'Awaiting-input status with evidence must not emit no-op remediation'
    $guide3InvalidStatus = Join-Path $scratch 'guide3-invalid-status.md'
    New-Guide -Path $guide3InvalidStatus -Rows @(
        @{ SourceId = 'design-md'; Revision = $tokenDigestV1; ApprovalState = 'DERIVED'; Scope = 'visual-foundations' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('design-md'); Body = "`nEquivalent evidence is already reflected in the owned artifact.`n" }
    ) -ModuleStatuses @(
        @{ Module = 'orientation'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' },
        @{ Module = 'foundations'; Status = 'not applicable'; Owner = 'brand-identity'; Sources = ''; Missing = '' },
        @{ Module = 'identity-assets'; Status = 'not applicable'; Owner = 'brand-steward'; Sources = ''; Missing = '' },
        @{ Module = 'usage-constraints'; Status = 'not applicable'; Owner = 'logo-usage'; Sources = ''; Missing = '' },
        @{ Module = 'visual-foundations'; Status = 'included'; Owner = 'design-reviewer'; Sources = 'design-md'; Missing = '' },
        @{ Module = 'imagery-illustration'; Status = 'not applicable'; Owner = 'imagery-illustration'; Sources = ''; Missing = '' },
        @{ Module = 'typography'; Status = 'awaitng input'; Owner = 'ux-writing'; Sources = ''; Missing = '' },
        @{ Module = 'voice-messaging'; Status = 'not applicable'; Owner = 'brand-voice-tone'; Sources = ''; Missing = '' },
        @{ Module = 'application-patterns'; Status = 'not applicable'; Owner = 'pattern-library'; Sources = ''; Missing = '' },
        @{ Module = 'resources-governance'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' }
    )
    $invalidStatus = Test-GuideFreshness -GuidePath $guide3InvalidStatus -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $invalidStatus.Modules['typography'] 'Invalid canonical module-status rows must be keyed by the affected module for remediation'
    $guide3DuplicateStatus = Join-Path $scratch 'guide3-duplicate-status.md'
    Copy-Item -LiteralPath $guide3InvalidStatus -Destination $guide3DuplicateStatus
    $duplicateText = (Get-Content -LiteralPath $guide3DuplicateStatus -Raw) -replace '\| typography \| awaitng input \| ux-writing \|  \|  \|', '| visual-foundations | included | design-reviewer | design-md |  |'
    Set-Content -LiteralPath $guide3DuplicateStatus -Value $duplicateText -NoNewline
    $duplicateStatus = Test-GuideFreshness -GuidePath $guide3DuplicateStatus -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'BLOCKED' $duplicateStatus.Modules['visual-foundations'] 'Duplicate module-status rows must block because module selection is ambiguous'
    $guide3ShiftedStatus = Join-Path $scratch 'guide3-shifted-status.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3ShiftedStatus
    $shiftedStatusText = (Get-Content -LiteralPath $guide3ShiftedStatus -Raw) -replace '\| visual-foundations \| included \| design-reviewer \| design-md \|  \|', 'visual-foundations | included | design-reviewer | design-md |  |'
    Set-Content -LiteralPath $guide3ShiftedStatus -Value $shiftedStatusText -NoNewline
    $shiftedStatus = Test-GuideFreshness -GuidePath $guide3ShiftedStatus -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $shiftedStatus.Overall 'Malformed module-status rows must fail closed instead of being silently skipped'
    Assert-True (($shiftedStatus.Reasons -join ' ') -match 'Module status row') 'Malformed module-status rows must preserve an explicit diagnostic'
    $guide3TruncatedStatus = Join-Path $scratch 'guide3-truncated-status.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3TruncatedStatus
    $truncatedStatusText = (Get-Content -LiteralPath $guide3TruncatedStatus -Raw) -replace '\| visual-foundations \| included \| design-reviewer \| design-md \|  \|', '| visual-foundations |'
    Set-Content -LiteralPath $guide3TruncatedStatus -Value $truncatedStatusText -NoNewline
    $truncatedStatus = Test-GuideFreshness -GuidePath $guide3TruncatedStatus -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $truncatedStatus.Overall 'Severely truncated module-status rows must degrade freshness instead of throwing'
    $guide3PipelessStatus = Join-Path $scratch 'guide3-pipeless-status.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3PipelessStatus
    $pipelessStatusText = (Get-Content -LiteralPath $guide3PipelessStatus -Raw) -replace '\| visual-foundations \| included \| design-reviewer \| design-md \|  \|', 'visual-foundations included design-reviewer design-md'
    Set-Content -LiteralPath $guide3PipelessStatus -Value $pipelessStatusText -NoNewline
    $pipelessStatus = Test-GuideFreshness -GuidePath $guide3PipelessStatus -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $pipelessStatus.Overall 'Pipe-less lines inside the Module status table must fail closed instead of being skipped'
    $guide3EdgePipeStatus = Join-Path $scratch 'guide3-edge-pipe-status.md'
    Copy-Item -LiteralPath $guide3Selection -Destination $guide3EdgePipeStatus
    $edgePipeStatusText = (Get-Content -LiteralPath $guide3EdgePipeStatus -Raw) -replace '\| visual-foundations \| included \| design-reviewer \| design-md \|  \|', '|| visual-foundations | included | design-reviewer | design-md ||'
    Set-Content -LiteralPath $guide3EdgePipeStatus -Value $edgePipeStatusText -NoNewline
    $edgePipeStatus = Test-GuideFreshness -GuidePath $guide3EdgePipeStatus -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $edgePipeStatus.Overall 'Module status rows with extra leading or trailing edge pipes must be treated as malformed evidence'
    $guide3ExcludedRegion = Join-Path $scratch 'guide3-excluded-region.md'
    New-Guide -Path $guide3ExcludedRegion -Rows @(
        @{ SourceId = 'design-md'; Revision = $tokenDigestV1; ApprovalState = 'DERIVED'; Scope = 'visual-foundations' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('design-md'); Body = "`nEquivalent evidence is already reflected in the owned artifact.`n" },
        @{ Id = 'typography'; Sources = @('tokens:type'); Body = '' }
    ) -ModuleStatuses @(
        @{ Module = 'orientation'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' },
        @{ Module = 'foundations'; Status = 'not applicable'; Owner = 'brand-identity'; Sources = ''; Missing = '' },
        @{ Module = 'identity-assets'; Status = 'not applicable'; Owner = 'brand-steward'; Sources = ''; Missing = '' },
        @{ Module = 'usage-constraints'; Status = 'not applicable'; Owner = 'logo-usage'; Sources = ''; Missing = '' },
        @{ Module = 'visual-foundations'; Status = 'included'; Owner = 'design-reviewer'; Sources = 'design-md'; Missing = '' },
        @{ Module = 'imagery-illustration'; Status = 'not applicable'; Owner = 'imagery-illustration'; Sources = ''; Missing = '' },
        @{ Module = 'typography'; Status = 'not applicable'; Owner = 'ux-writing'; Sources = 'tokens:type'; Missing = '' },
        @{ Module = 'voice-messaging'; Status = 'not applicable'; Owner = 'brand-voice-tone'; Sources = ''; Missing = '' },
        @{ Module = 'application-patterns'; Status = 'not applicable'; Owner = 'pattern-library'; Sources = ''; Missing = '' },
        @{ Module = 'resources-governance'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' }
    )
    $excludedText = Get-Content -LiteralPath $guide3ExcludedRegion -Raw
    $excludedRegion = Get-OwnedRegions -GuideText $excludedText | Where-Object { $_.Id -eq 'typography' }
    $tamperedText = $excludedText.Replace($excludedRegion.FullMatch, $excludedRegion.FullMatch.Replace('revision="', 'revision="sha256:0000'))
    Set-Content -LiteralPath $guide3ExcludedRegion -Value $tamperedText -NoNewline
    $excludedRegionResult = Test-GuideFreshness -GuidePath $guide3ExcludedRegion -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'CURRENT' $excludedRegionResult.Overall 'Excluded canonical owned regions must not participate after global boundary validation'
    Assert-True ('typography' -notin @($excludedRegionResult.Modules.Keys)) 'Excluded canonical owned regions must not create module state entries'
    $guide3EmptyOwned = Join-Path $scratch 'guide3-empty-owned.md'
    New-Guide -Path $guide3EmptyOwned -Rows @(
        @{ SourceId = 'design-md'; Revision = $tokenDigestV1; ApprovalState = 'DERIVED'; Scope = 'visual-foundations' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('design-md'); Body = '' }
    ) -ModuleStatuses @(
        @{ Module = 'orientation'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' },
        @{ Module = 'foundations'; Status = 'not applicable'; Owner = 'brand-identity'; Sources = ''; Missing = '' },
        @{ Module = 'identity-assets'; Status = 'not applicable'; Owner = 'brand-steward'; Sources = ''; Missing = '' },
        @{ Module = 'usage-constraints'; Status = 'not applicable'; Owner = 'logo-usage'; Sources = ''; Missing = '' },
        @{ Module = 'visual-foundations'; Status = 'included'; Owner = 'design-reviewer'; Sources = 'design-md'; Missing = '' },
        @{ Module = 'imagery-illustration'; Status = 'not applicable'; Owner = 'imagery-illustration'; Sources = ''; Missing = '' },
        @{ Module = 'typography'; Status = 'not applicable'; Owner = 'ux-writing'; Sources = ''; Missing = '' },
        @{ Module = 'voice-messaging'; Status = 'not applicable'; Owner = 'brand-voice-tone'; Sources = ''; Missing = '' },
        @{ Module = 'application-patterns'; Status = 'not applicable'; Owner = 'pattern-library'; Sources = ''; Missing = '' },
        @{ Module = 'resources-governance'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' }
    )
    $emptyOwned = Test-GuideFreshness -GuidePath $guide3EmptyOwned -ManifestPath $selectionManifest -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $emptyOwned.Overall 'An empty included owned region must fail closed for the affected module instead of aborting assessment'
    Assert-Equal 'UNKNOWN' $emptyOwned.Modules['visual-foundations'] 'An empty included owned region must mark the affected module UNKNOWN'

    # === Scenario 4: unchanged refresh is a true no-op ==========================
    Write-Host '[4/12] unchanged refresh -> byte-identical, timestamp-preserving no-op'
    $manifest4 = Join-Path $scratch 'manifest4.json'
    New-Manifest -Path $manifest4 -Sources @(
        @{ id = 'tokens:color'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'tokens.color.json' }
    )
    $guide4 = Join-Path $scratch 'guide4.md'
    New-Guide -Path $guide4 -Rows @(
        @{ SourceId = 'tokens:color'; Revision = $tokenDigestV1; ApprovalState = 'DERIVED'; Scope = 'visual-foundations' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('tokens:color'); Body = "`nPrimary role maps to tokens:color.`n" }
    )
    $beforeHash = (Get-FileHash -LiteralPath $guide4 -Algorithm SHA256).Hash
    $beforeTime = (Get-Item -LiteralPath $guide4).LastWriteTimeUtc
    Start-Sleep -Milliseconds 50
    $refresh4 = Invoke-GuideRefresh -GuidePath $guide4 -ManifestPath $manifest4 -RepoRoot $scratch -Apply
    Assert-Equal 'NO_OP' $refresh4.Result 'Fully current guide must refresh as a no-op'
    Assert-Equal $false $refresh4.Wrote 'No-op refresh must not write'
    $afterHash = (Get-FileHash -LiteralPath $guide4 -Algorithm SHA256).Hash
    $afterTime = (Get-Item -LiteralPath $guide4).LastWriteTimeUtc
    Assert-Equal $beforeHash $afterHash 'No-op refresh must leave the guide byte-identical'
    Assert-Equal $beforeTime $afterTime 'No-op refresh must not touch the file timestamp'
    $manifest4PartialCoverage = Join-Path $scratch 'manifest4-partial-coverage.json'
    New-Manifest -Path $manifest4PartialCoverage -Sources @(
        @{ id = 'tokens:color'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'tokens.color.json' },
        @{ id = 'tokens:spacing'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; digest = $brandGuideDigest }
    )
    $guide4PartialCoverage = Join-Path $scratch 'guide4-partial-coverage.md'
    New-Guide -Path $guide4PartialCoverage -Rows @(
        @{ SourceId = 'tokens:color'; Revision = $tokenDigestV1; ApprovalState = 'DERIVED'; Scope = 'visual-foundations' },
        @{ SourceId = 'tokens:spacing'; Revision = $brandGuideDigest; ApprovalState = 'DERIVED'; Scope = 'visual-foundations' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('tokens:color'); Body = "`nOnly one provenance row is mapped by this owned region.`n" }
    )
    $partialCoverage = Test-GuideFreshness -GuidePath $guide4PartialCoverage -ManifestPath $manifest4PartialCoverage -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $partialCoverage.Overall 'Every module provenance row source must be mapped by its owned region'
    $guide4MalformedRow = Join-Path $scratch 'guide4-malformed-row.md'
    Copy-Item -LiteralPath $guide4 -Destination $guide4MalformedRow
    $malformedRowText = (Get-Content -LiteralPath $guide4MalformedRow -Raw) -replace '(\|---\|---\|---\|---\|\r?\n)', "`$1| tokens:spacing | $brandGuideDigest | DERIVED | visual-foundations | unexpected |`n"
    Set-Content -LiteralPath $guide4MalformedRow -Value $malformedRowText -NoNewline
    $malformedRow = Test-GuideFreshness -GuidePath $guide4MalformedRow -ManifestPath $manifest4PartialCoverage -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $malformedRow.Overall 'Malformed approved-input rows must fail closed instead of being silently ignored'
    $guide4EdgePipeRow = Join-Path $scratch 'guide4-edge-pipe-row.md'
    Copy-Item -LiteralPath $guide4 -Destination $guide4EdgePipeRow
    $edgePipeRowText = (Get-Content -LiteralPath $guide4EdgePipeRow -Raw) -replace '(\|---\|---\|---\|---\|\r?\n)', "`$1|| tokens:spacing | $brandGuideDigest | DERIVED | visual-foundations |`n"
    Set-Content -LiteralPath $guide4EdgePipeRow -Value $edgePipeRowText -NoNewline
    $edgePipeRow = Test-GuideFreshness -GuidePath $guide4EdgePipeRow -ManifestPath $manifest4PartialCoverage -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $edgePipeRow.Overall 'Approved-input rows with extra leading or trailing edge pipes must be treated as malformed evidence'
    $guide4PipelessRow = Join-Path $scratch 'guide4-pipeless-row.md'
    Copy-Item -LiteralPath $guide4 -Destination $guide4PipelessRow
    $pipelessRowText = (Get-Content -LiteralPath $guide4PipelessRow -Raw) -replace '(\|---\|---\|---\|---\|\r?\n)', "`$1tokens:spacing | $brandGuideDigest | DERIVED | visual-foundations`n"
    Set-Content -LiteralPath $guide4PipelessRow -Value $pipelessRowText -NoNewline
    $pipelessRow = Test-GuideFreshness -GuidePath $guide4PipelessRow -ManifestPath $manifest4PartialCoverage -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $pipelessRow.Overall 'Pipe-less lines inside the Approved inputs table must fail closed instead of being skipped'
    $guide4BadApprovedHeader = Join-Path $scratch 'guide4-bad-approved-header.md'
    Copy-Item -LiteralPath $guide4 -Destination $guide4BadApprovedHeader
    $badApprovedHeaderText = (Get-Content -LiteralPath $guide4BadApprovedHeader -Raw) -replace '\| Source ID \| Revision or digest \| Approval state \| Supported module or rule \|', '| Source | Revision or digest | Approval state | Supported module or rule |'
    Set-Content -LiteralPath $guide4BadApprovedHeader -Value $badApprovedHeaderText -NoNewline
    $badApprovedHeader = Test-GuideFreshness -GuidePath $guide4BadApprovedHeader -ManifestPath $manifest4 -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $badApprovedHeader.Overall 'Approved inputs tables must include the exact header contract before rows can count as evidence'
    $guide4BadApprovedSeparator = Join-Path $scratch 'guide4-bad-approved-separator.md'
    Copy-Item -LiteralPath $guide4 -Destination $guide4BadApprovedSeparator
    $badApprovedSeparatorText = (Get-Content -LiteralPath $guide4BadApprovedSeparator -Raw) -replace '\|---\|---\|---\|---\|', '|---|---|---|'
    Set-Content -LiteralPath $guide4BadApprovedSeparator -Value $badApprovedSeparatorText -NoNewline
    $badApprovedSeparator = Test-GuideFreshness -GuidePath $guide4BadApprovedSeparator -ManifestPath $manifest4 -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $badApprovedSeparator.Overall 'Approved inputs tables must include a valid four-column Markdown separator'
    $guide4BlankRevision = Join-Path $scratch 'guide4-blank-revision.md'
    New-Guide -Path $guide4BlankRevision -Rows @(
        @{ SourceId = 'tokens:color'; Revision = ''; ApprovalState = 'DERIVED'; Scope = 'visual-foundations' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('tokens:color'); Body = "`nPrimary role maps to tokens:color.`n" }
    )
    $blankRevision = Test-GuideFreshness -GuidePath $guide4BlankRevision -ManifestPath $manifest4 -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $blankRevision.Overall 'Approved-input rows with missing revision evidence must be UNKNOWN, not STALE'
    $guide4BadOwnedDigest = Join-Path $scratch 'guide4-bad-owned-digest.md'
    Copy-Item -LiteralPath $guide4 -Destination $guide4BadOwnedDigest
    $badOwnedDigestText = (Get-Content -LiteralPath $guide4BadOwnedDigest -Raw) -replace 'revision="sha256:[a-f0-9]{64}"', 'revision=""'
    Set-Content -LiteralPath $guide4BadOwnedDigest -Value $badOwnedDigestText -NoNewline
    $badOwnedDigest = Test-GuideFreshness -GuidePath $guide4BadOwnedDigest -ManifestPath $manifest4 -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $badOwnedDigest.Overall 'Owned regions with missing recorded digest evidence must be UNKNOWN, not STALE'

    # === Scenario 5: stale refresh is fail-closed and read-only =================
    Write-Host '[5/12] stale refresh stays PARTIAL and does not rewrite the guide'
    $manifest5 = Join-Path $scratch 'manifest5.json'
    New-Manifest -Path $manifest5 -Sources @(
        @{ id = 'tokens:color'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'tokens.color.json'; guideContent = 'Primary role now maps to the refreshed tokens:color evidence.' },
        @{ id = 'guide:brand-a'; kind = 'approved-guide'; scope = 'foundations'; status = 'APPROVED'; digest = $brandGuideDigest }
    )
    $guide5 = Join-Path $scratch 'guide5.md'
    $consumerNote = "`n## Consumer notes`n`nOur design team added this manually and it must survive refresh untouched.`n"
    $visualBody = "`nPrimary role maps to tokens:color. This prose sentence must never be rewritten by refresh.`n"
    $foundationsBody = "`nFoundations text unaffected by the token change.`n"
    New-Guide -Path $guide5 -Rows @(
        @{ SourceId = 'tokens:color'; Revision = $tokenDigestV1; ApprovalState = 'DERIVED'; Scope = 'visual-foundations' },
        @{ SourceId = 'guide:brand-a'; Revision = $brandGuideDigest; ApprovalState = 'APPROVED'; Scope = 'foundations' }
    ) -OwnedModules @(
        @{ Id = 'visual-foundations'; Sources = @('tokens:color'); Body = $visualBody },
        @{ Id = 'foundations'; Sources = @('guide:brand-a'); Body = $foundationsBody }
    ) -ConsumerNote $consumerNote
    $before5 = Get-Content -LiteralPath $guide5 -Raw
    $before5Hash = (Get-FileHash -LiteralPath $guide5 -Algorithm SHA256).Hash
    $before5Time = (Get-Item -LiteralPath $guide5).LastWriteTimeUtc
    $foundationsRegionBefore = (Get-OwnedRegions -GuideText $before5 | Where-Object { $_.Id -eq 'foundations' }).FullMatch
    $visualRegionBefore = (Get-OwnedRegions -GuideText $before5 | Where-Object { $_.Id -eq 'visual-foundations' }).FullMatch
    # Mutate the token source so only visual-foundations goes STALE.
    Set-Content -LiteralPath $tokensPath -Value '{"$type":"color","primary":"#abcdef"}' -NoNewline
    Start-Sleep -Milliseconds 50
    $refresh5 = Invoke-GuideRefresh -GuidePath $guide5 -ManifestPath $manifest5 -RepoRoot $scratch -Apply
    Assert-Equal 'PARTIAL' $refresh5.Result 'A stale guide must remain PARTIAL even when guideContent exists'
    Assert-Equal $false $refresh5.Wrote 'Fail-closed refresh must not write stale guide content or provenance'
    Assert-Equal 0 @($refresh5.UpdatedModules).Count 'Fail-closed refresh must not report updated modules'
    $after5 = Get-Content -LiteralPath $guide5 -Raw
    $after5Hash = (Get-FileHash -LiteralPath $guide5 -Algorithm SHA256).Hash
    $after5Time = (Get-Item -LiteralPath $guide5).LastWriteTimeUtc
    Assert-Equal $before5Hash $after5Hash 'Fail-closed refresh must leave the guide byte-identical'
    Assert-Equal $before5Time $after5Time 'Fail-closed refresh must not touch the guide timestamp'
    Assert-True ($after5.Contains($consumerNote.Trim())) 'Consumer-authored content outside owned markers must be preserved verbatim'
    $foundationsRegionAfter = (Get-OwnedRegions -GuideText $after5 | Where-Object { $_.Id -eq 'foundations' }).FullMatch
    Assert-Equal $foundationsRegionBefore $foundationsRegionAfter 'Unaffected owned module (stable ID + content) must be byte-identical after refresh'
    $visualRegionAfter = (Get-OwnedRegions -GuideText $after5 | Where-Object { $_.Id -eq 'visual-foundations' }).FullMatch
    Assert-Equal $visualRegionBefore $visualRegionAfter 'Fail-closed refresh must not rewrite the stale owned region'
    $rowsAfter5 = Get-ApprovedInputRows -GuideText $after5
    $tokenRowAfter = $rowsAfter5 | Where-Object { $_.SourceId -eq 'tokens:color' }
    Assert-Equal $tokenDigestV1 $tokenRowAfter.Revision 'Fail-closed refresh must not advance provenance for a stale guide'
    Assert-True ($null -ne $refresh5.PostAssessment) 'Invoke-GuideRefresh must return a post-refresh assessment'
    Assert-Equal 'STALE' $refresh5.PostAssessment.Overall 'Fail-closed refresh must preserve the stale assessment'
    $reassessed5 = Test-GuideFreshness -GuidePath $guide5 -ManifestPath $manifest5 -RepoRoot $scratch
    Assert-Equal 'STALE' $reassessed5.Overall 'An independent reassessment must confirm the guide remains STALE after a fail-closed refresh'
    # restore token fixture
    Set-Content -LiteralPath $tokensPath -Value '{"$type":"color","primary":"#123456"}' -NoNewline

    # === Scenario 6: Check mode is genuinely read-only ==========================
    Write-Host '[6/12] check mode is genuinely read-only'
    $allFiles = Get-ChildItem -LiteralPath $scratch -Recurse -File
    $before = @{}
    foreach ($f in $allFiles) { $before[$f.FullName] = @{ Hash = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash; Time = $f.LastWriteTimeUtc } }
    Start-Sleep -Milliseconds 50
    1..3 | ForEach-Object { [void](Test-GuideFreshness -GuidePath $guide5 -ManifestPath $manifest5 -RepoRoot $scratch) }
    $afterFiles = Get-ChildItem -LiteralPath $scratch -Recurse -File
    Assert-Equal $allFiles.Count $afterFiles.Count 'Check mode must not create or delete any file'
    foreach ($f in $afterFiles) {
        $prior = $before[$f.FullName]
        Assert-True ($null -ne $prior) "Unexpected new file after check: $($f.FullName)"
        Assert-Equal $prior.Hash (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash "Check mode wrote to $($f.FullName)"
        Assert-Equal $prior.Time $f.LastWriteTimeUtc "Check mode touched the timestamp of $($f.FullName)"
    }

    # === Scenario 7: manifest structural validation =============================
    Write-Host '[7/12] manifest record validation rejects malformed records'
    $badManifestDir = Join-Path $scratch 'bad-manifests'
    New-Item -ItemType Directory -Path $badManifestDir -Force | Out-Null

    $dupId = Join-Path $badManifestDir 'dup-id.json'
    New-Manifest -Path $dupId -Sources @(
        @{ id = 'x'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; digest = $brandGuideDigest },
        @{ id = 'x'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; digest = $brandGuideDigest }
    )
    Assert-Throws { Read-InputsManifest -ManifestPath $dupId -RepoRoot $scratch } 'Duplicate manifest source IDs must be rejected, not silently overwritten' 'duplicated'
    $guide7DupId = Join-Path $scratch 'guide7-dup-id.md'
    New-Guide -Path $guide7DupId -Rows @(@{ SourceId = 'x'; Revision = $brandGuideDigest; ApprovalState = 'DERIVED'; Scope = 'typography' }) -OwnedModules @(
        @{ Id = 'typography'; Sources = @('x'); Body = "`nTypography evidence with duplicate source identity.`n" }
    )
    $dupIdFreshness = Test-GuideFreshness -GuidePath $guide7DupId -ManifestPath $dupId -RepoRoot $scratch
    Assert-Equal 'BLOCKED' $dupIdFreshness.Overall 'Duplicate manifest source IDs must block freshness rather than selecting the first definition'

    $badKind = Join-Path $badManifestDir 'bad-kind.json'
    New-Manifest -Path $badKind -Sources @(@{ id = 'x'; kind = 'not-a-real-kind'; scope = 'typography'; status = 'DERIVED'; digest = $brandGuideDigest })
    Assert-Throws { Read-InputsManifest -ManifestPath $badKind -RepoRoot $scratch } 'Unrecognized kind must be rejected' 'unrecognized kind'

    $badStatus = Join-Path $badManifestDir 'bad-status.json'
    New-Manifest -Path $badStatus -Sources @(@{ id = 'x'; kind = 'token'; scope = 'typography'; status = 'TEMPLATE'; digest = $brandGuideDigest })
    Assert-Throws { Read-InputsManifest -ManifestPath $badStatus -RepoRoot $scratch } "Status not permitted for kind ('TEMPLATE' is not valid for 'token') must be rejected" 'not permitted'

    $badScope = Join-Path $badManifestDir 'bad-scope.json'
    New-Manifest -Path $badScope -Sources @(@{ id = 'x'; kind = 'token'; scope = 'not-a-module'; status = 'DERIVED'; digest = $brandGuideDigest })
    Assert-Throws { Read-InputsManifest -ManifestPath $badScope -RepoRoot $scratch } 'Scope outside the ten canonical module IDs must be rejected' 'canonical module IDs'

    $missingScope = Join-Path $badManifestDir 'missing-scope.json'
    New-Manifest -Path $missingScope -Sources @(@{ id = 'x'; kind = 'token'; status = 'DERIVED'; digest = $brandGuideDigest })
    Assert-Throws { Read-InputsManifest -ManifestPath $missingScope -RepoRoot $scratch } 'A scope-requiring kind without a scope must be rejected' 'requires a'

    $badRule = Join-Path $badManifestDir 'bad-rule.json'
    New-Manifest -Path $badRule -Sources @(@{ id = 'x'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; digest = $brandGuideDigest; rule = @('not', 'a', 'string') })
    Assert-Throws { Read-InputsManifest -ManifestPath $badRule -RepoRoot $scratch } 'A non-string rule must be rejected' 'non-string'

    $badValue = Join-Path $badManifestDir 'bad-value.json'
    New-Manifest -Path $badValue -Sources @(@{ id = 'x'; kind = 'approved-guide'; scope = 'typography'; status = 'APPROVED'; digest = $brandGuideDigest; value = @{ nested = $true } })
    Assert-Throws { Read-InputsManifest -ManifestPath $badValue -RepoRoot $scratch } 'A non-scalar value must be rejected' 'non-scalar'

    $badDigest = Join-Path $badManifestDir 'bad-digest.json'
    New-Manifest -Path $badDigest -Sources @(@{ id = 'x'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; digest = @($brandGuideDigest) })
    Assert-Throws { Read-InputsManifest -ManifestPath $badDigest -RepoRoot $scratch } 'A non-string digest must be rejected before it can satisfy provenance' 'digest'

    $badDigestEmpty = Join-Path $badManifestDir 'bad-digest-empty.json'
    New-Manifest -Path $badDigestEmpty -Sources @(@{ id = 'x'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; digest = '   ' })
    Assert-Throws { Read-InputsManifest -ManifestPath $badDigestEmpty -RepoRoot $scratch } 'A blank digest must be rejected before it can satisfy provenance' "invalid 'digest'"

    $selfEquivalent = Join-Path $badManifestDir 'self-equivalent.json'
    New-Manifest -Path $selfEquivalent -Sources @(@{ id = 'x'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; digest = $brandGuideDigest; equivalentFor = @('x') })
    Assert-Throws { Read-InputsManifest -ManifestPath $selfEquivalent -RepoRoot $scratch } 'A source cannot declare itself as its own equivalent' 'cannot declare itself'

    $dupEquivalent = Join-Path $badManifestDir 'dup-equivalent.json'
    New-Manifest -Path $dupEquivalent -Sources @(@{ id = 'x'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; digest = $brandGuideDigest; equivalentFor = @('design-md', 'design-md') })
    Assert-Throws { Read-InputsManifest -ManifestPath $dupEquivalent -RepoRoot $scratch } 'Duplicate equivalentFor entries must be rejected' 'duplicate'

    $badId = Join-Path $badManifestDir 'bad-id.json'
    New-Manifest -Path $badId -Sources @(@{ id = 'bad|id'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; digest = $brandGuideDigest })
    Assert-Throws { Read-InputsManifest -ManifestPath $badId -RepoRoot $scratch } 'Manifest source IDs must be delimiter-safe for table cells and ownership markers' "invalid 'id'"

    $badIdNewline = Join-Path $badManifestDir 'bad-id-newline.json'
    New-Manifest -Path $badIdNewline -Sources @(@{ id = "safe-id`n"; kind = 'token'; scope = 'typography'; status = 'DERIVED'; digest = $brandGuideDigest })
    Assert-Throws { Read-InputsManifest -ManifestPath $badIdNewline -RepoRoot $scratch } 'Manifest source IDs with trailing newlines must be rejected by the absolute regex anchor' "invalid 'id'"

    $badEquivalentId = Join-Path $badManifestDir 'bad-equivalent-id.json'
    New-Manifest -Path $badEquivalentId -Sources @(@{ id = 'x'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; digest = $brandGuideDigest; equivalentFor = @('bad,entry') })
    Assert-Throws { Read-InputsManifest -ManifestPath $badEquivalentId -RepoRoot $scratch } 'equivalentFor IDs must use the same delimiter-safe grammar as source IDs' "invalid 'equivalentFor'"

    $badEquivalentIdNewline = Join-Path $badManifestDir 'bad-equivalent-id-newline.json'
    New-Manifest -Path $badEquivalentIdNewline -Sources @(@{ id = 'x'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; digest = $brandGuideDigest; equivalentFor = @("safe-id`n") })
    Assert-Throws { Read-InputsManifest -ManifestPath $badEquivalentIdNewline -RepoRoot $scratch } 'equivalentFor IDs with trailing newlines must be rejected by the absolute regex anchor' "invalid 'equivalentFor'"

    # A well-formed manifest with every field must still parse cleanly (no false-positive rejection).
    $goodManifest = Join-Path $badManifestDir 'good.json'
    New-Manifest -Path $goodManifest -Sources @(@{ id = 'x'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; digest = $brandGuideDigest; rule = 'role-mapping'; value = 'sans-serif'; equivalentFor = @('design-md') })
    $goodSources = Read-InputsManifest -ManifestPath $goodManifest -RepoRoot $scratch
    Assert-Equal 1 $goodSources.Count 'A fully valid manifest record must parse without error'

    # === Scenario 8: missing/inaccessible source path -> UNKNOWN, not abort ====
    Write-Host '[8/12] missing source file degrades only the affected module to UNKNOWN'
    $manifest8 = Join-Path $scratch 'manifest8.json'
    New-Manifest -Path $manifest8 -Sources @(@{ id = 'tokens:missing'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; path = 'does-not-exist.json' })
    $guide8 = Join-Path $scratch 'guide8.md'
    New-Guide -Path $guide8 -Rows @(@{ SourceId = 'tokens:missing'; Revision = 'sha256:' + ('0' * 64); ApprovalState = 'DERIVED'; Scope = 'typography' }) -OwnedModules @()
    $r8 = Test-GuideFreshness -GuidePath $guide8 -ManifestPath $manifest8 -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $r8.Overall 'A missing manifest source file must degrade its module to UNKNOWN, not throw/abort'
    Assert-Equal 'UNKNOWN' $r8.Modules['typography'] 'The affected module specifically must be UNKNOWN'
    Assert-True (($r8.Reasons -join ' ') -match 'unavailable') 'An explicit diagnostic reason must be preserved for the unavailable source'
    Assert-True ($r8.Actions['typography'] -match 'Supply current authorized input') 'UNKNOWN modules must include a remediation action'
    $manifest8Unavailable = Join-Path $scratch 'manifest8-unavailable.json'
    $unavailableManifest = Test-GuideFreshness -GuidePath $guide8 -ManifestPath $manifest8Unavailable -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $unavailableManifest.Overall 'A missing current-inputs manifest must return structured UNKNOWN assessment instead of throwing'
    Assert-Equal 'UNKNOWN' $unavailableManifest.Modules['typography'] 'A missing manifest must derive affected modules from guide provenance rows'
    Assert-True (($unavailableManifest.Reasons -join ' ') -match 'manifest is unavailable') 'A missing manifest must preserve an explicit diagnostic reason'
    $manifest8MixedMalformed = Join-Path $scratch 'manifest8-mixed-malformed.json'
    New-Manifest -Path $manifest8MixedMalformed -Sources @(
        @{ id = 'guide:brand-a'; kind = 'approved-guide'; scope = 'foundations'; status = 'APPROVED'; digest = $brandGuideDigest },
        @{ id = 'tokens:type-bad'; kind = 'not-a-real-kind'; scope = 'typography'; status = 'DERIVED'; digest = $brandGuideDigest },
        @{ id = 'tokens:unscoped-bad'; kind = 'token'; status = 'DERIVED'; digest = $brandGuideDigest }
    )
    $guide8MixedMalformed = Join-Path $scratch 'guide8-mixed-malformed.md'
    New-Guide -Path $guide8MixedMalformed -Rows @(
        @{ SourceId = 'guide:brand-a'; Revision = $brandGuideDigest; ApprovalState = 'APPROVED'; Scope = 'foundations' }
    ) -OwnedModules @(
        @{ Id = 'foundations'; Sources = @('guide:brand-a'); Body = "`nFoundations evidence remains valid despite an excluded malformed typography source.`n" }
    ) -ModuleStatuses @(
        @{ Module = 'orientation'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' },
        @{ Module = 'foundations'; Status = 'included'; Owner = 'brand-identity'; Sources = 'guide:brand-a'; Missing = '' },
        @{ Module = 'identity-assets'; Status = 'not applicable'; Owner = 'brand-steward'; Sources = ''; Missing = '' },
        @{ Module = 'usage-constraints'; Status = 'not applicable'; Owner = 'logo-usage'; Sources = ''; Missing = '' },
        @{ Module = 'visual-foundations'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' },
        @{ Module = 'imagery-illustration'; Status = 'not applicable'; Owner = 'imagery-illustration'; Sources = ''; Missing = '' },
        @{ Module = 'typography'; Status = 'not applicable'; Owner = 'ux-writing'; Sources = ''; Missing = '' },
        @{ Module = 'voice-messaging'; Status = 'not applicable'; Owner = 'brand-voice-tone'; Sources = ''; Missing = '' },
        @{ Module = 'application-patterns'; Status = 'not applicable'; Owner = 'pattern-library'; Sources = ''; Missing = '' },
        @{ Module = 'resources-governance'; Status = 'not applicable'; Owner = 'design-reviewer'; Sources = ''; Missing = '' }
    )
    $mixedMalformed = Test-GuideFreshness -GuidePath $guide8MixedMalformed -ManifestPath $manifest8MixedMalformed -RepoRoot $scratch
    Assert-Equal 'CURRENT' $mixedMalformed.Overall 'A malformed source record for a not-applicable module must not invalidate an otherwise current included module'
    $guide8MixedMalformedFallback = Join-Path $scratch 'guide8-mixed-malformed-fallback.md'
    New-Guide -Path $guide8MixedMalformedFallback -Rows @(
        @{ SourceId = 'guide:brand-a'; Revision = $brandGuideDigest; ApprovalState = 'APPROVED'; Scope = 'foundations' }
    ) -OwnedModules @(
        @{ Id = 'foundations'; Sources = @('guide:brand-a'); Body = "`nFallback foundations evidence remains valid despite unused malformed typography source.`n" }
    )
    $mixedMalformedFallback = Test-GuideFreshness -GuidePath $guide8MixedMalformedFallback -ManifestPath $manifest8MixedMalformed -RepoRoot $scratch
    Assert-Equal 'CURRENT' $mixedMalformedFallback.Overall 'Fallback freshness must ignore malformed manifest records not referenced by Approved inputs or owned regions'
    if (-not $IsWindows) {
        $deniedPath = Join-Path $scratch 'denied.json'
        Set-Content -LiteralPath $deniedPath -Value '{"$type":"color","primary":"#111111"}' -NoNewline
        chmod 000 $deniedPath
        try {
            $manifest8Denied = Join-Path $scratch 'manifest8-denied.json'
            New-Manifest -Path $manifest8Denied -Sources @(@{ id = 'tokens:denied'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; path = 'denied.json' })
            $sources8Denied = Read-InputsManifest -ManifestPath $manifest8Denied -RepoRoot $scratch
            Assert-True (-not $sources8Denied['tokens:denied'].available) 'An unreadable source must degrade to unavailable rather than aborting the manifest load'
            Assert-True ($sources8Denied['tokens:denied'].unavailableReason -match 'inaccessible') 'Unreadable sources must preserve an inaccessible-path diagnostic'
        } finally {
            chmod 600 $deniedPath
        }
    } else {
        $deniedPath = Join-Path $scratch 'denied.json'
        Set-Content -LiteralPath $deniedPath -Value '{"$type":"color","primary":"#111111"}' -NoNewline
        $principal = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        try {
            & icacls $deniedPath /inheritance:r /deny "${principal}:(R)" | Out-Null
            $manifest8Denied = Join-Path $scratch 'manifest8-denied.json'
            New-Manifest -Path $manifest8Denied -Sources @(@{ id = 'tokens:denied'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; path = 'denied.json' })
            $sources8Denied = Read-InputsManifest -ManifestPath $manifest8Denied -RepoRoot $scratch
            Assert-True (-not $sources8Denied['tokens:denied'].available) 'An unreadable source must degrade to unavailable rather than aborting the manifest load'
            Assert-True ($sources8Denied['tokens:denied'].unavailableReason -match 'inaccessible') 'Unreadable sources must preserve an inaccessible-path diagnostic'
        } finally {
            & icacls $deniedPath /remove:d $principal /grant:r "${principal}:(F)" | Out-Null
        }
    }
    $refresh8 = Invoke-GuideRefresh -GuidePath $guide8 -ManifestPath $manifest8 -RepoRoot $scratch -Apply
    Assert-Equal 'PARTIAL' $refresh8.Result 'An UNKNOWN module must not be mislabeled as a successful no-op refresh'
    Assert-Equal $false $refresh8.Wrote 'An UNKNOWN module must remain read-only pending evidence'

    $guide8RegionOnly = Join-Path $scratch 'guide8-region-only.md'
    New-Guide -Path $guide8RegionOnly -Rows @() -OwnedModules @(
        @{ Id = 'typography'; Sources = @('tokens:missing'); Body = "`nTypography evidence.`n" }
    )
    $regionOnly = Test-GuideFreshness -GuidePath $guide8RegionOnly -ManifestPath $manifest8 -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $regionOnly.Overall 'A region-only module must not be CURRENT without matching authorized-input provenance'

    $guide8BlankScope = Join-Path $scratch 'guide8-blank-scope.md'
    New-Guide -Path $guide8BlankScope -Rows @(
        @{ SourceId = 'tokens:missing'; Revision = 'sha256:' + ('0' * 64); ApprovalState = 'DERIVED'; Scope = '' }
    ) -OwnedModules @()
    $blankScope = Test-GuideFreshness -GuidePath $guide8BlankScope -ManifestPath $manifest8 -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $blankScope.Overall 'A blank guide-row scope must be UNKNOWN, never CURRENT'

    $guide8Malformed = Join-Path $scratch 'guide8-malformed-marker.md'
    Set-Content -LiteralPath $guide8Malformed -Value @"
# Malformed marker fixture

<!-- guide-owned:typography sources="tokens:missing" revision="sha256:$('0' * 64)" -->
Unclosed owned content.
"@ -NoNewline
    $malformedMarker = Test-GuideFreshness -GuidePath $guide8Malformed -ManifestPath $manifest8 -RepoRoot $scratch
    Assert-Equal 'BLOCKED' $malformedMarker.Overall 'Unbalanced guide-owned markers must block ambiguous ownership'
    $unavailableManifestBlocked = Test-GuideFreshness -GuidePath $guide8Malformed -ManifestPath $manifest8Unavailable -RepoRoot $scratch
    Assert-Equal 'BLOCKED' $unavailableManifestBlocked.Overall 'Guide-only ownership ambiguity must keep BLOCKED precedence even when the manifest is unavailable'

    $guide8EmptyBody = Join-Path $scratch 'guide8-empty-body.md'
    New-Guide -Path $guide8EmptyBody -Rows @(
        @{ SourceId = 'tokens:missing'; Revision = 'sha256:' + ('0' * 64); ApprovalState = 'DERIVED'; Scope = 'typography' }
    ) -OwnedModules @(
        @{ Id = 'typography'; Sources = @('tokens:missing'); Body = '' }
    )
    $emptyBody = Test-GuideFreshness -GuidePath $guide8EmptyBody -ManifestPath $manifest8 -RepoRoot $scratch
    Assert-Equal 'UNKNOWN' $emptyBody.Overall 'An empty owned region must be classified fail-closed instead of aborting assessment'
    Assert-True (($emptyBody.Reasons -join ' ') -match 'empty') 'Empty owned regions must preserve a diagnostic reason'

    $guide8Crossed = Join-Path $scratch 'guide8-crossed-marker.md'
    Set-Content -LiteralPath $guide8Crossed -Value @"
# Crossed marker fixture

<!-- guide-owned:typography sources="tokens:missing" revision="sha256:$('0' * 64)" -->
Outer owned content.
<!-- guide-owned:foundations sources="tokens:missing" revision="sha256:$('1' * 64)" -->
Inner owned content.
<!-- /guide-owned:typography -->
<!-- /guide-owned:foundations -->
"@ -NoNewline
    $crossedMarker = Test-GuideFreshness -GuidePath $guide8Crossed -ManifestPath $manifest8 -RepoRoot $scratch
    Assert-Equal 'BLOCKED' $crossedMarker.Overall 'Crossed or partially parsed guide-owned markers must block ambiguous ownership'

    # === Scenario 9: path containment -- absolute and traversal paths rejected =
    Write-Host '[9/12] absolute and traversal manifest paths are constrained to RepoRoot'
    $escapeTargetDir = Join-Path ([System.IO.Path]::GetTempPath()) ("sga-228-outside-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $escapeTargetDir -Force | Out-Null
    $escapeFile = Join-Path $escapeTargetDir 'secret.json'
    Set-Content -LiteralPath $escapeFile -Value '{"$type":"color","primary":"#000000"}' -NoNewline
    try {
        $relativeEscape = [System.IO.Path]::Combine('..', (Split-Path $escapeTargetDir -Leaf), 'secret.json')
        $manifest9a = Join-Path $scratch 'manifest9a.json'
        New-Manifest -Path $manifest9a -Sources @(@{ id = 'tokens:escape-rel'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; path = $relativeEscape })
        $sources9a = Read-InputsManifest -ManifestPath $manifest9a -RepoRoot $scratch
        Assert-True (-not $sources9a['tokens:escape-rel'].available) 'A relative-traversal path escaping RepoRoot must not be treated as available'
        Assert-True ($sources9a['tokens:escape-rel'].unavailableReason -match 'escapes repo root') 'The escape-path diagnostic must explain why'

        $absolutePath = $escapeFile
        $manifest9b = Join-Path $scratch 'manifest9b.json'
        New-Manifest -Path $manifest9b -Sources @(@{ id = 'tokens:escape-abs'; kind = 'token'; scope = 'typography'; status = 'DERIVED'; path = $absolutePath })
        $sources9b = Read-InputsManifest -ManifestPath $manifest9b -RepoRoot $scratch
        Assert-True (-not $sources9b['tokens:escape-abs'].available) 'An absolute manifest source path must be rejected, not honored'
        Assert-True ($sources9b['tokens:escape-abs'].unavailableReason -match 'absolute path rejected') 'The absolute-path diagnostic must explain why'

        if (-not $IsWindows) {
            $caseSibling = Join-Path (Split-Path $scratch -Parent) ((Split-Path $scratch -Leaf).ToUpperInvariant())
            New-Item -ItemType Directory -Path $caseSibling -Force | Out-Null
            try {
                $caseFile = Join-Path $caseSibling 'secret.json'
                Set-Content -LiteralPath $caseFile -Value '{}' -NoNewline
                $caseRelative = [System.IO.Path]::Combine('..', (Split-Path $caseSibling -Leaf), 'secret.json')
                $caseResult = Resolve-ManifestSourcePath -RepoRoot $scratch -RelativePath $caseRelative
                Assert-True (-not $caseResult.Path) 'Case-distinct sibling paths must not pass containment on case-sensitive hosts'
            } finally {
                Remove-Item -LiteralPath $caseSibling -Recurse -Force -ErrorAction SilentlyContinue
            }

            $linkPath = Join-Path $scratch 'outside-link.json'
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $escapeFile | Out-Null
            $linkResult = Resolve-ManifestSourcePath -RepoRoot $scratch -RelativePath 'outside-link.json'
            Assert-True (-not $linkResult.Path) 'An in-root symbolic link must not allow reading an outside target'
            Assert-True ($linkResult.Reason -match 'symbolic links') 'The symbolic-link rejection must preserve an explicit diagnostic'
            $linkTraversal = [System.IO.Path]::Combine('missing', '..', 'outside-link.json')
            $linkTraversalResult = Resolve-ManifestSourcePath -RepoRoot $scratch -RelativePath $linkTraversal
            Assert-True (-not $linkTraversalResult.Path) 'Traversal-normalized source paths must still reject the final symlink target'
            Assert-True ($linkTraversalResult.Reason -match 'symbolic links') 'Traversal-plus-link rejection must preserve a symbolic-link diagnostic'
        }

        # And the overall assessment must degrade to UNKNOWN rather than throwing.
        $guide9 = Join-Path $scratch 'guide9.md'
        New-Guide -Path $guide9 -Rows @(@{ SourceId = 'tokens:escape-abs'; Revision = 'sha256:' + ('0' * 64); ApprovalState = 'DERIVED'; Scope = 'typography' }) -OwnedModules @()
        $r9 = Test-GuideFreshness -GuidePath $guide9 -ManifestPath $manifest9b -RepoRoot $scratch
        Assert-Equal 'UNKNOWN' $r9.Overall 'An assessment referencing only a rejected absolute path must degrade to UNKNOWN, not abort'

        $invalidPath = "bad$([char]0)path"
        $invalidResult = Resolve-ManifestSourcePath -RepoRoot $scratch -RelativePath $invalidPath
        Assert-True (-not $invalidResult.Path) 'Malformed path strings must return unresolved rather than throw'
        Assert-True ($invalidResult.Reason -match 'invalid source path') 'Malformed paths must preserve a diagnostic'
    } finally {
        Remove-Item -LiteralPath $escapeTargetDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # === Scenario 10: authorization downgrade cannot yield CURRENT ==============
    Write-Host '[10/12] a downgraded (PROPOSED) source cannot satisfy an APPROVED-recorded row'
    $manifest10 = Join-Path $scratch 'manifest10.json'
    New-Manifest -Path $manifest10 -Sources @(
        @{ id = 'guide:brand-a'; kind = 'approved-guide'; scope = 'foundations'; status = 'PROPOSED'; digest = $brandGuideDigest }
    )
    $guide10 = Join-Path $scratch 'guide10.md'
    New-Guide -Path $guide10 -Rows @(
        @{ SourceId = 'guide:brand-a'; Revision = $brandGuideDigest; ApprovalState = 'APPROVED'; Scope = 'foundations' }
    ) -OwnedModules @()
    $r10 = Test-GuideFreshness -GuidePath $guide10 -ManifestPath $manifest10 -RepoRoot $scratch
    Assert-True ($r10.Overall -ne 'CURRENT') 'A source downgraded to PROPOSED must not satisfy a recorded APPROVED row, even with a matching digest'
    Assert-Equal 'STALE' $r10.Modules['foundations'] 'The downgraded module must be reported STALE, not silently passed as CURRENT'

    # === Scenario 11: refresh-guide.ps1 CLI exit codes for BLOCKED and PARTIAL ==
    Write-Host '[11/12] refresh-guide.ps1 exits nonzero for both BLOCKED and PARTIAL'
    $refreshCli = Join-Path $repoRoot 'skills' -AdditionalChildPath 'style-guide-authoring', 'scripts', 'refresh-guide.ps1'

    # BLOCKED case: reuse the conflicting-sources fixture from Scenario 1.
    New-Manifest -Path $manifest1 -Sources @(
        @{ id = 'guide:brand-a'; kind = 'approved-guide'; scope = 'foundations'; rule = 'primary-principle'; status = 'APPROVED'; value = 'clarity-first'; digest = $brandGuideDigest },
        @{ id = 'guide:brand-b'; kind = 'approved-guide'; scope = 'foundations'; rule = 'primary-principle'; status = 'APPROVED'; value = 'boldness-first'; digest = ('sha256:' + ('b' * 64)) }
    )
    & pwsh -NonInteractive -File $refreshCli -GuidePath $guide1 -ManifestPath $manifest1 -RepoRoot $scratch -Quiet | Out-Null
    Assert-Equal 1 $LASTEXITCODE 'refresh-guide.ps1 must exit nonzero for a BLOCKED result'
    $blockedResult = Invoke-GuideRefresh -GuidePath $guide1 -ManifestPath $manifest1 -RepoRoot $scratch
    Assert-Equal 'BLOCKED' $blockedResult.Result 'Conflicting approved sources must produce a BLOCKED refresh result'
    Assert-True ($null -ne $blockedResult.PostAssessment) 'BLOCKED refresh must preserve the freshness assessment for callers'
    Assert-True ($null -ne $blockedResult.PostAssessment.Actions) 'BLOCKED refresh assessment must include remediation actions'

    # PARTIAL case: STALE module whose source cannot be resolved (unauthorized), so nothing can be written.
    $manifest11 = Join-Path $scratch 'manifest11.json'
    New-Manifest -Path $manifest11 -Sources @(
        @{ id = 'guide:brand-a'; kind = 'approved-guide'; scope = 'foundations'; status = 'PROPOSED'; digest = $brandGuideDigest }
    )
    $guide11 = Join-Path $scratch 'guide11.md'
    New-Guide -Path $guide11 -Rows @(
        @{ SourceId = 'guide:brand-a'; Revision = $brandGuideDigest; ApprovalState = 'APPROVED'; Scope = 'foundations' }
    ) -OwnedModules @()
    & pwsh -NonInteractive -File $refreshCli -GuidePath $guide11 -ManifestPath $manifest11 -RepoRoot $scratch -Quiet | Out-Null
    Assert-Equal 1 $LASTEXITCODE 'refresh-guide.ps1 must exit nonzero for a PARTIAL result (unresolved stale module)'
    $partialResult = Invoke-GuideRefresh -GuidePath $guide11 -ManifestPath $manifest11 -RepoRoot $scratch
    Assert-Equal 'PARTIAL' $partialResult.Result 'The unresolved-source case must be classified PARTIAL, not silently REFRESHED or NO_OP'
    Assert-Equal $false $partialResult.Wrote 'A PARTIAL result with nothing resolvable must not write'

    # === Scenario 12: repeated read-only checks never touch the CLI's own files
    Write-Host '[12/12] check-guide-freshness.ps1 CLI is read-only end to end'
    $checkCli = Join-Path $repoRoot 'skills' -AdditionalChildPath 'style-guide-authoring', 'scripts', 'check-guide-freshness.ps1'
    # Dedicated STALE fixture: guide2/manifest2 were restored to CURRENT at the
    # end of scenario 2, so reuse a fresh mismatch instead of relying on them.
    $manifest12 = Join-Path $scratch 'manifest12.json'
    New-Manifest -Path $manifest12 -Sources @(
        @{ id = 'tokens:color'; kind = 'token'; scope = 'visual-foundations'; status = 'DERIVED'; path = 'tokens.color.json' }
    )
    $guide12 = Join-Path $scratch 'guide12.md'
    New-Guide -Path $guide12 -Rows @(
        @{ SourceId = 'tokens:color'; Revision = ('sha256:' + ('9' * 64)); ApprovalState = 'DERIVED'; Scope = 'visual-foundations' }
    ) -OwnedModules @()
    $cliGuideHashBefore = (Get-FileHash -LiteralPath $guide12 -Algorithm SHA256).Hash
    $cliGuideTimeBefore = (Get-Item -LiteralPath $guide12).LastWriteTimeUtc
    $cliOutput = & pwsh -NonInteractive -File $checkCli -GuidePath $guide12 -ManifestPath $manifest12 -RepoRoot $scratch
    Assert-Equal 1 $LASTEXITCODE 'A non-CURRENT guide must produce a nonzero check-guide-freshness.ps1 exit code'
    $cliJson = $cliOutput | ConvertFrom-Json
    Assert-True ($null -ne $cliJson.actions) 'check-guide-freshness.ps1 must serialize per-module remediation actions'
    & pwsh -NonInteractive -File $checkCli -GuidePath $guide12 -ManifestPath $manifest12 -RepoRoot $scratch -Quiet | Out-Null
    Assert-Equal 1 $LASTEXITCODE 'A STALE guide must produce a nonzero check-guide-freshness.ps1 exit code'
    Assert-Equal $cliGuideHashBefore (Get-FileHash -LiteralPath $guide12 -Algorithm SHA256).Hash 'check-guide-freshness.ps1 must not write the guide it inspects'
    Assert-Equal $cliGuideTimeBefore (Get-Item -LiteralPath $guide12).LastWriteTimeUtc 'check-guide-freshness.ps1 must not touch the timestamp of the guide it inspects'

    Write-Host "All style-guide-authoring input/freshness scenarios passed (12 scenarios)."
} finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
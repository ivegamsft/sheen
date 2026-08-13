<#
.SYNOPSIS
    Bootstrap Azure resources and GitHub secrets for MCP server deployment.

.DESCRIPTION
    Idempotent four-phase setup for the BaseCoat Metrics MCP server:
      Phase 1 — Prerequisites   (az CLI, gh CLI, Azure login, repo access)
      Phase 2 — Azure resources (resource group, service principal)
      Phase 3 — GitHub secrets  (AZURE_CREDENTIALS, MCP_RESOURCE_GROUP)
      Phase 4 — GHCR check      (verifies package exists)

    After completion, trigger the deploy with:
      gh workflow run mcp-deploy.yml --repo <owner>/<repo>

.PARAMETER ResourceGroup
    Azure resource group name. Defaults to 'rg-basecoat-mcp'.

.PARAMETER Location
    Azure region for the resource group. Defaults to 'eastus'.

.PARAMETER SpnName
    Display name for the service principal. Defaults to 'basecoat-mcp-deploy'.

.PARAMETER Repo
    GitHub repository slug (owner/name). Auto-detected from the current git remote.

.PARAMETER DryRun
    Show the actions without mutating Azure or GitHub.

.PARAMETER TriggerDeploy
    After secrets are set, trigger the MCP Deploy workflow.

.EXAMPLE
    pwsh scripts/bootstrap-mcp.ps1

.EXAMPLE
    pwsh scripts/bootstrap-mcp.ps1 -DryRun

.EXAMPLE
    pwsh scripts/bootstrap-mcp.ps1 -ResourceGroup rg-mcp-staging -Location westus2

.EXAMPLE
    pwsh scripts/bootstrap-mcp.ps1 -TriggerDeploy
#>

[CmdletBinding()]
param(
    [string]$ResourceGroup = 'rg-basecoat-mcp',
    [string]$Location = 'eastus',
    [string]$SpnName = 'basecoat-mcp-deploy',
    [string]$Repo,
    [switch]$DryRun,
    [switch]$TriggerDeploy
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── helpers ──────────────────────────────────────────────────────────────────

function Write-Header([string]$Text) {
    Write-Host ""
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host ('=' * 72) -ForegroundColor Cyan
}

function Write-Ok([string]$Text)   { Write-Host "  ✅  $Text" -ForegroundColor Green }
function Write-Skip([string]$Text) { Write-Host "  ⏭️   $Text" -ForegroundColor DarkGray }
function Write-Info([string]$Text) { Write-Host "  ℹ️   $Text" -ForegroundColor DarkGray }
function Write-Warn([string]$Text) { Write-Host "  ⚠️   $Text" -ForegroundColor Yellow }
function Write-Fail([string]$Text) { Write-Host "  ❌  $Text" -ForegroundColor Red }

# ── Phase 1: Prerequisites ──────────────────────────────────────────────────

Write-Header "Phase 1 — Prerequisites"

# az CLI
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Fail "Azure CLI required. Install from https://aka.ms/AzureCLI"
    exit 1
}
Write-Ok "Azure CLI found"

# gh CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Fail "GitHub CLI required. Install from https://cli.github.com"
    exit 1
}
Write-Ok "GitHub CLI found"

# Azure login check
$azAccount = az account show 2>$null | ConvertFrom-Json
if (-not $azAccount) {
    Write-Fail "Not authenticated with Azure. Run 'az login' first."
    exit 1
}
$subscriptionId = $azAccount.id
$subscriptionName = $azAccount.name
Write-Ok "Azure authenticated — subscription: $subscriptionName"

# Resolve repo from git remote if not provided
if (-not $Repo) {
    $remoteUrl = git remote get-url origin 2>$null
    if ($remoteUrl -match 'github\.com[:/](.+?)(?:\.git)?$') {
        $Repo = $Matches[1]
    }
    if (-not $Repo) {
        Write-Fail "Could not detect repository. Pass -Repo owner/name."
        exit 1
    }
}
Write-Ok "Repository: $Repo"

# gh auth check
$ghStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail "GitHub CLI not authenticated. Run 'gh auth login' first."
    exit 1
}
Write-Ok "GitHub CLI authenticated"

if ($DryRun) {
    Write-Warn "DRY RUN — no changes will be made"
}

Write-Info "Resource group: $ResourceGroup"
Write-Info "Location: $Location"
Write-Info "SPN name: $SpnName"
Write-Info "Subscription: $subscriptionId"

# ── Phase 2: Azure Resources ────────────────────────────────────────────────

Write-Header "Phase 2 — Azure Resources"

# 2a. Resource group
$existingRg = az group show --name $ResourceGroup 2>$null | ConvertFrom-Json
if ($existingRg) {
    Write-Skip "Resource group '$ResourceGroup' already exists ($($existingRg.location))"
} elseif ($DryRun) {
    Write-Info "Would create resource group '$ResourceGroup' in '$Location'"
} else {
    Write-Host "  Creating resource group '$ResourceGroup' in '$Location'..." -ForegroundColor Yellow
    az group create --name $ResourceGroup --location $Location --output none
    Write-Ok "Resource group '$ResourceGroup' created"
}

# 2b. Service principal
$rgScope = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup"

# Check if SPN already exists
$existingSpn = az ad sp list --display-name $SpnName --query "[0].appId" -o tsv 2>$null
if ($existingSpn) {
    Write-Skip "Service principal '$SpnName' already exists (appId: $existingSpn)"
    Write-Warn "To reset credentials, delete the SPN first: az ad sp delete --id $existingSpn"

    # Generate fresh credentials for the existing SPN
    Write-Host "  Generating fresh credentials for existing SPN..." -ForegroundColor Yellow
    if ($DryRun) {
        Write-Info "Would generate new credentials for SPN '$SpnName'"
        $spnJson = $null
    } else {
        $spnJson = az ad sp create-for-rbac `
            --name $SpnName `
            --role "Contributor" `
            --scopes $rgScope `
            --sdk-auth 2>$null
        Write-Ok "Fresh credentials generated (not displayed)"
    }
} elseif ($DryRun) {
    Write-Info "Would create service principal '$SpnName' with Contributor on '$ResourceGroup'"
    $spnJson = $null
} else {
    Write-Host "  Creating service principal '$SpnName'..." -ForegroundColor Yellow
    $spnJson = az ad sp create-for-rbac `
        --name $SpnName `
        --role "Contributor" `
        --scopes $rgScope `
        --sdk-auth 2>$null
    if (-not $spnJson) {
        Write-Fail "Failed to create service principal. Check Azure permissions."
        exit 1
    }
    Write-Ok "Service principal created (credentials not displayed)"
}

# ── Phase 3: GitHub Secrets ──────────────────────────────────────────────────

Write-Header "Phase 3 — GitHub Secrets"

if ($DryRun) {
    Write-Info "Would set secret AZURE_CREDENTIALS on $Repo"
    Write-Info "Would set secret MCP_RESOURCE_GROUP on $Repo"
} elseif (-not $spnJson) {
    Write-Warn "No SPN credentials available — skipping secret setup"
    Write-Warn "Re-run without -DryRun to generate credentials and set secrets"
} else {
    # Set AZURE_CREDENTIALS (pipe JSON via stdin — never echo to console)
    $spnJson | gh secret set AZURE_CREDENTIALS --repo $Repo
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Failed to set AZURE_CREDENTIALS secret"
        exit 1
    }
    Write-Ok "Secret AZURE_CREDENTIALS set on $Repo"

    gh secret set MCP_RESOURCE_GROUP --repo $Repo --body $ResourceGroup
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Failed to set MCP_RESOURCE_GROUP secret"
        exit 1
    }
    Write-Ok "Secret MCP_RESOURCE_GROUP set on $Repo"
}

# ── Phase 4: GHCR Package Visibility ─────────────────────────────────────────

Write-Header "Phase 4 — GHCR Package Check"

# The deploy workflow passes GITHUB_TOKEN as registry credentials to Bicep,
# so the package does NOT need to be public. This phase just verifies the
# package exists (it won't until after the first image push).
$packageName = 'basecoat-metrics-mcp'
$org = ($Repo -split '/')[0]

if ($DryRun) {
    Write-Info "Would check if package '$packageName' exists"
} else {
    $rawJson = gh api "/orgs/$org/packages/container/$packageName" 2>$null
    $packageInfo = $null
    if ($LASTEXITCODE -eq 0 -and $rawJson) {
        $packageInfo = $rawJson | ConvertFrom-Json -ErrorAction SilentlyContinue
    }
    if ($packageInfo -and $packageInfo.PSObject.Properties['name']) {
        Write-Ok "Package '$packageName' exists (visibility: $($packageInfo.visibility))"
        Write-Info "Deploy workflow uses authenticated GHCR pulls — public visibility not required"
    } else {
        Write-Warn "Package '$packageName' does not exist yet"
        Write-Info "It will be created on the first deploy workflow run"
    }
}

# ── Phase 5: Optional Deploy Trigger ─────────────────────────────────────────

if ($TriggerDeploy) {
    Write-Header "Phase 5 — Trigger Deploy"

    if ($DryRun) {
        Write-Info "Would trigger mcp-deploy.yml on $Repo"
    } else {
        gh workflow run mcp-deploy.yml --repo $Repo
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "Failed to trigger MCP deploy workflow"
            exit 1
        }
        Write-Ok "MCP Deploy workflow triggered"
        Write-Info "Monitor: gh run list --workflow=mcp-deploy.yml --repo $Repo"
    }
} else {
    Write-Host ""
    Write-Info "To deploy, run:"
    Write-Info "  gh workflow run mcp-deploy.yml --repo $Repo"
    Write-Info "Or re-run this script with -TriggerDeploy"
}

# ── Summary ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host ('=' * 72) -ForegroundColor Green
Write-Host "  MCP Bootstrap Complete" -ForegroundColor Green
Write-Host ('=' * 72) -ForegroundColor Green
Write-Host ""

<#
.SYNOPSIS
    Configures Microsoft Fabric workspace service principal access for notebook deployment.

.DESCRIPTION
    Provisions Fabric workspace role assignments for a service principal (OIDC federated identity).
    Enables automated notebook deployment via CI/CD without manual Portal configuration.
    Idempotent — skips assignment if service principal already has the role.

.PARAMETER WorkspaceId
    Fabric workspace GUID (required). Extract from workspace URL: admin.fabric.microsoft.com/workspaces/{WorkspaceId}

.PARAMETER ServicePrincipalId
    Service principal app ID (ObjectId from Microsoft Entra). If omitted, uses AZURE_CLIENT_ID environment variable.

.PARAMETER Role
    Role to assign: 'Contributor' (default), 'Viewer', 'Editor', or 'Admin'.
    For notebook deployment, 'Contributor' is minimum required.

.PARAMETER TenantId
    Azure tenant ID for authentication. If omitted, uses AZURE_TENANT_ID environment variable.

.PARAMETER SubscriptionId
    Azure subscription ID for context. If omitted, uses AZURE_SUBSCRIPTION_ID environment variable.

.PARAMETER DryRun
    Show what would be created without making changes.

.EXAMPLE
    ./bootstrap-fabric-workspace.ps1 `
      -WorkspaceId "f4a1c3e5-2b4d-4a8c-9f1e-7d5c8b3a2f6e" `
      -ServicePrincipalId "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d" `
      -Role "Contributor"

    ./bootstrap-fabric-workspace.ps1 -DryRun

    # Using environment variables
    $env:FABRIC_WORKSPACE_ID = "f4a1c3e5-2b4d-4a8c-9f1e-7d5c8b3a2f6e"
    $env:AZURE_CLIENT_ID = "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d"
    ./bootstrap-fabric-workspace.ps1
#>

param(
    [string]$WorkspaceId,
    [string]$ServicePrincipalId,
    [ValidateSet("Contributor", "Viewer", "Editor", "Admin")]
    [string]$Role = "Contributor",
    [string]$TenantId,
    [string]$SubscriptionId,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Fabric Workspace Service Principal Bootstrap                   ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Validate prerequisites
function Test-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Yellow

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: Azure CLI required. Install from https://aka.ms/AzureCLI" -ForegroundColor Red
        exit 1
    }

    $azAccount = az account show 2>$null
    if (-not $azAccount) {
        Write-Host "ERROR: Not authenticated with Azure. Run 'az login'" -ForegroundColor Red
        exit 1
    }

    Write-Host "✓ Prerequisites met" -ForegroundColor Green
}

# Resolve parameters from environment or arguments
function Resolve-Parameters {
    Write-Host "Resolving parameters..." -ForegroundColor Yellow

    if (-not $WorkspaceId) {
        $WorkspaceId = $env:FABRIC_WORKSPACE_ID
        if (-not $WorkspaceId) {
            Write-Host "ERROR: -WorkspaceId required or FABRIC_WORKSPACE_ID environment variable must be set" -ForegroundColor Red
            exit 1
        }
    }

    if (-not $ServicePrincipalId) {
        $ServicePrincipalId = $env:AZURE_CLIENT_ID
        if (-not $ServicePrincipalId) {
            Write-Host "ERROR: -ServicePrincipalId required or AZURE_CLIENT_ID environment variable must be set" -ForegroundColor Red
            exit 1
        }
    }

    if (-not $TenantId) {
        $TenantId = $env:AZURE_TENANT_ID
        if (-not $TenantId) {
            $accountInfo = az account show --query tenantId -o tsv 2>$null
            $TenantId = $accountInfo
        }
    }

    if (-not $SubscriptionId) {
        $SubscriptionId = $env:AZURE_SUBSCRIPTION_ID
        if (-not $SubscriptionId) {
            $accountInfo = az account show --query id -o tsv 2>$null
            $SubscriptionId = $accountInfo
        }
    }

    Write-Host "  Workspace ID: $WorkspaceId" -ForegroundColor Gray
    Write-Host "  Service Principal (App ID): $ServicePrincipalId" -ForegroundColor Gray
    Write-Host "  Role: $Role" -ForegroundColor Gray
    Write-Host "  Tenant ID: $TenantId" -ForegroundColor Gray
    Write-Host "  Subscription ID: $SubscriptionId" -ForegroundColor Gray
    Write-Host "✓ Parameters resolved" -ForegroundColor Green

    return @{
        WorkspaceId           = $WorkspaceId
        ServicePrincipalId    = $ServicePrincipalId
        Role                  = $Role
        TenantId              = $TenantId
        SubscriptionId        = $SubscriptionId
    }
}

# Check if service principal already has the role
function Test-RoleAssignment {
    param(
        [string]$WorkspaceId,
        [string]$ServicePrincipalId,
        [string]$Role,
        [string]$TenantId
    )

    Write-Host "Checking current role assignments..." -ForegroundColor Yellow

    try {
        $roleId = Get-FabricRoleId -Role $Role

        $assignments = az rest `
            --method GET `
            --url "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/roleAssignments" `
            --headers "Authorization=Bearer" 2>$null | ConvertFrom-Json

        if ($assignments.value) {
            foreach ($assignment in $assignments.value) {
                if ($assignment.principal.id -eq $ServicePrincipalId -and $assignment.role -eq $Role) {
                    return $true
                }
            }
        }
        return $false
    }
    catch {
        Write-Host "  Warning: Could not verify existing assignments (proceeding anyway)" -ForegroundColor Yellow
        return $false
    }
}

# Get Fabric role ID
function Get-FabricRoleId {
    param([string]$Role)

    switch ($Role) {
        "Admin" { return "d10d16a8-2a99-46b5-9caf-87f98fe1eb6f" }
        "Contributor" { return "f6bbc49f-22ca-4191-a54f-a2298eb26fa0" }
        "Editor" { return "8d2a2e2f-e6b9-4a7f-a2d4-5c8b9e1f3a7d" }
        "Viewer" { return "64e1b77a-130e-402e-b349-b510fc21b650" }
        default { throw "Unknown role: $Role" }
    }
}

# Assign role to service principal
function Add-FabricRoleAssignment {
    param(
        [string]$WorkspaceId,
        [string]$ServicePrincipalId,
        [string]$Role,
        [string]$TenantId,
        [bool]$DryRun
    )

    Write-Host "Setting up role assignment..." -ForegroundColor Yellow

    $roleId = Get-FabricRoleId -Role $Role

    $payload = @{
        principal = @{
            id   = $ServicePrincipalId
            type = "ServicePrincipal"
        }
        role = $Role
    } | ConvertTo-Json

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would assign $Role role to service principal $ServicePrincipalId on workspace $WorkspaceId" -ForegroundColor Cyan
        Write-Host "  Payload:" -ForegroundColor Gray
        Write-Host "  $payload" -ForegroundColor Gray
        return
    }

    try {
        az rest `
            --method POST `
            --url "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/roleAssignments" `
            --headers "Content-Type=application/json" `
            --body $payload | Out-Null

        Write-Host "✓ Successfully assigned $Role role to service principal" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Failed to assign role. Error: $_" -ForegroundColor Red
        exit 1
    }
}

# Generate GitHub Actions configuration guidance
function Show-ConfigurationGuidance {
    param(
        [string]$WorkspaceId,
        [string]$ServicePrincipalId,
        [string]$TenantId
    )

    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Fabric Workspace Configuration Complete" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Next: Configure GitHub Actions workflow variables" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Add these repository variables (Settings → Secrets and variables → Variables):" -ForegroundColor Gray
    Write-Host "  FABRIC_WORKSPACE_ID:   $WorkspaceId" -ForegroundColor Gray
    Write-Host "  AZURE_CLIENT_ID:       $ServicePrincipalId" -ForegroundColor Gray
    Write-Host "  AZURE_TENANT_ID:       $TenantId" -ForegroundColor Gray
    Write-Host ""

    Write-Host "GitHub Actions workflow pattern:" -ForegroundColor Gray
    Write-Host ""
    Write-Host @'
  - name: Azure OIDC Login
    uses: azure/login@v2
    with:
      client-id: `${{ vars.AZURE_CLIENT_ID }}
      tenant-id: `${{ vars.AZURE_TENANT_ID }}
      subscription-id: `${{ vars.AZURE_SUBSCRIPTION_ID }}

  - name: Upload Notebooks to Fabric
    run: |
      `$headers = @{
        "Authorization" = "Bearer $(az account get-access-token --resource 'https://api.fabric.microsoft.com' --query accessToken -o tsv)"
      }
      # Upload notebooks to workspace via Fabric REST API
      # See: https://learn.microsoft.com/fabric/rest-api/
'@ -ForegroundColor Gray

    Write-Host ""
    Write-Host "Security best practices:" -ForegroundColor Yellow
    Write-Host "  • Service principal has Contributor role ONLY on this workspace" -ForegroundColor Gray
    Write-Host "  • OIDC federated credentials restrict tokens to specific branches/environments" -ForegroundColor Gray
    Write-Host "  • Monitor role assignments in Fabric workspace settings" -ForegroundColor Gray
    Write-Host "  • Rotate credentials quarterly or on team changes" -ForegroundColor Gray
    Write-Host ""
}

# Main execution
try {
    Test-Prerequisites

    $params = Resolve-Parameters

    $alreadyAssigned = Test-RoleAssignment `
        -WorkspaceId $params.WorkspaceId `
        -ServicePrincipalId $params.ServicePrincipalId `
        -Role $params.Role `
        -TenantId $params.TenantId

    if ($alreadyAssigned) {
        Write-Host "ℹ Service principal already has $($params.Role) role (skipping)" -ForegroundColor Cyan
    }
    else {
        Add-FabricRoleAssignment `
            -WorkspaceId $params.WorkspaceId `
            -ServicePrincipalId $params.ServicePrincipalId `
            -Role $params.Role `
            -TenantId $params.TenantId `
            -DryRun $DryRun
    }

    if (-not $DryRun) {
        Show-ConfigurationGuidance `
            -WorkspaceId $params.WorkspaceId `
            -ServicePrincipalId $params.ServicePrincipalId `
            -TenantId $params.TenantId
    }

    Write-Host "✓ Bootstrap complete" -ForegroundColor Green
}
catch {
    Write-Host "FATAL: $_" -ForegroundColor Red
    exit 1
}

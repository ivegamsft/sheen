#!/usr/bin/env bash

# bootstrap-fabric-workspace.sh — Configure Fabric workspace service principal access
#
# Provisions Fabric workspace role assignments for a service principal (OIDC federated identity).
# Enables automated notebook deployment via CI/CD without manual Portal configuration.
# Idempotent — skips assignment if service principal already has the role.
#
# Usage:
#   ./bootstrap-fabric-workspace.sh \
#     --workspace-id "f4a1c3e5-2b4d-4a8c-9f1e-7d5c8b3a2f6e" \
#     --service-principal-id "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d" \
#     --role "Contributor"
#
#   ./bootstrap-fabric-workspace.sh --dry-run
#
# Environment variables (alternative to flags):
#   FABRIC_WORKSPACE_ID  — Workspace GUID
#   AZURE_CLIENT_ID      — Service principal app ID
#   AZURE_TENANT_ID      — Tenant ID (auto-detected if omitted)
#   AZURE_SUBSCRIPTION_ID — Subscription ID (auto-detected if omitted)

set -euo pipefail

WORKSPACE_ID=""
SERVICE_PRINCIPAL_ID=""
ROLE="Contributor"
TENANT_ID=""
SUBSCRIPTION_ID=""
DRY_RUN=false

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

log_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Fabric Workspace Service Principal Bootstrap                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log_info() {
    echo -e "${YELLOW}$1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

log_gray() {
    echo -e "${GRAY}$1${NC}"
}

test_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v az &> /dev/null; then
        log_error "Azure CLI required. Install from https://aka.ms/AzureCLI"
        exit 1
    fi

    if ! az account show &> /dev/null; then
        log_error "Not authenticated with Azure. Run 'az login'"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log_error "jq required for JSON parsing. Install from https://stedolan.github.io/jq/"
        exit 1
    fi

    log_success "Prerequisites met"
}

resolve_parameters() {
    log_info "Resolving parameters..."

    if [ -z "$WORKSPACE_ID" ]; then
        WORKSPACE_ID="${FABRIC_WORKSPACE_ID:-}"
        if [ -z "$WORKSPACE_ID" ]; then
            log_error "-workspace-id required or FABRIC_WORKSPACE_ID environment variable must be set"
            exit 1
        fi
    fi

    if [ -z "$SERVICE_PRINCIPAL_ID" ]; then
        SERVICE_PRINCIPAL_ID="${AZURE_CLIENT_ID:-}"
        if [ -z "$SERVICE_PRINCIPAL_ID" ]; then
            log_error "-service-principal-id required or AZURE_CLIENT_ID environment variable must be set"
            exit 1
        fi
    fi

    if [ -z "$TENANT_ID" ]; then
        TENANT_ID="${AZURE_TENANT_ID:-}"
        if [ -z "$TENANT_ID" ]; then
            TENANT_ID=$(az account show --query tenantId -o tsv 2>/dev/null || true)
        fi
    fi

    if [ -z "$SUBSCRIPTION_ID" ]; then
        SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-}"
        if [ -z "$SUBSCRIPTION_ID" ]; then
            SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null || true)
        fi
    fi

    log_gray "  Workspace ID: $WORKSPACE_ID"
    log_gray "  Service Principal (App ID): $SERVICE_PRINCIPAL_ID"
    log_gray "  Role: $ROLE"
    log_gray "  Tenant ID: $TENANT_ID"
    log_gray "  Subscription ID: $SUBSCRIPTION_ID"
    log_success "Parameters resolved"
}

get_fabric_role_id() {
    local role=$1
    case "$role" in
        Admin)
            echo "d10d16a8-2a99-46b5-9caf-87f98fe1eb6f"
            ;;
        Contributor)
            echo "f6bbc49f-22ca-4191-a54f-a2298eb26fa0"
            ;;
        Editor)
            echo "8d2a2e2f-e6b9-4a7f-a2d4-5c8b9e1f3a7d"
            ;;
        Viewer)
            echo "64e1b77a-130e-402e-b349-b510fc21b650"
            ;;
        *)
            log_error "Unknown role: $role"
            exit 1
            ;;
    esac
}

test_role_assignment() {
    log_info "Checking current role assignments..."

    local token=$(az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv 2>/dev/null || true)
    if [ -z "$token" ]; then
        log_gray "  Warning: Could not verify existing assignments (proceeding anyway)"
        return 1
    fi

    local assignments=$(curl -s \
        -H "Authorization: Bearer $token" \
        "https://api.fabric.microsoft.com/v1/workspaces/$WORKSPACE_ID/roleAssignments" 2>/dev/null || true)

    if [ -n "$assignments" ] && echo "$assignments" | jq -e ".value[] | select(.principal.id == \"$SERVICE_PRINCIPAL_ID\" and .role == \"$ROLE\")" &>/dev/null; then
        return 0
    fi
    return 1
}

add_fabric_role_assignment() {
    log_info "Setting up role assignment..."

    local role_id=$(get_fabric_role_id "$ROLE")

    local payload=$(cat <<EOF
{
  "principal": {
    "id": "$SERVICE_PRINCIPAL_ID",
    "type": "ServicePrincipal"
  },
  "role": "$ROLE"
}
EOF
)

    if [ "$DRY_RUN" = true ]; then
        echo -e "${CYAN}  [DRY RUN] Would assign $ROLE role to service principal $SERVICE_PRINCIPAL_ID on workspace $WORKSPACE_ID${NC}"
        log_gray "  Payload:"
        echo "$payload" | jq '.' | sed 's/^/  /' | log_gray
        return 0
    fi

    local token=$(az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv)

    local response=$(curl -s -X POST \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "https://api.fabric.microsoft.com/v1/workspaces/$WORKSPACE_ID/roleAssignments" 2>&1)

    if echo "$response" | grep -q "error"; then
        log_error "Failed to assign role. Response: $response"
        exit 1
    fi

    log_success "Successfully assigned $ROLE role to service principal"
}

show_configuration_guidance() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Fabric Workspace Configuration Complete${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
    echo ""

    log_info "Next: Configure GitHub Actions workflow variables"
    echo ""
    log_gray "Add these repository variables (Settings → Secrets and variables → Variables):"
    log_gray "  FABRIC_WORKSPACE_ID:   $WORKSPACE_ID"
    log_gray "  AZURE_CLIENT_ID:       $SERVICE_PRINCIPAL_ID"
    log_gray "  AZURE_TENANT_ID:       $TENANT_ID"
    echo ""

    log_gray "GitHub Actions workflow pattern:"
    echo ""
    cat <<'WORKFLOW'
  - name: Azure OIDC Login
    uses: azure/login@v2
    with:
      client-id: ${{ vars.AZURE_CLIENT_ID }}
      tenant-id: ${{ vars.AZURE_TENANT_ID }}
      subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

  - name: Upload Notebooks to Fabric
    run: |
      HEADERS="Authorization: Bearer $(az account get-access-token --resource 'https://api.fabric.microsoft.com' --query accessToken -o tsv)"
      # Upload notebooks to workspace via Fabric REST API
      # See: https://learn.microsoft.com/fabric/rest-api/
WORKFLOW

    echo ""
    log_info "Security best practices:"
    log_gray "  • Service principal has Contributor role ONLY on this workspace"
    log_gray "  • OIDC federated credentials restrict tokens to specific branches/environments"
    log_gray "  • Monitor role assignments in Fabric workspace settings"
    log_gray "  • Rotate credentials quarterly or on team changes"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --workspace-id)
            WORKSPACE_ID="$2"
            shift 2
            ;;
        --service-principal-id)
            SERVICE_PRINCIPAL_ID="$2"
            shift 2
            ;;
        --role)
            ROLE="$2"
            shift 2
            ;;
        --tenant-id)
            TENANT_ID="$2"
            shift 2
            ;;
        --subscription-id)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            log_error "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Main execution
log_header
test_prerequisites
resolve_parameters

if test_role_assignment; then
    echo -e "${CYAN}ℹ Service principal already has $ROLE role (skipping)${NC}"
else
    add_fabric_role_assignment
fi

if [ "$DRY_RUN" = false ]; then
    show_configuration_guidance
fi

log_success "Bootstrap complete"

## Microsoft Fabric Workspace Service Principal Access

Automate role assignment and permissions for service principals to access Fabric workspaces programmatically.

### Prerequisites

- Azure subscription with Contributor access
- Microsoft Fabric tenant provisioned
- Azure CLI and Fabric Python SDK installed

### Step 1: Create Service Principal for Fabric

```bash
# Create Entra ID application for Fabric access
az ad app create --display-name "fabric-automation"

# Get the application ID
FABRIC_APP_ID=$(az ad app list --query "[?displayName=='fabric-automation'].appId" -o tsv)
echo "Fabric App ID: $FABRIC_APP_ID"

# Create service principal
az ad sp create --id $FABRIC_APP_ID

# Get the service principal object ID
FABRIC_SP_ID=$(az ad sp show --id $FABRIC_APP_ID --query id -o tsv)
echo "Fabric Service Principal ID: $FABRIC_SP_ID"
```

### Step 2: Assign Fabric Workspace Roles

Use the Fabric REST API to assign workspace roles:

```bash
# Get Fabric workspace ID (from Fabric UI or API)
FABRIC_WORKSPACE_ID="your-workspace-id"

# Authenticate with Fabric
TOKEN=$(az account get-access-token --resource "https://analysis.windows.net/powerbi/api" --query accessToken -o tsv)

# Assign Contributor role to service principal
curl -X POST \
  "https://api.powerbi.com/v1.0/myorg/groups/$FABRIC_WORKSPACE_ID/users" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "'$FABRIC_SP_ID'",
    "principalType": "ServicePrincipal",
    "accessRight": "Contributor"
  }'
```

### Step 3: Create Fabric Admin Secret in Key Vault

Store the service principal credentials securely:

```bash
# Generate password for service principal
FABRIC_PASSWORD=$(az ad app credential create --id $FABRIC_APP_ID --query password -o tsv)

# Store in Key Vault
az keyvault secret set \
  --vault-name "$KEYVAULT_NAME" \
  --name "fabric-sp-password" \
  --value "$FABRIC_PASSWORD"

# Store Fabric app ID
az keyvault secret set \
  --vault-name "$KEYVAULT_NAME" \
  --name "fabric-sp-id" \
  --value "$FABRIC_APP_ID"

# Store Fabric workspace ID
az keyvault secret set \
  --vault-name "$KEYVAULT_NAME" \
  --name "fabric-workspace-id" \
  --value "$FABRIC_WORKSPACE_ID"
```

### Step 4: Bicep Template for Fabric Role Assignment

```bicep
param fabricWorkspaceId string
param serviceAccountObjectId string
param tenantId string

// Create role assignment via Azure Graph API call
resource fabricRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, serviceAccountObjectId, 'Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: serviceAccountObjectId
    principalType: 'ServicePrincipal'
  }
}

output roleAssignmentId string = fabricRoleAssignment.id
```

### Step 5: Automate with GitHub Actions

```yaml
name: Configure Fabric Workspace Access

on:
  workflow_dispatch:

jobs:
  setup-fabric-access:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v2
        with:
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Create Fabric Service Principal
        run: |
          # Create app
          APP_JSON=$(az ad app create --display-name "fabric-automation" --output json)
          APP_ID=$(echo $APP_JSON | jq -r '.appId')
          
          # Create service principal
          az ad sp create --id $APP_ID
          
          # Store in Key Vault
          az keyvault secret set \
            --vault-name "${{ secrets.KEYVAULT_NAME }}" \
            --name "fabric-sp-id" \
            --value "$APP_ID"

      - name: Assign Fabric Workspace Access
        run: |
          # Get token for Fabric API
          FABRIC_TOKEN=$(az account get-access-token \
            --resource "https://analysis.windows.net/powerbi/api" \
            --query accessToken \
            --output tsv)
          
          # Get credentials from Key Vault
          FABRIC_SP_ID=$(az keyvault secret show \
            --vault-name "${{ secrets.KEYVAULT_NAME }}" \
            --name "fabric-sp-id" \
            --query value -o tsv)
          
          FABRIC_WORKSPACE_ID=$(az keyvault secret show \
            --vault-name "${{ secrets.KEYVAULT_NAME }}" \
            --name "fabric-workspace-id" \
            --query value -o tsv)
          
          # Assign Contributor role
          curl -X POST \
            "https://api.powerbi.com/v1.0/myorg/groups/$FABRIC_WORKSPACE_ID/users" \
            -H "Authorization: Bearer $FABRIC_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{
              "identifier": "'$FABRIC_SP_ID'",
              "principalType": "ServicePrincipal",
              "accessRight": "Contributor"
            }'
          
          echo "✓ Fabric workspace access configured"
```

### Step 6: Verify Fabric Access

```python
# verify_fabric_access.py
from azure.identity import ClientSecretCredential
from azure.keyvault.secrets import SecretClient
import requests

# Get credentials from Key Vault
keyvault_url = "https://your-keyvault-name.vault.azure.net"
secret_client = SecretClient(vault_url=keyvault_url, credential=ClientSecretCredential(
    tenant_id="your-tenant-id",
    client_id="your-client-id",
    client_secret="your-client-secret"
))

# Retrieve Fabric SP credentials
fabric_sp_id = secret_client.get_secret("fabric-sp-id").value
fabric_sp_password = secret_client.get_secret("fabric-sp-password").value
fabric_workspace_id = secret_client.get_secret("fabric-workspace-id").value

# Authenticate service principal
credential = ClientSecretCredential(
    tenant_id="your-tenant-id",
    client_id=fabric_sp_id,
    client_secret=fabric_sp_password
)

# Get Fabric token
token = credential.get_token("https://analysis.windows.net/powerbi/api")

# Verify workspace access
headers = {"Authorization": f"Bearer {token.token}"}
response = requests.get(
    f"https://api.powerbi.com/v1.0/myorg/groups/{fabric_workspace_id}",
    headers=headers
)

if response.status_code == 200:
    print("✓ Fabric workspace access verified")
    print(f"Workspace: {response.json()['name']}")
else:
    print(f"✗ Access failed: {response.status_code}")
    print(response.text)
```

### Fabric Workspace Role Matrix

| Role | Permissions | Use Case |
|------|-------------|----------|
| **Admin** | Full control, user/role management | Workspace owner, infrastructure automation |
| **Member** | Create/edit/delete items, share | Data engineers, analysts building reports |
| **Contributor** | Create/edit items | Service principals automating data pipelines |
| **Viewer** | Read-only access | BI consumers, auditors, cross-org stakeholders |

---

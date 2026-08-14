## Azure Key Vault Provisioning

Secure secret storage and automatic rotation for application credentials.

### Key Vault Creation

```bash
# Create Key Vault
KEYVAULT_NAME="kv-$(openssl rand -hex 4)"
RESOURCE_GROUP="rg-secrets"

az keyvault create \
  --name "$KEYVAULT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "eastus" \
  --enable-rbac-authorization true \
  --public-network-access Enabled
```

### RBAC Configuration for CI/CD

```bash
# Grant service principal access to Key Vault secrets
SERVICE_PRINCIPAL_ID=$(az ad sp show --id $APP_ID --query id -o tsv)

# Assign Key Vault Secrets Officer role
az role assignment create \
  --role "Key Vault Secrets Officer" \
  --assignee-object-id "$SERVICE_PRINCIPAL_ID" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME"
```

### Bicep Template for Key Vault

```bicep
param keyVaultName string
param location string = resourceGroup().location
param tenantId string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
```

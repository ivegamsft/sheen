## Terraform and Bicep State Storage Configuration

Centralized state management ensures consistent infrastructure deployments across environments.

### Storage Account Setup

```bash
# Create resource group for state management
RESOURCE_GROUP="rg-terraform-state"
LOCATION="eastus"

az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

# Create storage account
STORAGE_ACCOUNT="tfstate$(date +%s)"

az storage account create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$STORAGE_ACCOUNT" \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2
```

### Storage Container and Backend Configuration

```bash
# Create blob container
az storage container create \
  --name "terraform-state" \
  --account-name "$STORAGE_ACCOUNT" \
  --public-access off

# Enable versioning for state recovery
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --enable-versioning
```

Bicep template for Terraform backend:

```bicep
param storageAccountName string
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    httpsTrafficOnlyEnabled: true
    minimumTlsVersion: 'TLS1_2'
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 30
    }
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  parent: blobServices
  name: 'terraform-state'
  properties: {
    publicAccess: 'None'
  }
}

output storageAccountId string = storageAccount.id
output containerName string = container.name
```

## Managed Identity

### Enable System-Assigned Managed Identity

Configure a system-assigned managed identity:

```bash
az containerapp identity assign \
  --name myapp \
  --resource-group myResourceGroup \
  --system-assigned
```

### Grant Permissions to Managed Identity

Assign role to the managed identity for Azure resources:

```bash
PRINCIPAL_ID=$(az containerapp identity show \
  --name myapp \
  --resource-group myResourceGroup \
  --query principalId -o tsv)

az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.KeyVault/vaults/<vault-name>
```

### Grant AcrPull to System-Assigned Identity

Allow the container app to pull images from ACR without stored credentials. Enable the system-assigned identity first if not already done:

```bash
# Enable system-assigned managed identity (if not already enabled)
az containerapp identity assign \
  --name myapp \
  --resource-group myResourceGroup \
  --system-assigned

PRINCIPAL_ID=$(az containerapp identity show \
  --name myapp \
  --resource-group myResourceGroup \
  --query principalId -o tsv)

ACR_ID=$(az acr show --name myregistry --query id -o tsv)

az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role AcrPull \
  --scope $ACR_ID

# Update the app to use system-assigned identity for the registry
az containerapp registry set \
  --name myapp \
  --resource-group myResourceGroup \
  --server myregistry.azurecr.io \
  --identity system
```

### Access Azure Key Vault

Use managed identity to securely access Key Vault secrets:

```bash
az containerapp secrets set \
  --name myapp \
  --resource-group myResourceGroup \
  --secrets keyvault-secret=keyvault-ref
```

## Troubleshooting

### OIDC Token Exchange Failures

```powershell
# Verify federated credential configuration
$appId = "your-app-id"
az ad app federated-credential list --id $appId

# Check service principal role assignments
$spId = az ad sp show --id $appId --query id -o tsv
az role assignment list --assignee-object-id $spId
```

### State Storage Access Issues

```bash
# Verify storage account access
az storage account show-connection-string --name $STORAGE_ACCOUNT

# Check container permissions
az storage container exists --name terraform-state --account-name $STORAGE_ACCOUNT
```

### Key Vault Access Denied

```bash
# Review role assignments
az role assignment list \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME"

# Grant additional permissions if needed
az role assignment create \
  --role "Key Vault Administrator" \
  --assignee-object-id $PRINCIPAL_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME"
```

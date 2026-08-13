## Deployment Patterns

### Basic Container Deployment

Deploy a simple container image to Azure Container Apps:

```bash
az containerapp create \
  --name myapp \
  --resource-group myResourceGroup \
  --image myregistry.azurecr.io/myapp:latest \
  --environment myEnvironment \
  --ingress external \
  --target-port 8080
```

### Using Azure Container Registry with Managed Identity

Pull images from ACR using a user-assigned managed identity (preferred over credentials):

```bash
# Create user-assigned managed identity
az identity create \
  --name myapp-identity \
  --resource-group myResourceGroup

# Retrieve identity resource ID and client ID in a single call
IDENTITY_ID=$(az identity show \
  --name myapp-identity \
  --resource-group myResourceGroup \
  --query id -o tsv)

IDENTITY_CLIENT_ID=$(az identity show \
  --name myapp-identity \
  --resource-group myResourceGroup \
  --query clientId -o tsv)

# Grant AcrPull role to the identity on the registry
ACR_ID=$(az acr show --name myregistry --query id -o tsv)
az role assignment create \
  --assignee $IDENTITY_CLIENT_ID \
  --role AcrPull \
  --scope $ACR_ID

# Create container app with managed identity for ACR
az containerapp create \
  --name myapp \
  --resource-group myResourceGroup \
  --image myregistry.azurecr.io/myapp:latest \
  --environment myEnvironment \
  --user-assigned $IDENTITY_ID \
  --registry-server myregistry.azurecr.io \
  --registry-identity $IDENTITY_ID \
  --ingress external \
  --target-port 8080
```

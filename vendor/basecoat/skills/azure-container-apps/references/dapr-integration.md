## Dapr Integration

### Enable Dapr for a Container App

Enable Dapr sidecar with specific components:

```bash
az containerapp create \
  --name myapp \
  --resource-group myResourceGroup \
  --image myregistry.azurecr.io/myapp:latest \
  --environment myEnvironment \
  --dapr-enabled true \
  --dapr-app-id myapp \
  --dapr-app-port 8080 \
  --ingress external \
  --target-port 8080
```

### State Management Component

Define a Dapr state store component:

```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore
spec:
  type: state.azure.cosmosdb
  version: v1
  metadata:
  - name: url
    value: "https://myaccount.documents.azure.com:443/"
  - name: masterKey
    secretRef: cosmosdb-master-key
  - name: databaseName
    value: mydb
  - name: collectionName
    value: mycollection
```

### Using Dapr with Container Apps

Create and apply a Dapr component in Azure Container Apps:

```bash
az containerapp env dapr-component set \
  --name myComponent \
  --environment myEnvironment \
  --resource-group myResourceGroup \
  --yaml @component.yaml
```

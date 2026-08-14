## Multi-Container Environments

### Environment Setup

Create a Container Apps Environment for hosting multiple apps:

```bash
az containerapp env create \
  --name myEnvironment \
  --resource-group myResourceGroup \
  --location eastus \
  --logs-workspace-id <workspace-id> \
  --logs-workspace-key <workspace-key>
```

### Internal Communication Between Apps

Enable apps to communicate within the same environment:

```bash
az containerapp create \
  --name frontend \
  --resource-group myResourceGroup \
  --image myregistry.azurecr.io/frontend:latest \
  --environment myEnvironment \
  --ingress external \
  --target-port 3000

az containerapp create \
  --name backend \
  --resource-group myResourceGroup \
  --image myregistry.azurecr.io/backend:latest \
  --environment myEnvironment \
  --ingress internal \
  --target-port 8080
```

The frontend can reach the backend using the internal DNS name `http://backend` within the environment.

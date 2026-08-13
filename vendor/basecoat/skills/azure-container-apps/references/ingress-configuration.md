## Ingress Configuration

### External Ingress with TLS

Configure external ingress with automatic TLS certificate:

```bash
az containerapp create \
  --name myapp \
  --resource-group myResourceGroup \
  --image myregistry.azurecr.io/myapp:latest \
  --environment myEnvironment \
  --ingress external \
  --target-port 8080 \
  --exposed-port 443
```

### Internal Ingress

Create an internal container app accessible only within the environment:

```bash
az containerapp create \
  --name myapp \
  --resource-group myResourceGroup \
  --image myregistry.azurecr.io/myapp:latest \
  --environment myEnvironment \
  --ingress internal \
  --target-port 8080
```

### Custom Domain and SSL

Bind a custom domain to your container app:

```bash
az containerapp hostname add \
  --name myapp \
  --resource-group myResourceGroup \
  --hostname mycustom.domain.com \
  --bind-mount-path /path/to/cert \
  --cert-file /path/to/cert.pfx \
  --cert-password <password>
```

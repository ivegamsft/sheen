# Container Migration — Workflow

## 1. Generate Multi-Stage Dockerfile

Produce a two-stage Dockerfile: a **build** stage that compiles or installs
dependencies, and a **runtime** stage that copies only the necessary artifacts.

Key requirements for the runtime stage:

- Run as a non-root user (`appuser`) — never `root`
- Install a SIGTERM handler so the process exits cleanly on container stop
- `EXPOSE {port}` matches the `port` input
- Add a `HEALTHCHECK` instruction pointing to `/healthz`

Example skeleton (dotnet):

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
RUN adduser --disabled-password --gecos "" appuser
COPY --from=build /app/publish .
USER appuser
EXPOSE <port>
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:<port>/healthz || exit 1
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

## 2. Generate `/healthz` Endpoint Stub

Add a lightweight health probe route — returns HTTP 200 with no authentication required.

**dotnet (minimal API):**

```csharp
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy" }))
   .AllowAnonymous();
```

**python (Flask):**

```python
@app.route("/healthz")
def healthz():
    return {"status": "healthy"}, 200
```

**java (Spring Boot):**

```java
@GetMapping("/healthz")
public ResponseEntity<Map<String, String>> healthz() {
    return ResponseEntity.ok(Map.of("status", "healthy"));
}
```

**node (Express):**

```javascript
app.get('/healthz', (req, res) => res.json({ status: 'healthy' }));
```

**ruby (Rails):**

```ruby
get '/healthz', to: proc { [200, {}, [{ status: 'healthy' }.to_json]] }
```

## 3. Generate ACR Push/Pull GitHub Actions Workflow

Create `.github/workflows/container-build-push.yml` using OIDC federated credentials
(no stored secrets). Tag the image with `${{ github.sha }}` — never `:latest`.

```yaml
name: Build and push container image

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  build-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Log in to ACR
        run: az acr login --name ${{ vars.ACR_NAME }}

      - uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ vars.ACR_NAME }}.azurecr.io/${{ vars.IMAGE_NAME }}:${{ github.sha }}
```

## 4. If target = aca — Generate Bicep Module

Create `infra/container-app.bicep` with a `containerApp` resource:

- System-assigned managed identity (when `managed_identity = true`)
- Ingress on the configured `port`, `external: true`
- Configurable `minReplicas` / `maxReplicas`
- Image tagged with the deployment SHA (pass as parameter)

```bicep
param appName string
param location string = resourceGroup().location
param containerImage string
param port int
param minReplicas int = 1
param maxReplicas int = 3

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: appName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    configuration: {
      ingress: {
        external: true
        targetPort: port
      }
    }
    template: {
      containers: [
        {
          name: appName
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}
```

## 5. If target = aks — Generate Kubernetes Manifests

Create `k8s/deployment.yaml` and `k8s/service.yaml`.

The Deployment must include:

- `readinessProbe` and `livenessProbe` on `/healthz`
- CPU and memory `requests` and `limits`
- `securityContext` with `runAsNonRoot: true`

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <app_name>
spec:
  replicas: 2
  selector:
    matchLabels:
      app: <app_name>
  template:
    metadata:
      labels:
        app: <app_name>
    spec:
      securityContext:
        runAsNonRoot: true
      containers:
        - name: <app_name>
          image: <acr>.azurecr.io/<image>:<sha>
          ports:
            - containerPort: <port>
          resources:
            requests:
              cpu: 250m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
          readinessProbe:
            httpGet:
              path: /healthz
              port: <port>
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /healthz
              port: <port>
            initialDelaySeconds: 15
            periodSeconds: 20
```

```yaml
# k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: <app_name>
spec:
  type: ClusterIP
  selector:
    app: <app_name>
  ports:
    - port: 80
      targetPort: <port>
```

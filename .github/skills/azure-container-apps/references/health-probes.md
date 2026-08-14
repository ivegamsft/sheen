## Health Probes

### Liveness Probe

Restart a container when it becomes unresponsive:

```bash
az containerapp create \
  --name myapp \
  --resource-group myResourceGroup \
  --image myregistry.azurecr.io/myapp:latest \
  --environment myEnvironment \
  --ingress external \
  --target-port 8080 \
  --liveness-probe-path /health/live \
  --liveness-probe-period 10 \
  --liveness-probe-threshold 3
```

### Readiness Probe

Delay traffic until the container is ready to serve requests:

```bash
az containerapp create \
  --name myapp \
  --resource-group myResourceGroup \
  --image myregistry.azurecr.io/myapp:latest \
  --environment myEnvironment \
  --ingress external \
  --target-port 8080 \
  --readiness-probe-path /health/ready \
  --readiness-probe-period 5 \
  --readiness-probe-threshold 2
```

### Health Probes via YAML

Define all three probe types (liveness, readiness, startup) in a container app YAML spec:

```yaml
properties:
  template:
    containers:
      - name: myapp
        image: myregistry.azurecr.io/myapp:latest
        probes:
          - type: liveness
            httpGet:
              path: /health/live
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
            failureThreshold: 3
          - type: readiness
            httpGet:
              path: /health/ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 2
          - type: startup
            httpGet:
              path: /health/startup
              port: 8080
            initialDelaySeconds: 0
            periodSeconds: 10
            failureThreshold: 30
```

Apply the YAML spec to an existing container app:

```bash
az containerapp update \
  --name myapp \
  --resource-group myResourceGroup \
  --yaml @containerapp.yaml
```

### Health Probes in Bicep

Embed probe definitions directly in a Bicep template:

```bicep
param containerAppName string
param containerImage string
param environmentName string
param location string = resourceGroup().location

resource containerEnv 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: environmentName
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerEnv.id
    template: {
      containers: [
        {
          name: containerAppName
          image: containerImage
          probes: [
            {
              type: 'liveness'
              httpGet: {
                path: '/health/live'
                port: 8080
              }
              initialDelaySeconds: 10
              periodSeconds: 10
              failureThreshold: 3
            }
            {
              type: 'readiness'
              httpGet: {
                path: '/health/ready'
                port: 8080
              }
              initialDelaySeconds: 5
              periodSeconds: 5
              failureThreshold: 2
            }
            {
              type: 'startup'
              httpGet: {
                path: '/health/startup'
                port: 8080
              }
              initialDelaySeconds: 0
              periodSeconds: 10
              failureThreshold: 30
            }
          ]
        }
      ]
    }
  }
}
```

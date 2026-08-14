## Scaling Rules

### HTTP-Based Scaling

Configure HTTP request-based scaling rules:

```bash
az containerapp create \
  --name myapp \
  --resource-group myResourceGroup \
  --image myregistry.azurecr.io/myapp:latest \
  --environment myEnvironment \
  --min-replicas 2 \
  --max-replicas 10 \
  --ingress external \
  --target-port 8080
```

### KEDA Scaling Rules

Define scaling based on custom metrics using KEDA:

```yaml
apiVersion: apps/containerapp.io/v1alpha1
kind: ContainerApp
metadata:
  name: myapp
spec:
  template:
    scale:
      minReplicas: 1
      maxReplicas: 10
      rules:
      - name: http-rule
        http:
          metadata:
            concurrentRequests: "50"
      - name: custom-metric
        custom:
          type: azure-queue
          metadata:
            connection: AzureStorageConnectionString
            queueName: myqueue
            queueLength: "10"
```

### Azure Event Hub Scaling

Scale based on Event Hub throughput:

```yaml
apiVersion: apps/containerapp.io/v1alpha1
kind: ContainerApp
metadata:
  name: myapp
spec:
  template:
    scale:
      rules:
      - name: eventhub-scaler
        custom:
          type: azure-eventhub
          metadata:
            storageConnectionString: "connection-string"
            storageContainerName: "container"
            eventHubName: "myeventhub"
            consumerGroup: "myconsumergroup"
            unprocessedEventThreshold: "30"
```

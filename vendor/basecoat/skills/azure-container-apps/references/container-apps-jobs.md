## Azure Container Apps Jobs

### Create a Job

Deploy a long-running or batch job:

```bash
az containerapp job create \
  --name myjob \
  --resource-group myResourceGroup \
  --environment myEnvironment \
  --trigger-type schedule \
  --cron-expression "0 0 * * *" \
  --image myregistry.azurecr.io/myjob:latest \
  --cpu 0.5 \
  --memory 1Gi
```

### Event-Driven Job

Create a job triggered by external events:

```bash
az containerapp job create \
  --name eventjob \
  --resource-group myResourceGroup \
  --environment myEnvironment \
  --trigger-type event \
  --replica-completion-count 1 \
  --image myregistry.azurecr.io/eventjob:latest
```

### Scale Job Executions

Configure scaling for job executions:

```bash
az containerapp job create \
  --name scalablejob \
  --resource-group myResourceGroup \
  --environment myEnvironment \
  --trigger-type event \
  --min-executions 0 \
  --max-executions 10 \
  --image myregistry.azurecr.io/scalablejob:latest
```

## Revision Management

### Create a New Revision

Update a container app to create a new revision automatically:

```bash
az containerapp update \
  --name myapp \
  --resource-group myResourceGroup \
  --image myregistry.azurecr.io/myapp:v2.0 \
  --set-env-vars VERSION=2.0
```

### Traffic Splitting Between Revisions

Route traffic across multiple revisions for blue-green deployment:

```bash
az containerapp revision set-traffic \
  --name myapp \
  --resource-group myResourceGroup \
  --traffic-weight myapp--1=70 myapp--2=30
```

### List and Manage Revisions

View all revisions of a container app:

```bash
az containerapp revision list \
  --name myapp \
  --resource-group myResourceGroup \
  --query "[].{Name:name, Active:properties.active, CreatedTime:properties.createdTime}"
```

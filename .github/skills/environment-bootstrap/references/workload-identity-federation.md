## Workload Identity Federation

Enable pod-level authentication in AKS using Azure Workload Identity.

### Prerequisites for AKS

- Azure Kubernetes Service cluster
- Azure CLI and kubectl configured

### Setup Steps

```bash
# Create namespace for workload identity
kubectl create namespace workload-identity

# Create Kubernetes service account
kubectl create serviceaccount workload-identity-sa -n workload-identity

# Export OIDC issuer URL
export AKS_OIDC_ISSUER=$(az aks show \
  --name myAKSCluster \
  --resource-group myResourceGroup \
  --query "oidcIssuerProfile.issuerUrl" -o tsv)

# Create Entra ID application for AKS workload
az ad app create --display-name "aks-workload-identity"
```

### Federated Credential for AKS Pod

```bash
# Get Kubernetes service account info
KUBE_NAMESPACE="workload-identity"
KUBE_SERVICE_ACCOUNT="workload-identity-sa"
KUBE_SERVICE_ACCOUNT_EMAIL="$KUBE_SERVICE_ACCOUNT@$AKS_CLUSTER_NAME.iam.gke.google.com"

# Create federated credential
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "kubernetes-workload",
    "issuer": "'$AKS_OIDC_ISSUER'",
    "subject": "system:serviceaccount:'$KUBE_NAMESPACE':'$KUBE_SERVICE_ACCOUNT'",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Deploy Workload with Identity

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-identity-sa
  namespace: workload-identity
  annotations:
    azure.workload.identity/client-id: <APPLICATION_CLIENT_ID>

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: workload-identity-app
  namespace: workload-identity
spec:
  replicas: 1
  selector:
    matchLabels:
      app: workload-identity-app
  template:
    metadata:
      labels:
        app: workload-identity-app
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: workload-identity-sa
      containers:
      - name: app
        image: myregistry.azurecr.io/myapp:latest
        env:
        - name: AZURE_TENANT_ID
          value: "<TENANT_ID>"
        - name: AZURE_CLIENT_ID
          value: "<CLIENT_ID>"
```

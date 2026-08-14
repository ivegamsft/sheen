# Workload Identity Federation Template

Use this template to configure workload identity federation between an external identity provider (such as GitHub Actions) and Azure Entra ID. Workload identity federation eliminates the need for long-lived credentials by trusting tokens issued by the external IdP.

## Instructions

1. Create an app registration or user-assigned managed identity in Entra ID.
2. Add federated identity credentials for each environment or workflow that requires access.
3. Assign the required RBAC roles to the service principal or managed identity.
4. Configure the CI/CD workflow to request an OIDC token and exchange it for an Azure access token.
5. Never store Azure credentials in CI/CD secrets when workload identity federation is available.

---

## Federation Overview

**Workload:** _[name]_
**External IdP:** _[GitHub Actions | GitLab CI | Kubernetes | Other]_
**Azure App Registration / Managed Identity:** _[name]_
**Tenant ID:** _[tenant ID]_
**Subscription ID:** _[subscription ID]_
**Date:** _[YYYY-MM-DD]_
**Author:** _[name or agent]_

---

## Federated Identity Credentials

Define one federated credential per environment or subject claim that requires Azure access.

| # | Name | Issuer | Subject | Audience | Environment / Branch | Purpose |
|---|---|---|---|---|---|---|
| 1 | `github-prod` | `https://token.actions.githubusercontent.com` | `repo:<org>/<repo>:environment:production` | `api://AzureADTokenExchange` | production | Deploy to production |
| 2 | `github-staging` | `https://token.actions.githubusercontent.com` | `repo:<org>/<repo>:environment:staging` | `api://AzureADTokenExchange` | staging | Deploy to staging |
| 3 | `github-pr` | `https://token.actions.githubusercontent.com` | `repo:<org>/<repo>:pull_request` | `api://AzureADTokenExchange` | PR | Read-only validation |

### Subject Claim Formats (GitHub Actions)

| Trigger | Subject Claim Format |
|---|---|
| Environment deployment | `repo:<org>/<repo>:environment:<environment-name>` |
| Branch push | `repo:<org>/<repo>:ref:refs/heads/<branch>` |
| Pull request | `repo:<org>/<repo>:pull_request` |
| Tag push | `repo:<org>/<repo>:ref:refs/tags/<tag>` |

---

## RBAC Assignments

| Service Principal / Managed Identity | Role | Scope | Justification |
|---|---|---|---|
| | Contributor / Reader / Custom | Subscription / Resource Group / Resource | |

---

## Azure CLI Setup

```bash
# Step 1 — Create app registration (or use user-assigned managed identity)
APP_ID=$(az ad app create \
  --display-name "sp-myworkload-github" \
  --query appId -o tsv)

SP_OBJECT_ID=$(az ad sp create \
  --id $APP_ID \
  --query id -o tsv)

# Step 2 — Add federated credential for production environment
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-prod",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<org>/<repo>:environment:production",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Step 3 — Assign RBAC role
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Contributor" \
  --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group>
```

---

## Bicep Snippet — Federated Identity Credential

```bicep
resource appRegistrationFederation 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: 'github-prod'
  parent: userAssignedIdentity
  properties: {
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:<org>/<repo>:environment:production'
    audiences: [
      'api://AzureADTokenExchange'
    ]
  }
}
```

---

## GitHub Actions Workflow Snippet

```yaml
permissions:
  id-token: write   # Required for OIDC token request
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4

      - name: Azure login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy
        run: |
          az deployment group create \
            --resource-group my-rg \
            --template-file infra/main.bicep
```

### Required GitHub Secrets

| Secret | Value | Notes |
|---|---|---|
| `AZURE_CLIENT_ID` | App registration client ID | Not a credential — safe to store as plain secret |
| `AZURE_TENANT_ID` | Entra ID tenant ID | Not a credential — safe to store as plain secret |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | Not a credential — safe to store as plain secret |

> No `AZURE_CLIENT_SECRET` is required when using workload identity federation.

---

## Kubernetes / AKS Federated Credential (Service Account Token)

```bash
# Federated credential subject for AKS workload identity
# Format: system:serviceaccount:<namespace>:<service-account-name>
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "aks-prod",
    "issuer": "https://oidc.prod.aks.azure.com/<cluster-oidc-issuer>",
    "subject": "system:serviceaccount:<namespace>:<service-account-name>",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

---

**Federated Credentials Configured:** ___ | **RBAC Assignments:** ___ | **Long-lived Credentials Eliminated:** ___

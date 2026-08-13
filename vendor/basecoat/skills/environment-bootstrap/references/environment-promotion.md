## Environment Promotion

Establish a structured promotion path from development through production with approval gates.

### Multi-Environment Architecture

```text
Development → Staging → Production
    ↓            ↓           ↓
   Auto         Auto      Manual Approval
  Deploy       Deploy     Required
```

### Environment Configuration

```yaml
environments:
  dev:
    resource-group: rg-basecoat-dev
    location: eastus
    sku: Standard_B2s
    auto-deploy: true

  staging:
    resource-group: rg-basecoat-staging
    location: eastus2
    sku: Standard_D2s_v3
    auto-deploy: true
    requires-approval: false

  prod:
    resource-group: rg-basecoat-prod
    location: eastus
    sku: Standard_D4s_v3
    auto-deploy: false
    requires-approval: true
    approval-team: infrastructure-team
```

### GitHub Environments Configuration

```yaml
name: Multi-Environment Deployment

on:
  push:
    branches:
      - main

jobs:
  deploy-dev:
    runs-on: ubuntu-latest
    environment: development
    steps:
      - uses: actions/checkout@v3
      - run: az deployment group create --resource-group rg-basecoat-dev --template-file main.bicep

  deploy-staging:
    needs: deploy-dev
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v3
      - run: az deployment group create --resource-group rg-basecoat-staging --template-file main.bicep

  deploy-prod:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v3
      - run: az deployment group create --resource-group rg-basecoat-prod --template-file main.bicep
```

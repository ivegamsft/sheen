# Managed Identity Mapping Template

Use this template to catalogue all managed identities used by a workload. Each entry documents the identity type, the Azure resource it is assigned to, and the RBAC roles it holds.

## Instructions

1. Prefer system-assigned managed identities for single-resource workloads with no sharing requirement.
2. Use user-assigned managed identities when the same identity must be shared across multiple resources, or when the identity must survive resource recreation.
3. Never use service principal credentials (client secrets or certificates) when a managed identity is available.
4. Document every RBAC role granted to each managed identity — reference the RBAC Role Assignment Matrix for full scope details.

---

## Workload Overview

**Workload:** _[name]_
**Environment:** _[dev | staging | production]_
**Subscription:** _[subscription name or ID]_
**Date:** _[YYYY-MM-DD]_
**Author:** _[name or agent]_

---

## System-Assigned Managed Identities

| # | Resource Name | Resource Type | Resource Group | Principal ID | Roles Granted | Target Resources |
|---|---|---|---|---|---|---|
| 1 | | App Service / AKS / Container App / VM / Function | | _[populated after creation]_ | | |
| 2 | | | | | | |

---

## User-Assigned Managed Identities

| # | Identity Name | Resource Group | Client ID | Principal ID | Assigned To Resources | Roles Granted | Sharing Justification |
|---|---|---|---|---|---|---|---|
| 1 | | | _[populated after creation]_ | _[populated after creation]_ | | | |
| 2 | | | | | | | |

---

## Key Vault Access via Managed Identity

| Identity | Key Vault Name | Secret / Key / Certificate | Access Policy or RBAC Role |
|---|---|---|---|
| | | | Key Vault Secrets User / Key Vault Reader |

---

## Bicep Snippet — System-Assigned Identity

```bicep
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: 'my-app-service'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // ... other properties
  }
}

// Assign Key Vault Secrets User to the system-assigned identity
resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, appService.identity.principalId, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    principalId: appService.identity.principalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    )
    principalType: 'ServicePrincipal'
  }
}
```

## Bicep Snippet — User-Assigned Identity

```bicep
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-myworkload-prod'
  location: resourceGroup().location
}

resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: 'my-app-service'
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    // ... other properties
  }
}
```

---

**System-Assigned Count:** ___ | **User-Assigned Count:** ___ | **Key Vault Integrations:** ___

# RBAC Role Assignment Matrix

Use this template to document all Azure RBAC assignments for a workload or system. Each row maps a principal (user, group, service principal, or managed identity) to a role at a specific scope.

## Instructions

1. Identify all principals that require access to Azure resources.
2. Apply least-privilege: assign the narrowest built-in role that satisfies the requirement. Define a custom role only when no built-in role fits.
3. Prefer resource-group or resource scope over subscription scope.
4. Document the business justification for every assignment.
5. Flag assignments that require Privileged Identity Management (PIM) for just-in-time activation.

---

## Workload Overview

**Workload:** _[name]_
**Environment:** _[dev | staging | production]_
**Subscription:** _[subscription name or ID]_
**Date:** _[YYYY-MM-DD]_
**Author:** _[name or agent]_

---

## Role Assignment Matrix

| # | Principal | Principal Type | Role | Scope Level | Scope Resource | PIM Required | Justification |
|---|---|---|---|---|---|---|---|
| 1 | | User / Group / SP / Managed Identity | | Subscription / Resource Group / Resource | | Yes / No | |
| 2 | | | | | | | |
| 3 | | | | | | | |

**Scope Level options:** Subscription · Resource Group · Resource

---

## Custom Role Definitions

Complete this section only when no built-in role satisfies the requirement.

### Custom Role: _[role name]_

**Description:** _[what this role allows]_

**Actions:**

```json
{
  "Name": "[Role Name]",
  "Description": "[Role description]",
  "Actions": [
    "Microsoft.<provider>/<resource>/<action>"
  ],
  "NotActions": [],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": [
    "/subscriptions/<subscription-id>"
  ]
}
```

**Justification:** _[why no built-in role is sufficient]_

---

## Privileged Identity Management (PIM) Summary

List all assignments that use PIM for just-in-time activation.

| Principal | Role | Scope | Max Activation Duration | Approval Required | Approvers |
|---|---|---|---|---|---|
| | | | | Yes / No | |

---

## Stale Assignment Review

| Principal | Role | Scope | Last Used | Action Required |
|---|---|---|---|---|
| | | | _[date or never]_ | Keep / Revoke / Downgrade |

---

## Bicep Snippet — Role Assignment

```bicep
param principalId string
param roleDefinitionId string = 'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader (built-in)
param resourceGroupName string = resourceGroup().name

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionId)
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalType: 'ServicePrincipal' // User | Group | ServicePrincipal
  }
}
```

---

**Total Assignments:** ___ | **Custom Roles:** ___ | **PIM-Gated:** ___

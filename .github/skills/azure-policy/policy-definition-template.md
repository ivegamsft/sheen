# Custom Azure Policy Definition Template

Use this template to author a custom Azure Policy definition. Fill in every placeholder before deploying. Store the resulting JSON file in source control alongside an `initiative-definition-template.md` when bundling multiple controls.

## Metadata

| Field | Value |
|---|---|
| **Policy Name** | _[short-kebab-case-name]_ |
| **Display Name** | _[Human-readable control title]_ |
| **Category** | _[e.g., Tagging / Compute / Network / Storage / Security Center]_ |
| **Effect** | _[Deny \| Audit \| AuditIfNotExists \| Modify \| DeployIfNotExists]_ |
| **Version** | _[1.0.0]_ |
| **Owner** | _[team or role]_ |
| **Framework Mappings** | _[CIS X.X / NIST 800-53 XX-X / ISO 27001 A.X.X]_ |

---

## Effect Selection Guide

| Effect | Use When |
|---|---|
| `Deny` | The resource configuration must never be allowed (e.g., public blob access). |
| `Audit` | The configuration is non-preferred but not blocked; used during burn-in. |
| `AuditIfNotExists` | A related resource (e.g., diagnostic setting) must exist alongside the evaluated resource. |
| `Modify` | Automatically add or replace a tag or property on the resource at create or update time. |
| `DeployIfNotExists` | Deploy a companion resource (e.g., diagnostic extension) when it is missing. Use `remediation-task-template.md`. |

---

## Policy Definition JSON

```json
{
  "name": "[short-kebab-case-name]",
  "type": "Microsoft.Authorization/policyDefinitions",
  "properties": {
    "displayName": "[Human-readable control title]",
    "description": "[Explain what this policy enforces and why. Include the business or security rationale.]",
    "policyType": "Custom",
    "mode": "Indexed",
    "metadata": {
      "version": "1.0.0",
      "category": "[Category]",
      "owner": "[team-or-role]",
      "frameworkMappings": {
        "CIS": "[e.g., 6.1]",
        "NIST_800_53": "[e.g., SC-28]",
        "ISO_27001": "[e.g., A.10.1.1]"
      }
    },
    "parameters": {
      "effect": {
        "type": "String",
        "metadata": {
          "displayName": "Effect",
          "description": "Enable or disable the execution of the policy."
        },
        "allowedValues": [
          "Deny",
          "Audit",
          "Disabled"
        ],
        "defaultValue": "Audit"
      }
    },
    "policyRule": {
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "[Resource type — e.g., Microsoft.Storage/storageAccounts]"
          },
          {
            "field": "[Property path — e.g., properties.allowBlobPublicAccess]",
            "equals": "[Condition value — e.g., true]"
          }
        ]
      },
      "then": {
        "effect": "[parameters('effect')]"
      }
    }
  }
}
```

---

## Common Policy Rule Patterns

### Require a specific tag

```json
{
  "if": {
    "not": {
      "field": "tags['[TagName]']",
      "exists": "true"
    }
  },
  "then": {
    "effect": "[parameters('effect')]"
  }
}
```

### Restrict allowed locations

```json
{
  "if": {
    "not": {
      "field": "location",
      "in": "[parameters('allowedLocations')]"
    }
  },
  "then": {
    "effect": "[parameters('effect')]"
  }
}
```

### Restrict VM SKUs

```json
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Compute/virtualMachines"
      },
      {
        "not": {
          "field": "Microsoft.Compute/virtualMachines/sku.name",
          "in": "[parameters('allowedSKUs')]"
        }
      }
    ]
  },
  "then": {
    "effect": "[parameters('effect')]"
  }
}
```

### Require encryption at rest (Storage)

```json
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Storage/storageAccounts"
      },
      {
        "field": "Microsoft.Storage/storageAccounts/encryption.keySource",
        "notEquals": "Microsoft.Keyvault"
      }
    ]
  },
  "then": {
    "effect": "[parameters('effect')]"
  }
}
```

---

## Authoring Checklist

- [ ] `name` is lowercase, kebab-case, and unique within the management group or subscription
- [ ] `displayName` is human-readable and scoped (e.g., "Require tag: Environment on all resources")
- [ ] `description` explains the control rationale and remediation path
- [ ] `mode` is `Indexed` for resource-level policies or `All` for subscription and resource group policies
- [ ] `effect` is parameterized to allow initiative-level override
- [ ] At least one `frameworkMappings` entry is present
- [ ] `policyRule` has been tested against a non-production environment with `enforcementMode: DoNotEnforce`
- [ ] Version is set to `1.0.0` for new policies; increment on breaking changes

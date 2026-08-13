# Policy Initiative Definition Template

Use this template to bundle related custom (or built-in) Azure Policy definitions into a policy set (initiative). An initiative simplifies assignment and compliance tracking by grouping controls that address a common governance objective.

## Metadata

| Field | Value |
|---|---|
| **Initiative Name** | _[short-kebab-case-name]_ |
| **Display Name** | _[Human-readable initiative title]_ |
| **Category** | _[e.g., Tagging / Compute / Security / Regulatory Compliance]_ |
| **Version** | _[1.0.0]_ |
| **Owner** | _[team or role]_ |
| **Framework** | _[CIS Benchmark vX.X / NIST 800-53 Rev 5 / ISO 27001:2013]_ |
| **Scope** | _[Management Group / Subscription / Resource Group]_ |

---

## Initiative Definition JSON

```json
{
  "name": "[short-kebab-case-name]",
  "type": "Microsoft.Authorization/policySetDefinitions",
  "properties": {
    "displayName": "[Human-readable initiative title]",
    "description": "[Describe the governance objective this initiative addresses and the frameworks it maps to.]",
    "policyType": "Custom",
    "metadata": {
      "version": "1.0.0",
      "category": "[Category]",
      "owner": "[team-or-role]",
      "framework": "[e.g., CIS Microsoft Azure Foundations Benchmark v2.0.0]"
    },
    "parameters": {
      "effect": {
        "type": "String",
        "metadata": {
          "displayName": "Default Effect",
          "description": "Default effect applied to all policy definitions in this initiative that support an effect parameter."
        },
        "allowedValues": [
          "Audit",
          "Deny",
          "Disabled"
        ],
        "defaultValue": "Audit"
      },
      "allowedLocations": {
        "type": "Array",
        "metadata": {
          "displayName": "Allowed Locations",
          "description": "The list of locations that resource groups can be created in.",
          "strongType": "location"
        },
        "defaultValue": [
          "eastus",
          "westus2",
          "westeurope"
        ]
      }
    },
    "policyDefinitions": [
      {
        "policyDefinitionId": "/providers/Microsoft.Authorization/policyDefinitions/[built-in-policy-id]",
        "policyDefinitionReferenceId": "[unique-reference-id-1]",
        "parameters": {
          "effect": {
            "value": "[parameters('effect')]"
          }
        },
        "groupNames": [
          "[Group1]"
        ]
      },
      {
        "policyDefinitionId": "/subscriptions/[subscription-id]/providers/Microsoft.Authorization/policyDefinitions/[custom-policy-name]",
        "policyDefinitionReferenceId": "[unique-reference-id-2]",
        "parameters": {
          "effect": {
            "value": "[parameters('effect')]"
          },
          "allowedLocations": {
            "value": "[parameters('allowedLocations')]"
          }
        },
        "groupNames": [
          "[Group2]"
        ]
      }
    ],
    "policyDefinitionGroups": [
      {
        "name": "[Group1]",
        "displayName": "[Group display name — e.g., Identity and Access Management]",
        "description": "[What this group of controls addresses]",
        "additionalMetadataId": "/providers/Microsoft.PolicyInsights/policyMetadata/[metadata-resource-id]"
      },
      {
        "name": "[Group2]",
        "displayName": "[Group display name — e.g., Network Security]",
        "description": "[What this group of controls addresses]"
      }
    ]
  }
}
```

---

## Initiative Assignment JSON

Use this block to assign the initiative to a management group, subscription, or resource group.

```json
{
  "name": "[assignment-name]",
  "type": "Microsoft.Authorization/policyAssignments",
  "identity": {
    "type": "SystemAssigned"
  },
  "location": "[deployment-location]",
  "properties": {
    "displayName": "[Assignment display name]",
    "description": "[Scope and purpose of this assignment]",
    "policyDefinitionId": "/subscriptions/[subscription-id]/providers/Microsoft.Authorization/policySetDefinitions/[initiative-name]",
    "scope": "/subscriptions/[subscription-id]",
    "notScopes": [
      "/subscriptions/[subscription-id]/resourceGroups/[excluded-rg]"
    ],
    "parameters": {
      "effect": {
        "value": "Audit"
      },
      "allowedLocations": {
        "value": [
          "eastus",
          "westus2"
        ]
      }
    },
    "enforcementMode": "Default",
    "nonComplianceMessages": [
      {
        "message": "Resources must comply with the [initiative display name] initiative. Review the policy details and remediate non-compliant resources."
      }
    ]
  }
}
```

---

## Bicep Assignment (Alternative)

```bicep
param initiativeId string
param assignmentName string
param scope string = subscription().id
param allowedLocations array = ['eastus', 'westus2']

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: assignmentName
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: '[Initiative Display Name] Assignment'
    policyDefinitionId: initiativeId
    scope: scope
    parameters: {
      effect: {
        value: 'Audit'
      }
      allowedLocations: {
        value: allowedLocations
      }
    }
    enforcementMode: 'Default'
    nonComplianceMessages: [
      {
        message: 'Resource does not comply with governance initiative. Refer to the policy details for remediation steps.'
      }
    ]
  }
}

output assignmentId string = policyAssignment.id
output principalId string = policyAssignment.identity.principalId
```

---

## Initiative Authoring Checklist

- [ ] Each `policyDefinitionReferenceId` is unique within the initiative
- [ ] All custom policy definitions referenced exist in the target scope before deploying the initiative
- [ ] Shared parameters are defined at the initiative level with sensible defaults
- [ ] `policyDefinitionGroups` are used to organize controls by framework domain
- [ ] Non-compliance messages provide actionable guidance, not just policy identifiers
- [ ] `enforcementMode` is set to `DoNotEnforce` for initial rollout; switch to `Default` after burn-in
- [ ] Assignment identity (`SystemAssigned`) has been granted the minimum required roles for any `DeployIfNotExists` policies in the set
- [ ] Excluded scopes (`notScopes`) are documented with a rationale and review date

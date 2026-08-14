# Remediation Task Template

Use this template when authoring `DeployIfNotExists` or `Modify` Azure Policy definitions that require automated remediation. Complete the deployment template section and the managed identity role assignment before deploying to production.

## Metadata

| Field | Value |
|---|---|
| **Policy Name** | _[policy definition name this task remediates]_ |
| **Resource Type** | _[e.g., Microsoft.Compute/virtualMachines]_ |
| **Remediation Action** | _[e.g., Deploy diagnostic settings / Enable encryption / Add missing tag]_ |
| **Managed Identity Scope** | _[Subscription / Resource Group — use narrowest scope possible]_ |
| **Required Role** | _[e.g., Contributor / Log Analytics Contributor / Storage Account Contributor]_ |
| **Owner** | _[team or role]_ |

---

## DeployIfNotExists Policy Rule

The `DeployIfNotExists` effect requires an `existenceCondition` and an inner `deployment` block. The policy engine evaluates the `existenceCondition` against related resources; if no matching resource exists, the deployment is triggered.

```json
{
  "policyRule": {
    "if": {
      "field": "type",
      "equals": "[Resource type — e.g., Microsoft.Compute/virtualMachines]"
    },
    "then": {
      "effect": "[parameters('effect')]",
      "details": {
        "type": "[Related resource type — e.g., Microsoft.Insights/diagnosticSettings]",
        "name": "[Expected resource name — e.g., [field('name')]-diag]",
        "existenceCondition": {
          "allOf": [
            {
              "field": "[Property that confirms the related resource is correctly configured]",
              "equals": "[Expected value]"
            }
          ]
        },
        "roleDefinitionIds": [
          "/providers/Microsoft.Authorization/roleDefinitions/[role-definition-id]"
        ],
        "deployment": {
          "properties": {
            "mode": "incremental",
            "template": {
              "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
              "contentVersion": "1.0.0.0",
              "parameters": {
                "resourceName": {
                  "type": "string"
                },
                "resourceLocation": {
                  "type": "string"
                },
                "workspaceId": {
                  "type": "string"
                }
              },
              "resources": [
                {
                  "type": "[Related resource type — e.g., Microsoft.Insights/diagnosticSettings]",
                  "apiVersion": "[Latest stable API version]",
                  "name": "[[concat(parameters('resourceName'), '-diag')]",
                  "location": "[[parameters('resourceLocation')]",
                  "scope": "[[concat('[Resource provider namespace]/', parameters('resourceName'))]",
                  "properties": {
                    "workspaceId": "[[parameters('workspaceId')]",
                    "logs": [
                      {
                        "category": "[Log category]",
                        "enabled": true,
                        "retentionPolicy": {
                          "enabled": true,
                          "days": 90
                        }
                      }
                    ],
                    "metrics": [
                      {
                        "category": "AllMetrics",
                        "enabled": true,
                        "retentionPolicy": {
                          "enabled": true,
                          "days": 90
                        }
                      }
                    ]
                  }
                }
              ]
            },
            "parameters": {
              "resourceName": {
                "value": "[[field('name')]"
              },
              "resourceLocation": {
                "value": "[[field('location')]"
              },
              "workspaceId": {
                "value": "[[parameters('workspaceId')]"
              }
            }
          }
        }
      }
    }
  }
}
```

---

## Managed Identity Role Assignment

The policy assignment's managed identity must have the role specified in `roleDefinitionIds` before remediation tasks will succeed.

```json
{
  "type": "Microsoft.Authorization/roleAssignments",
  "apiVersion": "2022-04-01",
  "name": "[guid(policyAssignmentId, roleDefinitionId)]",
  "scope": "[assignment scope — e.g., subscription or resource group resource ID]",
  "properties": {
    "roleDefinitionId": "/providers/Microsoft.Authorization/roleDefinitions/[role-definition-id]",
    "principalId": "[managed identity principal ID from the policy assignment]",
    "principalType": "ServicePrincipal"
  }
}
```

### Common Role Definition IDs

| Role | GUID |
|---|---|
| Contributor | `b24988ac-6180-42a0-ab88-20f7382dd24c` |
| Log Analytics Contributor | `92aaf0da-9dab-42b6-94a3-d43ce8d16293` |
| Storage Account Contributor | `17d1049b-9a84-46fb-8f53-869881c3d3ab` |
| Monitoring Contributor | `749f88d5-cbae-40b8-bcfc-e573ddc772fa` |
| Key Vault Contributor | `f25e0fa2-a7c8-4377-a976-54943a77a395` |
| Network Contributor | `4d97b98b-1d4f-4787-a291-c67834d212e7` |
| Virtual Machine Contributor | `9980e02c-c2be-4d73-94e8-173b1dc7cf3c` |

---

## Remediation Task Trigger (Azure CLI)

After deploying and assigning a `DeployIfNotExists` policy, trigger a remediation task for existing non-compliant resources:

```bash
# Trigger remediation for all non-compliant resources under the assignment
az policy remediation create \
  --name "[remediation-task-name]" \
  --policy-assignment "[assignment-name]" \
  --resource-discovery-mode ExistingNonCompliant \
  --resource-group "[resource-group-name]"

# Check remediation task status
az policy remediation show \
  --name "[remediation-task-name]" \
  --resource-group "[resource-group-name]" \
  --query "{Status:properties.provisioningState, Succeeded:properties.deploymentSummary.successfulDeployments, Failed:properties.deploymentSummary.failedDeployments}"
```

---

## Remediation Task Bicep (Inline)

```bicep
resource remediationTask 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: '[remediation-task-name]'
  properties: {
    policyAssignmentId: '[policy-assignment-resource-id]'
    policyDefinitionReferenceId: '[policy-definition-reference-id-in-initiative]'
    resourceDiscoveryMode: 'ExistingNonCompliant'
    parallelDeployments: 10
    failureThreshold: {
      percentage: 0.1
    }
    filters: {
      locations: [
        '[location-1]'
        '[location-2]'
      ]
    }
  }
}
```

---

## Authoring Checklist

- [ ] `existenceCondition` accurately identifies correctly configured companion resources — overly broad conditions cause false compliance
- [ ] `roleDefinitionIds` uses the minimum role required, not `Owner` or `Contributor` at subscription scope unless justified
- [ ] Inner ARM deployment template is tested standalone before embedding in the policy rule
- [ ] ARM template uses `incremental` mode to avoid deleting existing sibling resources
- [ ] `parallelDeployments` is set to a safe value (≤ 10) for large-scale remediation to avoid resource provider throttling
- [ ] `failureThreshold.percentage` is set to halt remediation if the error rate exceeds an acceptable threshold
- [ ] Managed identity role assignment is deployed before the remediation task is triggered
- [ ] Remediation task outcome is reviewed in Azure Portal → Policy → Remediation before marking the control as compliant

# Compliance Report Template

Use this template to produce Azure Resource Graph and KQL (Log Analytics / Azure Monitor) queries for compliance dashboards and regulatory reporting. Populate the query placeholders with your policy assignment IDs, management group scopes, and framework control identifiers before running.

## Metadata

| Field | Value |
|---|---|
| **Report Title** | _[e.g., Monthly Azure Policy Compliance — NIST 800-53]_ |
| **Scope** | _[Management Group / Subscription / Resource Group]_ |
| **Framework** | _[CIS Benchmark vX.X / NIST 800-53 Rev 5 / ISO 27001:2013]_ |
| **Report Date** | _[YYYY-MM-DD]_ |
| **Owner** | _[team or role]_ |

---

## Azure Resource Graph Queries

Run these queries in Azure Resource Graph Explorer (`portal.azure.com → Resource Graph Explorer`) or via CLI.

### Overall Compliance Summary by Policy Assignment

```kusto
PolicyResources
| where type =~ 'microsoft.policyinsights/policystates'
| where properties.complianceState in ('NonCompliant', 'Compliant')
| summarize
    Total = count(),
    Compliant = countif(properties.complianceState == 'Compliant'),
    NonCompliant = countif(properties.complianceState == 'NonCompliant')
    by PolicyAssignmentName = tostring(properties.policyAssignmentName)
| extend ComplianceRate = round(todouble(Compliant) / Total * 100, 2)
| order by ComplianceRate asc
```

### Non-Compliant Resources by Policy Definition

```kusto
PolicyResources
| where type =~ 'microsoft.policyinsights/policystates'
| where properties.complianceState == 'NonCompliant'
| project
    ResourceId = id,
    ResourceType = tostring(properties.resourceType),
    ResourceGroup = tostring(properties.resourceGroup),
    PolicyDefinitionName = tostring(properties.policyDefinitionName),
    PolicyDefinitionId = tostring(properties.policyDefinitionId),
    PolicyAssignmentName = tostring(properties.policyAssignmentName),
    ComplianceState = tostring(properties.complianceState),
    Timestamp = tostring(properties.timestamp)
| order by Timestamp desc
```

### Non-Compliant Resources by Resource Type

```kusto
PolicyResources
| where type =~ 'microsoft.policyinsights/policystates'
| where properties.complianceState == 'NonCompliant'
| summarize NonCompliantCount = count()
    by ResourceType = tostring(properties.resourceType)
| order by NonCompliantCount desc
```

### Resources Without Required Tag

```kusto
Resources
| where type =~ '[resource-type — e.g., microsoft.compute/virtualmachines]'
| where tags['[TagName]'] == ''
    or isnull(tags['[TagName]'])
| project
    ResourceId = id,
    ResourceName = name,
    ResourceGroup = resourceGroup,
    Location = location,
    ExistingTags = tags
| order by ResourceGroup asc
```

### Resources Outside Allowed Locations

```kusto
Resources
| where location !in ('[location-1]', '[location-2]', '[location-3]')
| project
    ResourceId = id,
    ResourceName = name,
    ResourceType = type,
    ResourceGroup = resourceGroup,
    Location = location
| order by Location asc
```

### Storage Accounts Without Encryption Key Vault Integration

```kusto
Resources
| where type =~ 'microsoft.storage/storageaccounts'
| where properties.encryption.keySource != 'Microsoft.Keyvault'
| project
    ResourceId = id,
    StorageAccountName = name,
    ResourceGroup = resourceGroup,
    Location = location,
    KeySource = tostring(properties.encryption.keySource)
```

---

## KQL Queries (Log Analytics / Azure Monitor)

Run these queries in a Log Analytics workspace to surface compliance trends, remediation activity, and policy evaluation events.

### Policy Compliance Trend Over Time

```kusto
AzureActivity
| where OperationNameValue has 'Microsoft.PolicyInsights'
| where ActivityStatusValue in ('Success', 'Failed')
| summarize
    Success = countif(ActivityStatusValue == 'Success'),
    Failed = countif(ActivityStatusValue == 'Failed')
    by bin(TimeGenerated, 1d), OperationNameValue
| order by TimeGenerated desc
```

### Remediation Task Outcomes

```kusto
AzureActivity
| where OperationNameValue has 'Microsoft.PolicyInsights/remediations'
| project
    TimeGenerated,
    Caller,
    OperationNameValue,
    ActivityStatusValue,
    ResourceId,
    Properties = parse_json(Properties)
| extend
    RemediationName = tostring(Properties.entity),
    PolicyAssignment = tostring(Properties.policyAssignmentId)
| order by TimeGenerated desc
```

### Policy Deny Events (Blocked Deployments)

```kusto
AzureActivity
| where OperationNameValue has_any ('Microsoft.Resources/deployments', 'Microsoft.Compute', 'Microsoft.Storage', 'Microsoft.Network')
| where ActivityStatusValue == 'Failed'
| where Properties has 'RequestDisallowedByPolicy'
| project
    TimeGenerated,
    Caller,
    ResourceGroup,
    ResourceId,
    OperationNameValue,
    Properties = parse_json(Properties)
| extend
    PolicyName = tostring(Properties.statusMessage)
| order by TimeGenerated desc
```

### Resources Modified by Policy (Modify Effect)

```kusto
AzureActivity
| where OperationNameValue has 'write'
| where Caller has 'policy'
| project
    TimeGenerated,
    Caller,
    ResourceId,
    ResourceGroup,
    OperationNameValue,
    ActivityStatusValue
| order by TimeGenerated desc
```

---

## Compliance Mapping Table

Use this table to document how your policy assignments map to regulatory framework controls. Include one row per control.

| Framework | Control ID | Control Name | Policy Definition(s) | Assignment | Compliant | Evidence |
|---|---|---|---|---|---|---|
| NIST 800-53 | SC-28 | Protection of Information at Rest | `require-encryption-storage` | `[assignment-name]` | ☐ | Policy compliance state |
| NIST 800-53 | AC-2 | Account Management | `[policy-name]` | `[assignment-name]` | ☐ | Policy compliance state |
| CIS | 3.1 | Ensure that 'Secure transfer required' is set to 'Enabled' | `[policy-name]` | `[assignment-name]` | ☐ | Policy compliance state |
| ISO 27001 | A.10.1.1 | Policy on the use of cryptographic controls | `[policy-name]` | `[assignment-name]` | ☐ | Policy compliance state |

---

## Compliance Report Checklist

- [ ] Queries have been validated in the target scope (management group, subscription, or resource group)
- [ ] All non-compliant resources in the report have a tracked remediation issue or approved exception
- [ ] Compliance rate by policy assignment has been reviewed and compared to the previous reporting period
- [ ] Framework mapping table is complete — no unmapped policy definitions
- [ ] Remediation task outcomes have been reviewed and failed remediations have been investigated
- [ ] Report has been reviewed by the policy owner before distribution to auditors or stakeholders
- [ ] Approved exceptions are referenced in the report with expiry dates and compensating controls documented

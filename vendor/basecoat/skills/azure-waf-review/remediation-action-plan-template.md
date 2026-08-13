# Remediation Action Plan

Use this template to document and track remediation actions identified during a WAF assessment. For each finding, record the recommended fix, provide an IaC snippet (Bicep or Terraform), and assign ownership and target dates.

## Plan Metadata

| Field | Value |
|---|---|
| **Workload Name** | _[name]_ |
| **Assessment Date** | _[YYYY-MM-DD]_ |
| **Plan Owner** | _[name or team]_ |
| **Target Completion** | _[YYYY-MM-DD]_ |
| **Source Report** | _[link to waf-assessment-report-template.md output]_ |

---

## Prioritization Matrix

Findings are ordered by **Impact × Effort** — high-impact, low-effort items (quick wins) appear first.

| ID | Pillar | Finding | Severity | Impact | Effort | Priority | Owner | Due Date | Status |
|---|---|---|---|---|---|---|---|---|---|
| R-01 | Reliability | | Critical | High | Low | 🔴 P1 | | | ☐ Open |
| S-01 | Security | | | | | | | | ☐ Open |
| C-01 | Cost Optimization | | | | | | | | ☐ Open |
| O-01 | Operational Excellence | | | | | | | | ☐ Open |
| P-01 | Performance Efficiency | | | | | | | | ☐ Open |

**Priority Legend:** 🔴 P1 — fix now · 🟠 P2 — fix this sprint · 🟡 P3 — fix this quarter · 🟢 P4 — backlog

---

## Remediation Items

_For each finding, complete one section below. Include an IaC snippet (Bicep preferred; Terraform alternative where applicable)._

---

### R-01 — [Finding Title]

**Pillar:** Reliability
**Severity:** _Critical / High / Medium / Low_
**WAF Reference:** _[URL to relevant WAF guidance]_

**Problem Statement:**
_Describe the gap identified during assessment._

**Recommended Fix:**
_Concise description of the remediation action._

**Acceptance Criteria:**
- [ ] _criterion 1_
- [ ] _criterion 2_

**Bicep Snippet:**

```bicep
// Example: Enable zone-redundant deployment for Azure App Service
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'P1v3'
    tier: 'PremiumV3'
    capacity: 2
  }
  properties: {
    zoneRedundant: true  // <-- enable zone redundancy
  }
}
```

**Terraform Alternative:**

```hcl
# Example: Enable zone-redundant App Service Plan
resource "azurerm_service_plan" "example" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "P1v3"
  zone_balancing_enabled = true  # <-- enable zone redundancy
}
```

**Owner:** _[name or team]_
**Due Date:** _[YYYY-MM-DD]_

---

### S-01 — [Finding Title]

**Pillar:** Security
**Severity:** _Critical / High / Medium / Low_
**WAF Reference:** _[URL to relevant WAF guidance]_

**Problem Statement:**
_Describe the gap identified during assessment._

**Recommended Fix:**
_Concise description of the remediation action._

**Acceptance Criteria:**
- [ ] _criterion 1_
- [ ] _criterion 2_

**Bicep Snippet:**

```bicep
// Example: Enable Managed Identity and Key Vault access for an App Service
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  identity: {
    type: 'SystemAssigned'  // <-- enable managed identity
  }
  properties: {
    // ...existing properties...
  }
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: appService.identity.principalId
        permissions: {
          secrets: ['get', 'list']
        }
      }
    ]
  }
}
```

**Terraform Alternative:**

```hcl
# Example: Enable System-Assigned Managed Identity on App Service
resource "azurerm_linux_web_app" "example" {
  name                = var.app_service_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.example.id

  identity {
    type = "SystemAssigned"  # <-- enable managed identity
  }
}

resource "azurerm_key_vault_access_policy" "app_service" {
  key_vault_id = azurerm_key_vault.example.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.example.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}
```

**Owner:** _[name or team]_
**Due Date:** _[YYYY-MM-DD]_

---

### C-01 — [Finding Title]

**Pillar:** Cost Optimization
**Severity:** _Critical / High / Medium / Low_
**WAF Reference:** _[URL to relevant WAF guidance]_

**Problem Statement:**
_Describe the gap identified during assessment._

**Recommended Fix:**
_Concise description of the remediation action._

**Acceptance Criteria:**
- [ ] _criterion 1_
- [ ] _criterion 2_

**Bicep Snippet:**

```bicep
// Example: Add budget alert to a resource group
resource budget 'Microsoft.Consumption/budgets@2021-10-01' = {
  name: 'workload-monthly-budget'
  properties: {
    category: 'Cost'
    amount: 5000  // monthly budget in USD
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: '2024-01-01'
    }
    notifications: {
      actual_80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [alertEmail]
        thresholdType: 'Actual'
      }
      forecasted_100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: [alertEmail]
        thresholdType: 'Forecasted'
      }
    }
  }
}
```

**Terraform Alternative:**

```hcl
# Example: Azure budget with alert notifications
resource "azurerm_consumption_budget_resource_group" "example" {
  name              = "workload-monthly-budget"
  resource_group_id = var.resource_group_id
  amount            = 5000
  time_grain        = "Monthly"

  time_period {
    start_date = "2024-01-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.alert_email]
  }
}
```

**Owner:** _[name or team]_
**Due Date:** _[YYYY-MM-DD]_

---

### O-01 — [Finding Title]

**Pillar:** Operational Excellence
**Severity:** _Critical / High / Medium / Low_
**WAF Reference:** _[URL to relevant WAF guidance]_

**Problem Statement:**
_Describe the gap identified during assessment._

**Recommended Fix:**
_Concise description of the remediation action._

**Acceptance Criteria:**
- [ ] _criterion 1_
- [ ] _criterion 2_

**Bicep Snippet:**

```bicep
// Example: Enable diagnostic settings to send logs to Log Analytics
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-log-analytics'
  scope: targetResource
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
```

**Terraform Alternative:**

```hcl
# Example: Diagnostic settings for any Azure resource
resource "azurerm_monitor_diagnostic_setting" "example" {
  name                       = "send-to-log-analytics"
  target_resource_id         = var.target_resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"

    retention_policy {
      enabled = true
      days    = 90
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

**Owner:** _[name or team]_
**Due Date:** _[YYYY-MM-DD]_

---

### P-01 — [Finding Title]

**Pillar:** Performance Efficiency
**Severity:** _Critical / High / Medium / Low_
**WAF Reference:** _[URL to relevant WAF guidance]_

**Problem Statement:**
_Describe the gap identified during assessment._

**Recommended Fix:**
_Concise description of the remediation action._

**Acceptance Criteria:**
- [ ] _criterion 1_
- [ ] _criterion 2_

**Bicep Snippet:**

```bicep
// Example: Configure auto-scale for Azure App Service
resource autoScaleSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: 'appservice-autoscale'
  location: location
  properties: {
    enabled: true
    targetResourceUri: appServicePlan.id
    profiles: [
      {
        name: 'Default'
        capacity: {
          minimum: '2'
          maximum: '10'
          default: '2'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT10M'
            }
          }
        ]
      }
    ]
  }
}
```

**Terraform Alternative:**

```hcl
# Example: Auto-scale settings for App Service Plan
resource "azurerm_monitor_autoscale_setting" "example" {
  name                = "appservice-autoscale"
  location            = var.location
  resource_group_name = var.resource_group_name
  target_resource_id  = azurerm_service_plan.example.id
  enabled             = true

  profile {
    name = "Default"

    capacity {
      default = 2
      minimum = 2
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.example.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.example.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT10M"
      }
    }
  }
}
```

**Owner:** _[name or team]_
**Due Date:** _[YYYY-MM-DD]_

---

_Add additional remediation items by copying any section above._

---

## Progress Tracker

| ID | Pillar | Status | Completed Date | Notes |
|---|---|---|---|---|
| R-01 | Reliability | ☐ Open | | |
| S-01 | Security | ☐ Open | | |
| C-01 | Cost Optimization | ☐ Open | | |
| O-01 | Operational Excellence | ☐ Open | | |
| P-01 | Performance Efficiency | ☐ Open | | |

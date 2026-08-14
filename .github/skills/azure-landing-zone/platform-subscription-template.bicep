// Platform Subscription Template
// Purpose: Deploy a single CAF platform subscription (Connectivity, Identity, or Management).
// Usage: az deployment sub create --location <region> --template-file platform-subscription-template.bicep --parameters @platform-subscription.parameters.json

targetScope = 'subscription'

@description('Subscription display name used for tagging and resource naming.')
param subscriptionDisplayName string

@allowed(['Connectivity', 'Identity', 'Management'])
@description('Platform subscription type determining which resources are deployed.')
param platformType string

@description('Primary Azure region for all resources in this subscription.')
param location string

@description('Secondary Azure region for geo-redundant resources (e.g. backup Log Analytics). Leave empty to disable.')
param locationSecondary string = ''

@description('Log Analytics workspace resource ID in the Management subscription for diagnostic forwarding.')
param logAnalyticsWorkspaceId string

@description('Microsoft Defender for Cloud pricing tier.')
@allowed(['Standard', 'Free'])
param defenderTier string = 'Standard'

@description('Mandatory resource tags applied to every resource group.')
param tags object = {
  environment: 'platform'
  managedBy: 'platform-team'
  costCenter: 'platform'
  workloadName: subscriptionDisplayName
}

// ─── Resource Groups ──────────────────────────────────────────────────────────

resource networkingRg 'Microsoft.Resources/resourceGroups@2023-07-01' = if (platformType == 'Connectivity') {
  name: 'rg-connectivity-networking-${location}'
  location: location
  tags: tags
}

resource identityRg 'Microsoft.Resources/resourceGroups@2023-07-01' = if (platformType == 'Identity') {
  name: 'rg-identity-${location}'
  location: location
  tags: tags
}

resource managementRg 'Microsoft.Resources/resourceGroups@2023-07-01' = if (platformType == 'Management') {
  name: 'rg-management-${location}'
  location: location
  tags: tags
}

// ─── Defender for Cloud ───────────────────────────────────────────────────────

resource defenderPricing 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'VirtualMachines'
  properties: {
    pricingTier: defenderTier
  }
}

resource defenderStoragePricing 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'StorageAccounts'
  properties: {
    pricingTier: defenderTier
  }
}

resource defenderKeyVaultPricing 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'KeyVaults'
  properties: {
    pricingTier: defenderTier
  }
}

// ─── Security Contact ─────────────────────────────────────────────────────────

resource securityContact 'Microsoft.Security/securityContacts@2020-01-01-preview' = {
  name: 'default'
  properties: {
    alertNotifications: {
      minimalRiskLevel: 'High'
      state: 'On'
    }
    alertsToAdmins: true
  }
}

// ─── Activity Log Diagnostic Setting ─────────────────────────────────────────

resource activityLogDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'diag-activity-log-to-law'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Administrative'
        enabled: true
      }
      {
        category: 'Security'
        enabled: true
      }
      {
        category: 'Policy'
        enabled: true
      }
      {
        category: 'Alert'
        enabled: true
      }
    ]
  }
}

// ─── Outputs ──────────────────────────────────────────────────────────────────

output subscriptionId string = subscription().subscriptionId
output platformType string = platformType
output location string = location

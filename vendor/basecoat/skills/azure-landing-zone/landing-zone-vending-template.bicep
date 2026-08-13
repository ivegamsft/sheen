// Landing Zone Vending Template
// Purpose: Vend a new application landing zone subscription with spoke VNet, hub peering, DNS, RBAC, tagging, and diagnostics.
// Usage: az deployment sub create --location <region> --template-file landing-zone-vending-template.bicep --parameters @landing-zone-vending.parameters.json

targetScope = 'subscription'

@description('Name of the workload or application team.')
param workloadName string

@description('Owner email address or alias for the application team.')
param ownerEmail string

@description('Cost center code for billing.')
param costCenter string

@minLength(1)
@maxLength(3)
@description('Environment abbreviation: dev, tst, stg, or prd.')
@allowed(['dev', 'tst', 'stg', 'prd'])
param environment string

@description('Data classification for workloads in this subscription.')
@allowed(['public', 'internal', 'confidential', 'highly-confidential'])
param dataClassification string = 'internal'

@description('Primary Azure region for spoke resources.')
param location string

@description('Spoke virtual network address space (CIDR). Must not overlap with hub or other spokes.')
param spokeVnetAddressPrefix string

@description('Resource ID of the hub virtual network to peer with.')
param hubVnetId string

@description('Private IP address of Azure Firewall in the hub for UDR default route.')
param firewallPrivateIp string

@description('Resource ID of the Log Analytics workspace in the Management subscription.')
param logAnalyticsWorkspaceId string

@description('Resource ID of the hub route table containing the default-to-firewall route.')
param hubRouteTableId string = ''

@description('Array of Azure AD group or user object IDs to assign Contributor role on this subscription.')
param appTeamContributorObjectIds array = []

// ─── Mandatory Tags ───────────────────────────────────────────────────────────

var mandatoryTags = {
  environment: environment
  owner: ownerEmail
  costCenter: costCenter
  workloadName: workloadName
  dataClassification: dataClassification
  managedBy: 'platform-team'
}

// ─── Resource Groups ──────────────────────────────────────────────────────────

resource networkingRg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-${workloadName}-networking-${environment}-${location}'
  location: location
  tags: mandatoryTags
}

resource workloadRg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-${workloadName}-${environment}-${location}'
  location: location
  tags: mandatoryTags
}

// ─── Spoke Virtual Network ────────────────────────────────────────────────────

module spokeNetworking 'br/public:avm/res/network/virtual-network:0.4.0' = {
  name: 'spokeVnet'
  scope: networkingRg
  params: {
    name: 'vnet-${workloadName}-${environment}-${location}'
    location: location
    addressPrefixes: [spokeVnetAddressPrefix]
    tags: mandatoryTags
    peerings: [
      {
        name: 'peer-to-hub'
        remoteVirtualNetworkResourceId: hubVnetId
        allowForwardedTraffic: true
        allowGatewayTransit: false
        useRemoteGateways: true
        allowVirtualNetworkAccess: true
      }
    ]
  }
}

// ─── Spoke Route Table (force-tunnel to hub firewall) ─────────────────────────

module spokeRouteTable 'br/public:avm/res/network/route-table:0.3.0' = {
  name: 'spokeRouteTable'
  scope: networkingRg
  params: {
    name: 'rt-${workloadName}-${environment}-${location}'
    location: location
    tags: mandatoryTags
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

// ─── Diagnostic Settings (Activity Log) ──────────────────────────────────────

resource activityLogDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-activity-log-to-law'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'Administrative', enabled: true }
      { category: 'Security', enabled: true }
      { category: 'Policy', enabled: true }
      { category: 'Alert', enabled: true }
    ]
  }
}

// ─── RBAC: Application Team Contributor ──────────────────────────────────────

resource appTeamRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for objectId in appTeamContributorObjectIds: {
  name: guid(subscription().id, objectId, 'Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: objectId
    principalType: 'Group'
  }
}]

// ─── Outputs ──────────────────────────────────────────────────────────────────

output subscriptionId string = subscription().subscriptionId
output spokeVnetId string = spokeNetworking.outputs.resourceId
output workloadResourceGroupName string = workloadRg.name
output networkingResourceGroupName string = networkingRg.name

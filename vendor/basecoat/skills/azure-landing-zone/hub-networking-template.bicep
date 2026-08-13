// Hub Networking Template
// Purpose: Deploy the centralized hub virtual network, Azure Firewall, DNS Private Resolver, Azure Bastion, and VPN/ER gateway.
// Usage: az deployment group create --resource-group rg-connectivity-networking-<region> --template-file hub-networking-template.bicep --parameters @hub-networking.parameters.json

@description('Azure region for all hub networking resources.')
param location string

@description('Hub virtual network address space (CIDR). Must be large enough to accommodate all required subnets.')
param hubVnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet CIDR for AzureFirewallSubnet. Must be /26 or larger.')
param firewallSubnetPrefix string = '10.0.0.0/26'

@description('Subnet CIDR for AzureBastionSubnet. Must be /26 or larger.')
param bastionSubnetPrefix string = '10.0.0.64/26'

@description('Subnet CIDR for GatewaySubnet.')
param gatewaySubnetPrefix string = '10.0.1.0/27'

@description('Subnet CIDR for DNS Private Resolver inbound endpoint.')
param dnsResolverInboundSubnetPrefix string = '10.0.2.0/28'

@description('Subnet CIDR for DNS Private Resolver outbound endpoint.')
param dnsResolverOutboundSubnetPrefix string = '10.0.2.16/28'

@description('Azure Firewall SKU tier.')
@allowed(['Standard', 'Premium'])
param firewallSkuTier string = 'Premium'

@description('Enable Azure Bastion for secure VM access.')
param enableBastion bool = true

@description('Enable VPN gateway. Set to false when using ExpressRoute only.')
param enableVpnGateway bool = true

@description('Enable ExpressRoute gateway.')
param enableErGateway bool = false

@description('Log Analytics workspace resource ID for diagnostic settings.')
param logAnalyticsWorkspaceId string

@description('Mandatory resource tags.')
param tags object = {
  environment: 'platform'
  managedBy: 'platform-team'
  workloadName: 'hub-networking'
}

// ─── Hub Virtual Network ──────────────────────────────────────────────────────

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-hub-${location}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [hubVnetAddressPrefix]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: { addressPrefix: firewallSubnetPrefix }
      }
      {
        name: 'AzureBastionSubnet'
        properties: { addressPrefix: bastionSubnetPrefix }
      }
      {
        name: 'GatewaySubnet'
        properties: { addressPrefix: gatewaySubnetPrefix }
      }
      {
        name: 'DnsResolverInboundSubnet'
        properties: {
          addressPrefix: dnsResolverInboundSubnetPrefix
          delegations: [
            {
              name: 'Microsoft.Network.dnsResolvers'
              properties: { serviceName: 'Microsoft.Network/dnsResolvers' }
            }
          ]
        }
      }
      {
        name: 'DnsResolverOutboundSubnet'
        properties: {
          addressPrefix: dnsResolverOutboundSubnetPrefix
          delegations: [
            {
              name: 'Microsoft.Network.dnsResolvers'
              properties: { serviceName: 'Microsoft.Network/dnsResolvers' }
            }
          ]
        }
      }
    ]
    enableDdosProtection: false
  }
}

// ─── Azure Firewall ───────────────────────────────────────────────────────────

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-09-01' = {
  name: 'afwp-hub-${location}'
  location: location
  tags: tags
  properties: {
    sku: { tier: firewallSkuTier }
    threatIntelMode: 'Alert'
    dnsSettings: {
      enableProxy: true
    }
  }
}

resource firewallPip 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-afw-hub-${location}'
  location: location
  tags: tags
  sku: { name: 'Standard', tier: 'Regional' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-09-01' = {
  name: 'afw-hub-${location}'
  location: location
  tags: tags
  properties: {
    sku: { name: 'AZFW_VNet', tier: firewallSkuTier }
    firewallPolicy: { id: firewallPolicy.id }
    ipConfigurations: [
      {
        name: 'ipconfig-hub'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnet.name, 'AzureFirewallSubnet')
          }
          publicIPAddress: { id: firewallPip.id }
        }
      }
    ]
  }
}

resource firewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-afw-to-law'
  scope: firewall
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { categoryGroup: 'allLogs', enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
}

// ─── DNS Private Resolver ─────────────────────────────────────────────────────

resource dnsResolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: 'dnspr-hub-${location}'
  location: location
  tags: tags
  properties: {
    virtualNetwork: { id: hubVnet.id }
  }
}

resource dnsResolverInbound 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = {
  parent: dnsResolver
  name: 'inbound'
  location: location
  properties: {
    ipConfigurations: [
      {
        subnet: {
          id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnet.name, 'DnsResolverInboundSubnet')
        }
        privateIpAllocationMethod: 'Dynamic'
      }
    ]
  }
}

resource dnsResolverOutbound 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = {
  parent: dnsResolver
  name: 'outbound'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnet.name, 'DnsResolverOutboundSubnet')
    }
  }
}

// ─── Azure Bastion ────────────────────────────────────────────────────────────

resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-09-01' = if (enableBastion) {
  name: 'pip-bastion-hub-${location}'
  location: location
  tags: tags
  sku: { name: 'Standard', tier: 'Regional' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-09-01' = if (enableBastion) {
  name: 'bas-hub-${location}'
  location: location
  tags: tags
  sku: { name: 'Standard' }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig-bastion'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnet.name, 'AzureBastionSubnet')
          }
          publicIPAddress: { id: bastionPip.id }
        }
      }
    ]
  }
}

// ─── VPN Gateway ─────────────────────────────────────────────────────────────

resource vpnGatewayPip 'Microsoft.Network/publicIPAddresses@2023-09-01' = if (enableVpnGateway) {
  name: 'pip-vpngw-hub-${location}'
  location: location
  tags: tags
  sku: { name: 'Standard', tier: 'Regional' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-09-01' = if (enableVpnGateway) {
  name: 'vpngw-hub-${location}'
  location: location
  tags: tags
  properties: {
    sku: { name: 'VpnGw2AZ', tier: 'VpnGw2AZ' }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: true
    ipConfigurations: [
      {
        name: 'ipconfig-vpngw'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnet.name, 'GatewaySubnet')
          }
          publicIPAddress: { id: vpnGatewayPip.id }
        }
      }
    ]
  }
}

// ─── Hub Route Table (force-tunnel via Firewall) ──────────────────────────────

resource hubRouteTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: 'rt-hub-${location}'
  location: location
  tags: tags
  properties: {
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

// ─── Outputs ──────────────────────────────────────────────────────────────────

output hubVnetId string = hubVnet.id
output hubVnetName string = hubVnet.name
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output dnsResolverInboundIp string = dnsResolverInbound.properties.ipConfigurations[0].privateIpAddress
output hubRouteTableId string = hubRouteTable.id

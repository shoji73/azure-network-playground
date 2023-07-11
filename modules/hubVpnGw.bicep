
param location string = resourceGroup().location
param existingHubVnetName string = 'hubVnet'
param existingGatewaySubnetName string = 'GatewaySubnet'
param logAnalyticsWorkspaceId string

var hubVpnGwPipName = 'hubVpnGwPip'
var hubVpnGwName = 'hubVpnGw'
var hubVpnGwDiagnosticSettingsName = 'send-loganalytics'

resource existingHubVnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingHubVnetName
  resource existingGatewaySubnet 'subnets' existing = {
    name: existingGatewaySubnetName
  }
}

resource hubVpnGwPip 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: hubVpnGwPipName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource hubVpnGw 'Microsoft.Network/virtualNetworkGateways@2022-11-01' = {
  name: hubVpnGwName
  location: location
  properties: {
    enablePrivateIpAddress: false
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: hubVpnGwPip.id
          }
          subnet: {
            id: existingHubVnet::existingGatewaySubnet.id
          }
        }
      }
    ]
    natRules: []
    virtualNetworkGatewayPolicyGroups: []
    enableBgpRouteTranslationForNat: false
    disableIPSecReplayProtection: false
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    activeActive: false
    vpnClientConfiguration: {
      vpnClientProtocols: [
        'OpenVPN'
        'IkeV2'
      ]

    }
    vpnGatewayGeneration: 'Generation1'
    allowRemoteVnetTraffic: false
    allowVirtualWanTraffic: false
  }
}

resource hubGwDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: hubVpnGwDiagnosticSettingsName
  scope: hubVpnGw
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        timeGrain: null
        enabled: true
        category: 'AllMetrics'
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

output hubVpnGwPipName string = hubVpnGwPip.name
output hubVpnGwName string = hubVpnGw.name

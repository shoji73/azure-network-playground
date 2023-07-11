param location string = resourceGroup().location
param existingRemoteVnetName string = 'remoteVnet'
param existingGatewaySubnetName string = 'GatewaySubnet'
param logAnalyticsWorkspaceId string

var remoteVpnGwPipName = 'remoteVpnGwPip'
var remoteVpnGwName = 'remoteVpnGw'
var remoteVpnGwDiagnosticSettingsName = 'send-loganalytics'

resource existingRemoteVnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingRemoteVnetName
  resource existingGatewaySubnet 'subnets' existing = {
    name: existingGatewaySubnetName
  }
}

resource remoteVpnGwPip 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: remoteVpnGwPipName
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

resource remoteVpnGw 'Microsoft.Network/virtualNetworkGateways@2022-11-01' = {
  name: remoteVpnGwName
  location: location
  properties: {
    enablePrivateIpAddress: false
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: remoteVpnGwPip.id
          }
          subnet: {
            id: existingRemoteVnet::existingGatewaySubnet.id
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

resource remoteGwDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: remoteVpnGwDiagnosticSettingsName
  scope: remoteVpnGw
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

output remoteVpnGwPipName string = remoteVpnGwPip.name
output remoteVpnGwName string = remoteVpnGw.name

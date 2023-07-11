param location string = resourceGroup().location
param existingSpoke01VnetName string
param existingApplicationServerSubnetName string
param existingPrivateLinkSubnetName string
param spoke01LbFrontendIpAddress string
param logAnalyticsWorkspaceId string
param hubLbPrivateEndpointAddress string
param existingHubVnetName string
param existingPrivateEndpointSubnetName string

var spoke01LbName = 'spoke01Lb'
var spoke01LbBackendPoolName = 'spoke01LbBackendPool'
var spoke01LbFrontendIpConfigurationName = 'spoke01LbFrontendPool'
var spoke01LbProbeName = 'spoke01LbProbe'
var spoke01LPrivateLinkName = 'spoke01LbPrivateLink'
var spoke01LbDiagnosticSettingsName = 'send-loganalytics'
var spoke01LPrivateEndpointName = 'spoke01LbPrivateEndpoint'
var spoke01LbPrivateEndpointNicName = 'spoke01LbPrivateEndpointNic'

resource existingHubVnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingHubVnetName
  resource existingPrivateEndpointSubnet 'subnets' existing = {
    name: existingPrivateEndpointSubnetName
  }
}

resource existingSpoke01Vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingSpoke01VnetName
  resource existingApplicationServerSubnet 'subnets' existing = {
    name: existingApplicationServerSubnetName
  }
  resource existingPrivateLinkSubnet 'subnets' existing = {
    name: existingPrivateLinkSubnetName
  }
}

resource spoke01Lb 'Microsoft.Network/loadBalancers@2021-08-01' = {
  name: spoke01LbName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: spoke01LbFrontendIpConfigurationName
        properties: {
          privateIPAddress: spoke01LbFrontendIpAddress
          privateIPAllocationMethod: 'Static'
          subnet:{
            id: existingSpoke01Vnet::existingApplicationServerSubnet.id
          }	
        }
      }
    ]
    backendAddressPools: [
      {
        name: spoke01LbBackendPoolName
      }
    ]
    loadBalancingRules: [
      {
        name: 'myHTTPRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', spoke01LbName, spoke01LbFrontendIpConfigurationName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', spoke01LbName, spoke01LbBackendPoolName)
          }
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 15
          protocol: 'Tcp'
          enableTcpReset: true
          loadDistribution: 'Default'
          disableOutboundSnat: true
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', spoke01LbName, spoke01LbProbeName)
          }
        }
      }
    ]
    probes: [
      {
        name: spoke01LbProbeName
        properties: {
          protocol: 'Http'
          port: 80
          requestPath: '/status/200'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    outboundRules: []
  }
}

resource spoke01LbDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: spoke01LbDiagnosticSettingsName
  scope: spoke01Lb
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

resource spoke01LPrivateLink 'Microsoft.Network/privateLinkServices@2019-04-01' = {
  name: spoke01LPrivateLinkName
  location: location
  properties: {
    fqdns: []
    visibility: {
      subscriptions: []
    }
    autoApproval: {
      subscriptions: []
    }
    //enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', spoke01LbName, spoke01LbFrontendIpConfigurationName)
      }
    ]
    ipConfigurations: [
      {
        name: 'spoke01LPrivateLinkIpConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: existingSpoke01Vnet::existingPrivateLinkSubnet.id
          }
          primary: true
        }
      }
    ]
    privateEndpointConnections: []
  }
  dependsOn: [
    spoke01Lb
  ]
}

resource spoke01LPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  location: location
  name: spoke01LPrivateEndpointName
  properties: {
    subnet: {
      id: existingHubVnet::existingPrivateEndpointSubnet.id
    }
    ipConfigurations: [
      {
        name: 'spoke01LPrivateEndpointIpCongig'
        properties: {
          privateIPAddress: hubLbPrivateEndpointAddress
        }
      }
    ]
    customNetworkInterfaceName: spoke01LbPrivateEndpointNicName
    privateLinkServiceConnections: [
      {
        name: spoke01LPrivateEndpointName
        properties: {
          privateLinkServiceId: spoke01LPrivateLink.id
          groupIds: []
        }
      }
    ]
  }
}



output spoke01LbBackendAddressPoolId string = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', spoke01LbName, spoke01LbBackendPoolName)

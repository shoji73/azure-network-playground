param location string = resourceGroup().location
param vnetResourceGroupName string

param existingRemoteVnetName string
param existingRemoteClientSubnetName string

param existingSpoke01VnetName string
param existingApplicationServerSubnetName string

param existingSpoke02VnetName string
param existingSpoke02ClientSubnet string

param hubLbPrivateEndpointAddress string
param hubAppGwPrivateEndpointAddress string
param appGwFrontendIpAddress string
param spoke01LbFrontendIpAddress string

param logAnalyticsWorkspaceId string

var connectionMonitorName = 'connectionMonitor'
var endpointRemoteClientSubnetName = 'remoteClientSubnet'
var endpointSpoke02ClientSubnetName = 'spoke02ClientSubnet'
var endpointSpoke01ApplicationServerSubnetName = 'spoke01ApplicationServerSubnet'
var testConfigurationName = 'httpTest'
var testVipConfigurationName = 'httpVipTest'

var normalTestGroupName = 'normalTestGroup'
var normalVipTestGroupName = 'normalVipTestGroup'

var hubLbPrivateEndpointName = 'hubLbPrivateEndpoint'
var hubAppGwPrivateEndpointName = 'hubAppGwPrivateEndpoint'
var appGwFrontendIpAddressName = 'appGwFrontendIpAddress'
var spoke01LbFrontendIpAddressName = 'spoke01LbFrontendIpAddress'
var networkWatcherName = 'NetworkWatcher_${location}'

resource existingRemoteVnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingRemoteVnetName
  scope: resourceGroup(vnetResourceGroupName)
  resource existingClientSubnet 'subnets' existing = {
    name: existingRemoteClientSubnetName
  }
}

resource existingSpoke01Vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingSpoke01VnetName
  scope: resourceGroup(vnetResourceGroupName)
  resource existingApplicationServerSubnet 'subnets' existing = {
    name: existingApplicationServerSubnetName
  }
}

resource existingSpoke02Vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingSpoke02VnetName
  scope: resourceGroup(vnetResourceGroupName)
  resource existingClientSubnet 'subnets' existing = {
    name: existingSpoke02ClientSubnet
  }
}

resource connectionMonitor 'Microsoft.Network/networkWatchers/connectionMonitors@2022-11-01' = {
  name: '${networkWatcherName}/${connectionMonitorName}'
  location: location
  properties: {
    endpoints: [
      {
        name: endpointRemoteClientSubnetName
        resourceId: existingRemoteVnet::existingClientSubnet.id
        type: 'AzureSubnet'
      }
      {
        name: endpointSpoke02ClientSubnetName
        resourceId: existingSpoke02Vnet::existingClientSubnet.id
        type: 'AzureSubnet'
      }
      {
        name: endpointSpoke01ApplicationServerSubnetName
        resourceId: existingSpoke01Vnet::existingApplicationServerSubnet.id
        type: 'AzureSubnet'
      }
      {
        name: hubLbPrivateEndpointName
        type: 'ExternalAddress'
        address: hubLbPrivateEndpointAddress
      }
      {
        name: hubAppGwPrivateEndpointName
        type: 'ExternalAddress'
        address: hubAppGwPrivateEndpointAddress
      }
      {
        name: appGwFrontendIpAddressName
        type: 'ExternalAddress'
        address: appGwFrontendIpAddress
      }
      {
        name: spoke01LbFrontendIpAddressName
        type: 'ExternalAddress'
        address: spoke01LbFrontendIpAddress
      }
    ]
    testConfigurations: [
      {
        name: testConfigurationName
        testFrequencySec: 30
        protocol: 'HTTP'
        successThreshold: {
          checksFailedPercent: null
          roundTripTimeMs: null
        }
        httpConfiguration: {
          port: 80
          method: 'GET'
          path: '/status/200'
          requestHeaders: []
          validStatusCodeRanges: [
            '200'
          ]
          preferHTTPS: false
        }
      }
      {
        name: testVipConfigurationName
        testFrequencySec: 30
        protocol: 'HTTP'
        successThreshold: {
          checksFailedPercent: null
          roundTripTimeMs: null
        }
        httpConfiguration: {
          port: 80
          method: 'GET'
          requestHeaders: [ {
              name: 'Host'
              value: 'httpbin.org'
            } ]
          validStatusCodeRanges: [
            '200'
          ]
          preferHTTPS: false
        }
      }
    ]
    testGroups: [
      {
        name: normalTestGroupName
        disable: false
        sources: [
          endpointRemoteClientSubnetName
          endpointSpoke02ClientSubnetName
        ]
        destinations: [
          endpointSpoke01ApplicationServerSubnetName
        ]
        testConfigurations: [
          testConfigurationName
        ]
      }
      {
        name: normalVipTestGroupName
        disable: false
        sources: [
          endpointRemoteClientSubnetName
          endpointSpoke02ClientSubnetName
        ]
        destinations: [
          hubLbPrivateEndpointName
          hubAppGwPrivateEndpointName
          appGwFrontendIpAddressName
          spoke01LbFrontendIpAddressName
        ]
        testConfigurations: [
          testVipConfigurationName
        ]
      }
    ]
    outputs: [
      {
        type: 'Workspace'
        workspaceSettings: {
          workspaceResourceId: logAnalyticsWorkspaceId
        }
      }
    ]
  }
}

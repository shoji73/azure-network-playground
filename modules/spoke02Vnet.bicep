param location string = resourceGroup().location
param spoke02VnetSpace string = '10.2.0.0/16'
param spoke02VnetClientSubnetSpace string = '10.2.0.0/24'

param remoteVnetSpace string
param spoke01VnetSpace string
param hubAfwPrivateIpAddress string
param spoke02ClientSubnetNsgId string

var spoke02VnetName = 'spoke02Vnet'
var clientSubnetName = 'clientSubnet'
var spoke02VnetUdrName = 'spoke02VnetUdr'

resource spoke02Vnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: spoke02VnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spoke02VnetSpace
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: clientSubnetName
        properties: {
          addressPrefix: spoke02VnetClientSubnetSpace
          routeTable: {
            id: spoke02VnetUdr.id
          }
          networkSecurityGroup: {
            id: spoke02ClientSubnetNsgId
          }
        }
      }
    ]
    enableDdosProtection: false
  }
}

resource spoke02VnetUdr 'Microsoft.Network/routeTables@2022-07-01' = {
  name: spoke02VnetUdrName
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'remote'
        properties: {
          addressPrefix: remoteVnetSpace
          hasBgpOverride: false
          nextHopIpAddress: hubAfwPrivateIpAddress
          nextHopType: 'VirtualAppliance'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
      {
        name: 'spoke01'
        properties: {
          addressPrefix: spoke01VnetSpace
          hasBgpOverride: false
          nextHopIpAddress: hubAfwPrivateIpAddress
          nextHopType: 'VirtualAppliance'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
    ]
  }
}

output spoke02VnetName string = spoke02Vnet.name
output clientSubnetName string = clientSubnetName

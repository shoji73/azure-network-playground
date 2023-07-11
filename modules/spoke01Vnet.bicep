param location string = resourceGroup().location
param spoke01VnetSpace string = '10.1.0.0/16'
param spoke01VnetApplicationGatewaySubnetSpace string = '10.1.0.0/24'
param spoke01VnetPrivateLinkSubnetSpace string = '10.1.1.0/24'
param spoke01VnetApplicationServerSubnetSpace string = '10.1.2.0/24'

param remoteVnetSpace string
param spoke02VnetSpace string
param hubAfwPrivateIpAddress string

param appGwSubnetNsgId string
param privateLinkSubnetNsgId string
param applicationServerSubnetNsgId string

var spoke01VnetName = 'spoke01Vnet'
var applicationGatewaySubnetName = 'applicationGatewaySubnet'
var applicationServerSubnetName = 'applicationServerSubnet'
var privateLinkSubnetName = 'privateLinkSubnet'
var spoke01NatGwPipName = 'spoke01NatGwPip'
var spoke01NatGwName = 'spoke01NatGw'
var spoke01VnetUdrName = 'spoke01VnetUdr'

resource spoke01Vnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: spoke01VnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spoke01VnetSpace
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: applicationGatewaySubnetName
        properties: {
          addressPrefix: spoke01VnetApplicationGatewaySubnetSpace
          routeTable:{
            id: spoke01VnetUdr.id
          }
          networkSecurityGroup: {
            id: appGwSubnetNsgId
          }

        }
      }
      {
        name: privateLinkSubnetName
        properties: {
          addressPrefix: spoke01VnetPrivateLinkSubnetSpace
          privateLinkServiceNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: privateLinkSubnetNsgId
          }
        }
      }
      {
        name: applicationServerSubnetName
        properties: {
          addressPrefix: spoke01VnetApplicationServerSubnetSpace
          natGateway: {
            id: spoke01NatGw.id
          }
          routeTable:{
            id: spoke01VnetUdr.id
          }
          networkSecurityGroup: {
            id: applicationServerSubnetNsgId
          }
        }
      }
    ]
    enableDdosProtection: false
  }
}

resource spoke01NatGwPip 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: spoke01NatGwPipName
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

resource spoke01NatGw 'Microsoft.Network/natGateways@2022-11-01' = {
  name: spoke01NatGwName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: spoke01NatGwPip.id
      }
    ]
  }
}

resource spoke01VnetUdr 'Microsoft.Network/routeTables@2022-07-01' = {
  name: spoke01VnetUdrName
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
        name: 'spoke02'
        properties: {
          addressPrefix: spoke02VnetSpace
          hasBgpOverride: false
          nextHopIpAddress: hubAfwPrivateIpAddress
          nextHopType: 'VirtualAppliance'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
    ]
  }
}


output spoke01VnetName string = spoke01Vnet.name
output applicationGatewaySubnetName string = applicationGatewaySubnetName
output applicationServerSubnetName string = applicationServerSubnetName
output privateLinkSubnetName string = privateLinkSubnetName

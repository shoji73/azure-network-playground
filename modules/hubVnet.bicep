param location string = resourceGroup().location
param hubVnetSpace string = '10.0.0.0/16'
param hubVnetGatewaySubnetSpace string = '10.0.0.0/26'
param hubVnetAzureFirewallSubnetSpace string = '10.0.0.64/26'
param hubVnetAzureBastionSubnetSpace string = '10.0.0.128/26'
param hubPrivateEndpointSubnetSpace string = '10.0.0.192/26'
param spoke01VnetSpace string
param spoke02VnetSpace string
param hubAfwPrivateIpAddress string
param hubBastionSubnetNsgId string
param hubPrivateEndpointNsgId string

var hubVnetName = 'hubVnet'
var gatewaySubnetName = 'GatewaySubnet'
var azureFirewallSubnetName = 'AzureFirewallSubnet'
var azureBastionSubnetName = 'AzureBastionSubnet'
var privateEndpointSubnetName = 'privateEndpointSubnet'
var hubGatewayUdrName = 'hubGatewayUdr'

resource hubVnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: hubVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetSpace
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: gatewaySubnetName
        properties: {
          addressPrefix: hubVnetGatewaySubnetSpace
          routeTable: {
            id: hubGatewayUdr.id
          }
        }
      }
      {
        name: azureFirewallSubnetName
        properties: {
          addressPrefix: hubVnetAzureFirewallSubnetSpace
        }
      }
      {
        name: azureBastionSubnetName
        properties: {
          addressPrefix: hubVnetAzureBastionSubnetSpace
          networkSecurityGroup: {
            id: hubBastionSubnetNsgId
          }
        }
      }
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: hubPrivateEndpointSubnetSpace
          networkSecurityGroup: {
            id: hubPrivateEndpointNsgId
          }
        }
      }
    ]
    enableDdosProtection: false
  }
}

resource hubGatewayUdr 'Microsoft.Network/routeTables@2022-07-01' = {
  name: hubGatewayUdrName
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
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

output hubVnetName string = hubVnet.name
output gatewaySubnetName string = gatewaySubnetName
output azureFirewallSubnetName string = azureFirewallSubnetName
output azureBastionSubnetName string = azureBastionSubnetName
output privateEndpointSubnetName string = privateEndpointSubnetName

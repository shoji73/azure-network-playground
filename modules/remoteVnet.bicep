param location string = resourceGroup().location
param remoteVnetSpace string = '172.16.0.0/16'
param remoteVnetGatewaySubnetSpace string = '172.16.0.0/26'
param remoteVnetClientSubnetSpace string = '172.16.1.0/24'
param remoteClientSubnetNsgId string

var remoteVnetName = 'remoteVnet'
var gatewaySubnetName = 'GatewaySubnet'
var clientSubnetName = 'remoteClientSubnet'

resource remoteVnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: remoteVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        remoteVnetSpace
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: gatewaySubnetName
        properties: {
          addressPrefix: remoteVnetGatewaySubnetSpace
        }
      }
      {
        name: clientSubnetName
        properties: {
          addressPrefix: remoteVnetClientSubnetSpace
          networkSecurityGroup: {
            id: remoteClientSubnetNsgId
          }
        }
      }
    ]
    enableDdosProtection: false
  }
}

output remoteVnetName string = remoteVnet.name
output gatewaySubnetName string = remoteVnet.properties.subnets[0].name
output clientSubnetName string = remoteVnet.properties.subnets[1].name

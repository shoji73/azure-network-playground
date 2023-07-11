param location string = resourceGroup().location
param existingHubVnetName string
param existingGatewaySubnetName string
param existingSpoke01VnetName string
param existingApplicationGatewaySubnetName string
param existingApplicationServerSubnetName string
param existingSpoke02VnetName string
param existingClientSubnetName string
param existingHubAfwName string


var hubGatewayUdrName = 'hubGatewayUdr'

resource existingHubVnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingHubVnetName
  resource existingGatewaySubnet 'subnets' existing = {
    name: existingGatewaySubnetName
  }
}

resource existingSpoke01Vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingSpoke01VnetName
  resource existingApplicationGatewaySubnet 'subnets' existing = {
    name: existingApplicationGatewaySubnetName
  }
  resource existingApplicationServerSubnet 'subnets' existing = {
    name: existingApplicationServerSubnetName
  }
}

resource existingSpoke02Vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingSpoke02VnetName
  resource existingClientSubnet 'subnets' existing = {
    name: existingClientSubnetName
  }
}

resource hubAfw 'Microsoft.Network/azureFirewalls@2022-11-01' existing = {
  name: existingHubAfwName
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
          addressPrefix: existingSpoke01Vnet.properties.addressSpace.addressPrefixes[0]
          hasBgpOverride: false
          nextHopIpAddress: hubAfw.properties.ipConfigurations[0].properties.privateIPAddress
          nextHopType: 'VirtualAppliance'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
      {
        name: 'spoke02'
        properties: {
          addressPrefix: existingSpoke02Vnet.properties.addressSpace.addressPrefixes[0]
          hasBgpOverride: false
          nextHopIpAddress: hubAfw.properties.ipConfigurations[0].properties.privateIPAddress
          nextHopType: 'VirtualAppliance'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
    ]
  }
}

param existingHubVnetName string
param existingSpoke01VnetName string
param existingSpoke02VnetName string


resource existingHubVnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingHubVnetName 
}

resource existingSpoke01Vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingSpoke01VnetName
}

resource existingSpoke02Vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingSpoke02VnetName
}

resource peeringHubToSpoke01 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peeringHubToSpoke01'
  parent: existingHubVnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    doNotVerifyRemoteGateways: false
    remoteVirtualNetwork: {
      id: existingSpoke01Vnet.id
    }
    useRemoteGateways: false
  }
}

resource peeringHubToSpoke02 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peeringHubToSpoke02'
  parent: existingHubVnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    doNotVerifyRemoteGateways: false
    remoteVirtualNetwork: {
      id: existingSpoke02Vnet.id
    }
    useRemoteGateways: false
  }
}

resource peeringSpoke01ToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peeringSpoke01ToHub'
  parent: existingSpoke01Vnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    doNotVerifyRemoteGateways: false
    remoteVirtualNetwork: {
      id: existingHubVnet.id
    }
    useRemoteGateways: true
  }
}

resource peeringSpoke02ToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peeringSpoke02ToHub'
  parent: existingSpoke02Vnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    doNotVerifyRemoteGateways: false
    remoteVirtualNetwork: {
      id: existingHubVnet.id
    }
    useRemoteGateways: true
  }
}


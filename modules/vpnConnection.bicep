param location string = resourceGroup().location
param hubVnetSpace string = '10.0.0.0/16'
param spoke01VnetSpace string = '10.1.0.0/16'
param spoke02VnetSpace string = '10.2.0.0/16'
param remoteVnetSpace string = '172.16.0.0/16'
param existingHubVpnGwPipName string
param existingRemoteVpnGwPipName string
param existingHubVpnGwName string
param existingRemoteVpnGwName string

var hubLocalGwName = 'hubLocalGw'
var remoteLocalGwName = 'remoteLocalGw'
var vpnConnectionHubToRemoteName = 'connectionHubToRemote'
var vpnConnectionRemoteToHubName = 'connectionRemoteToHub'

resource existingHubVpnGwPip 'Microsoft.Network/publicIPAddresses@2022-11-01' existing = {
  name: existingHubVpnGwPipName
}

resource existingRemoteVpnGwPip 'Microsoft.Network/publicIPAddresses@2022-11-01' existing = {
  name: existingRemoteVpnGwPipName
}

resource existingHubVpnGw 'Microsoft.Network/virtualNetworkGateways@2022-11-01' existing = {
  name: existingHubVpnGwName
}

resource existinRemoteVpnGw 'Microsoft.Network/virtualNetworkGateways@2022-11-01' existing = {
  name: existingRemoteVpnGwName
}

resource hubLocalGw 'Microsoft.Network/localNetworkGateways@2022-11-01' = {
  name: hubLocalGwName
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        remoteVnetSpace
      ]
    }
    gatewayIpAddress: existingRemoteVpnGwPip.properties.ipAddress
  }
}

resource remoteLocalGw 'Microsoft.Network/localNetworkGateways@2022-11-01' = {
  name: remoteLocalGwName
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        hubVnetSpace
        spoke01VnetSpace
        spoke02VnetSpace
      ]
    }
    gatewayIpAddress: existingHubVpnGwPip.properties.ipAddress
  }
}

resource vpnConnectionRemoteToHub 'Microsoft.Network/connections@2022-11-01' = {
  name: vpnConnectionRemoteToHubName
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: existinRemoteVpnGw.id
      properties: {}
    }
    localNetworkGateway2: {
      id: remoteLocalGw.id
      properties: {}
    }
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    routingWeight: 0
    sharedKey: 'sharedkey'
    enableBgp: false
    useLocalAzureIpAddress: false
    usePolicyBasedTrafficSelectors: false
    expressRouteGatewayBypass: false
    enablePrivateLinkFastPath: false
    dpdTimeoutSeconds: 0
    connectionMode: 'Default'
  }
}

resource vpnConnectionHubToRemote 'Microsoft.Network/connections@2022-11-01' = {
  name: vpnConnectionHubToRemoteName
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: existingHubVpnGw.id
      properties: {}
    }
    localNetworkGateway2: {
      id: hubLocalGw.id
      properties: {}
    }
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    routingWeight: 0
    sharedKey: 'sharedkey'
    enableBgp: false
    useLocalAzureIpAddress: false
    usePolicyBasedTrafficSelectors: false
    expressRouteGatewayBypass: false
    enablePrivateLinkFastPath: false
    dpdTimeoutSeconds: 0
    connectionMode: 'Default'
  }
}

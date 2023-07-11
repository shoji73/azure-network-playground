param location string = resourceGroup().location
param existingHubVnetName string 
param existingAzureFirewallSubnetName string 
param existingSpoke01VnetName string
param existingSpoke02VnetName string
param existingRemoteVnetName string
param logAnalyticsWorkspaceId string = '7728171c-c8eb-4bf3-8fb0-03b15cc49222'

var hubAfwPipName = 'hubAfwPip'
var hubAfwName = 'hubAfw'
var hubAfwPolicyName = 'hubAfwPolicy'
var hubAfwDiagnosticSettingsName = 'send-loganalytics'

resource existingHubVnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingHubVnetName
  resource existingAzureFirewallSubnet 'subnets' existing = {
    name: existingAzureFirewallSubnetName
  }
}

resource hubAfwPip 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: hubAfwPipName
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

resource hubAfw 'Microsoft.Network/azureFirewalls@2022-11-01' = {
  name: hubAfwName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    additionalProperties: {}
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          publicIPAddress: {
            id: hubAfwPip.id
          }
          subnet: {
            id: existingHubVnet::existingAzureFirewallSubnet.id
          }
        }
      }
    ]
    networkRuleCollections: []
    applicationRuleCollections: []
    natRuleCollections: []
    firewallPolicy: {
      id: hubAfwPolicy.id
    }
  }
}


resource hubAfwPolicy 'Microsoft.Network/firewallPolicies@2022-11-01' = {
  name: hubAfwPolicyName
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    threatIntelWhitelist: {
      fqdns: []
      ipAddresses: []
    }
  }
}

resource hubAfwDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: hubAfwDiagnosticSettingsName
  scope: hubAfw
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

resource existingSpoke01Vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingSpoke01VnetName
}

resource existingSpoke02Vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingSpoke02VnetName
}

resource existingRemoteVnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingRemoteVnetName
}

resource hubAfwDefaultNetworkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-11-01' = {
  parent: hubAfwPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'hubAfwNetworkRules'
        priority: 1000
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'AllowOutbounFromSpoke01Vnet'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              existingSpoke01Vnet.properties.addressSpace.addressPrefixes[0]
            ]
            sourceIpGroups: []
            destinationAddresses: [
              existingSpoke02Vnet.properties.addressSpace.addressPrefixes[0]
              existingRemoteVnet.properties.addressSpace.addressPrefixes[0]
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '*'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'AllowOutboundFromSpoke02Vnet'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              existingSpoke02Vnet.properties.addressSpace.addressPrefixes[0]
            ]
            sourceIpGroups: []
            destinationAddresses: [
              existingSpoke01Vnet.properties.addressSpace.addressPrefixes[0]
              existingRemoteVnet.properties.addressSpace.addressPrefixes[0]
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '*'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'AllowInboundFromRemoteVnet'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              existingRemoteVnet.properties.addressSpace.addressPrefixes[0]
            ]
            sourceIpGroups: []
            destinationAddresses: [
              existingSpoke01Vnet.properties.addressSpace.addressPrefixes[0]
              existingSpoke02Vnet.properties.addressSpace.addressPrefixes[0]
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '*'
            ]
          }
        ]
      }
    ]
  }
}


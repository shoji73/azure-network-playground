param location string = resourceGroup().location
param logAnalyticsWorkspaceId string

var AppGwSubnetNsgName = 'AppGwSubnetNsg'
var privateLinkSubnetNsgName = 'privateLinkSubnetNsg'
var applicationServerSubnetName = 'applicationServerSubnetNsg'

resource AppGwSubnetNsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: AppGwSubnetNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: ''
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: [ '65200-65535' ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource privateLinkSubnetNsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: privateLinkSubnetNsgName
  location: location
  properties: {
    securityRules: []
  }
}

resource applicationServerSubnetNsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: applicationServerSubnetName
  location: location
  properties: {
    securityRules: []
  }
}

resource AppGwSubnetNsggDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-loganalytics'
  scope: AppGwSubnetNsg
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
  }
}

resource privateLinkSubnetNsgDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-loganalytics'
  scope: privateLinkSubnetNsg
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
  }
}

resource applicationServerSubnetNsgDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-loganalytics'
  scope: applicationServerSubnetNsg
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
  }
}

output appGwSubnetNsgId string = AppGwSubnetNsg.id
output privateLinkSubnetNsgId string = privateLinkSubnetNsg.id
output applicationServerSubnetNsgId string = applicationServerSubnetNsg.id

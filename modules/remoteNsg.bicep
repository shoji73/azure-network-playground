param location string = resourceGroup().location
param logAnalyticsWorkspaceId string

var remoteClientSubnetNsgName = 'remoteClientSubnetNsg'

resource remoteClientSubnetNsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: remoteClientSubnetNsgName
  location: location
  properties: {
    securityRules: []
  }
}

resource remoteClientSubnetNsgDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-loganalytics'
  scope: remoteClientSubnetNsg
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

output remoteClientSubnetNsgId string = remoteClientSubnetNsg.id

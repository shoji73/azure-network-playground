param location string = resourceGroup().location
param logAnalyticsWorkspaceId string

var spoke02ClientSubnetNsgName = 'spoke02ClientSubnetNsg'

resource spoke02ClientSubnetNsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: spoke02ClientSubnetNsgName
  location: location
  properties: {
    securityRules: []
  }
}

resource spoke02ClientSubnetNsgDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-loganalytics'
  scope: spoke02ClientSubnetNsg
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

output spoke02ClientSubnetNsgId string = spoke02ClientSubnetNsg.id

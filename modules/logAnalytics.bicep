param location string = resourceGroup().location
var logAnalyticsName = 'logAnalytics-${uniqueString(resourceGroup().name)}'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

output logAnalyticsWorkspaceId string = logAnalytics.id

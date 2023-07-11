param location string = resourceGroup().location
param logAnalyticsWorkspaceId string = '7728171c-c8eb-4bf3-8fb0-03b15cc49222'
param nsgResourceIds array
param storageAccountResourceId string

var networkWatcherName = 'NetworkWatcher_${location}'
var nsgFlowLogConfigs = [for nsgId in nsgResourceIds: {
  nsgResourceId: nsgId
  nsgFlowLogName: '${split(nsgId, '/')[8]}FlowLog'
}]

resource nsgFlowlog 'Microsoft.Network/networkWatchers/flowLogs@2022-07-01' = [for (nsgFlowLogConfig, i) in nsgFlowLogConfigs: {
  name: '${networkWatcherName}/${nsgFlowLogConfig.nsgFlowLogName}'
  location: location
  properties: {
    enabled: true
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        trafficAnalyticsInterval: 10
        workspaceRegion: location
        workspaceResourceId: logAnalyticsWorkspaceId
      }
    }
    format: {
      type: 'JSON'
      version: 2
    }
    retentionPolicy: {
      days: 0
      enabled: false
    }
    storageId: storageAccountResourceId
    targetResourceId: nsgFlowLogConfig.nsgResourceId
  }
}]

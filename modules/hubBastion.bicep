param location string = resourceGroup().location
param existingHubVnetName string = 'hubVnet'
param existingBastionSubnetName string = 'AzureBastionSubnet'
param logAnalyticsWorkspaceId string = '/subscriptions/0bd1c23d-2bb8-4931-8c18-dbe32218ddc8/resourceGroups/test/providers/Microsoft.OperationalInsights/workspaces/logAnalytics-rbgf3xv4ufgzg'

var hubBastionPipName = 'hubBastionPip'
var hubBastionName = 'hubBastion'
var hubBastiondiagnosticSettingsName = 'sendLogAnalytics'

resource existingHubVnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingHubVnetName
  resource existingBastionSubnet 'subnets' existing = {
    name: existingBastionSubnetName
  }
}

resource hubBastionPip 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: hubBastionPipName
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

resource hubBastion 'Microsoft.Network/bastionHosts@2022-11-01' = {
  name: hubBastionName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    //scaleUnits: 2
    //enableTunneling: true
    //enableIpConnect: false
    //disableCopyPaste: false
    //enableShareableLink: true
    //enableKerberos: false
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: hubBastionPip.id
          }
          subnet: {
            id: existingHubVnet::existingBastionSubnet.id
          }
        }
      }
    ]
  }
}

resource hubBastiondiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: hubBastiondiagnosticSettingsName
  scope: hubBastion
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

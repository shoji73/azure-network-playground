param location string = resourceGroup().location
param remoteVnetSpace string = '172.16.0.0/16'
param remoteVnetGatewaySubnetSpace string = '172.16.0.0/26'
param remoteVnetClientSubnetSpace string = '172.16.1.0/24'
param hubVnetSpace string = '10.0.0.0/16'
param hubVnetGatewaySubnetSpace string = '10.0.0.0/26'
param hubVnetAzureFirewallSubnetSpace string = '10.0.0.64/26'
param hubVnetAzureBastionSubnetSpace string = '10.0.0.128/26'
param hubPrivateEndpointSubnetSpace string = '10.0.0.192/26'
param hubAzureFirewallPrivateAddress string = '10.0.0.68'
param hubAppGwPrivateEndpointAddress string = '10.0.0.196'
param hubLbPrivateEndpointAddress string = '10.0.0.197'
param spoke01VnetSpace string = '10.1.0.0/16'
param spoke01VnetApplicationGatewaySubnetSpace string = '10.1.0.0/24'
param spoke01VnetPrivateLinkSubnetSpace string = '10.1.1.0/24'
param spoke01VnetApplicationServerSubnetSpace string = '10.1.2.0/24'
param appGwFrontendIpAddress string = '10.1.0.4'
param spoke01LbFrontendIpAddress string = '10.1.2.4'
param spoke02VnetSpace string = '10.2.0.0/16'
param spoke02VnetClientSubnetSpace string = '10.2.0.0/24'
param isBastionDeploy bool = true
param vmAdminUserName string
@secure()
param vmAdminUserPassword string

module logAnalyticsModule 'modules/logAnalytics.bicep' = {
  name: 'logAnalyticsModule'
  params: {
    location: location
  }
}

module hubVnetNsgModule 'modules/hubNsg.bicep' = {
  name: 'hubVnetNsgModule'
  params: {
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
  }
}

module spoke01VnetNsgModule 'modules/spoke01Nsg.bicep' = {
  name: 'spoke01VnetNsgModule'
  params: {
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
  }
}

module spoke02VnetNsgModule 'modules/spoke02Nsg.bicep' = {
  name: 'spoke02VnetNsgModuke'
  params: {
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
  }
}

module remoteVnetNsgModule 'modules/remoteNsg.bicep' = {
  name: 'remoteVnetNsgModuke'
  params: {
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
  }
}

module remoteVnetModule 'modules/remoteVnet.bicep' = {
  name: 'remoteVnetModule'
  params: {
    location: location
    remoteVnetSpace: remoteVnetSpace
    remoteVnetGatewaySubnetSpace: remoteVnetGatewaySubnetSpace
    remoteVnetClientSubnetSpace: remoteVnetClientSubnetSpace
    remoteClientSubnetNsgId: remoteVnetNsgModule.outputs.remoteClientSubnetNsgId
  }
}

module remoteGwModule 'modules/remoteVpnGw.bicep' = {
  name: 'remoteVpnGwModule'
  params: {
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    existingRemoteVnetName: remoteVnetModule.outputs.remoteVnetName
    existingGatewaySubnetName: remoteVnetModule.outputs.gatewaySubnetName
  }
}

module remoteVmModule 'modules/remoteVm.bicep' = {
  name: 'remoteVmModule'
  params: {
    location: location
    existingRemoteVnetName: remoteVnetModule.outputs.remoteVnetName
    existingClientSubnetName: remoteVnetModule.outputs.clientSubnetName
    vmAdminUserName: vmAdminUserName
    vmAdminUserPassword: vmAdminUserPassword
  }
}

module hubVnetModule 'modules/hubVnet.bicep' = {
  name: 'hubVnetModule'
  params: {
    location: location
    hubVnetSpace: hubVnetSpace
    hubVnetGatewaySubnetSpace: hubVnetGatewaySubnetSpace
    hubVnetAzureFirewallSubnetSpace: hubVnetAzureFirewallSubnetSpace
    hubVnetAzureBastionSubnetSpace: hubVnetAzureBastionSubnetSpace
    hubPrivateEndpointSubnetSpace: hubPrivateEndpointSubnetSpace
    spoke01VnetSpace: spoke01VnetSpace
    spoke02VnetSpace: spoke02VnetSpace
    hubAfwPrivateIpAddress: hubAzureFirewallPrivateAddress
    hubBastionSubnetNsgId: hubVnetNsgModule.outputs.hubBastionSubnetNsgId
    hubPrivateEndpointNsgId: hubVnetNsgModule.outputs.hubPrivateEndpointSubnetNsgId
  }
}

module hubGwModule 'modules/hubVpnGw.bicep' = {
  name: 'hubVpnGwModule'
  params: {
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    existingHubVnetName: hubVnetModule.outputs.hubVnetName
    existingGatewaySubnetName: hubVnetModule.outputs.gatewaySubnetName
  }
}

module hubAfwModule 'modules/hubAfw.bicep' = {
  name: 'hubAfwModule'
  params: {
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    existingHubVnetName: hubVnetModule.outputs.hubVnetName
    existingAzureFirewallSubnetName: hubVnetModule.outputs.azureFirewallSubnetName
    existingSpoke01VnetName: spoke01VnetModule.outputs.spoke01VnetName
    existingSpoke02VnetName: spoke02VnetModule.outputs.spoke02VnetName
    existingRemoteVnetName: remoteVnetModule.outputs.remoteVnetName
  }
}

module hubBastionModule 'modules/hubBastion.bicep' = if (isBastionDeploy == true) {
  name: 'hubBastionModule'
  params: {
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    existingHubVnetName: hubVnetModule.outputs.hubVnetName
    existingBastionSubnetName: hubVnetModule.outputs.azureBastionSubnetName
  }
}

module spoke01VnetModule 'modules/spoke01Vnet.bicep' = {
  name: 'spoke01VnetModule'
  params: {
    location: location
    spoke01VnetSpace: spoke01VnetSpace
    spoke02VnetSpace: spoke02VnetSpace
    remoteVnetSpace: remoteVnetSpace
    spoke01VnetApplicationGatewaySubnetSpace: spoke01VnetApplicationGatewaySubnetSpace
    spoke01VnetApplicationServerSubnetSpace: spoke01VnetApplicationServerSubnetSpace
    spoke01VnetPrivateLinkSubnetSpace: spoke01VnetPrivateLinkSubnetSpace
    hubAfwPrivateIpAddress: hubAzureFirewallPrivateAddress
    appGwSubnetNsgId: spoke01VnetNsgModule.outputs.appGwSubnetNsgId
    privateLinkSubnetNsgId: spoke01VnetNsgModule.outputs.privateLinkSubnetNsgId
    applicationServerSubnetNsgId: spoke01VnetNsgModule.outputs.applicationServerSubnetNsgId
  }
}

module spoke01AppGwModule 'modules/spoke01AppGw.bicep' = {
  name: 'spoke01AppGwModule'
  params: {
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    existingSpoke01VnetName: spoke01VnetModule.outputs.spoke01VnetName
    appGwFrontendIpAddress: appGwFrontendIpAddress
    hubAppGwPrivateEndpointAddress: hubAppGwPrivateEndpointAddress
    existingApplicationGatewaySubnetName: spoke01VnetModule.outputs.applicationGatewaySubnetName
    existingHubVnetName: hubVnetModule.outputs.hubVnetName
    existingPrivateEndpointSubnetName: hubVnetModule.outputs.privateEndpointSubnetName
    existingPrivateLinkSubnetName: spoke01VnetModule.outputs.privateLinkSubnetName
  }
}

module spoke01LbModule 'modules/spoke01Lb.bicep' = {
  name: 'spoke01LbModule'
  params: {
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    existingSpoke01VnetName: spoke01VnetModule.outputs.spoke01VnetName
    spoke01LbFrontendIpAddress: spoke01LbFrontendIpAddress
    existingApplicationServerSubnetName: spoke01VnetModule.outputs.applicationServerSubnetName
    existingPrivateLinkSubnetName: spoke01VnetModule.outputs.privateLinkSubnetName
    existingHubVnetName: hubVnetModule.outputs.hubVnetName
    existingPrivateEndpointSubnetName: hubVnetModule.outputs.privateEndpointSubnetName
    hubLbPrivateEndpointAddress: hubLbPrivateEndpointAddress
  }
}

module spoke01VmModule 'modules/spoke01Vm.bicep' = {
  name: 'spoke01VmModule'
  params: {
    location: location
    existingSpoke01VnetName: spoke01VnetModule.outputs.spoke01VnetName
    existingApplicationServerSubnetName: spoke01VnetModule.outputs.applicationServerSubnetName
    appGwBacendAddressPoolId: spoke01AppGwModule.outputs.appGwBacendAddressPoolId
    spoke01LbBackendAddressPoolId: spoke01LbModule.outputs.spoke01LbBackendAddressPoolId
    vmAdminUserName: vmAdminUserName
    vmAdminUserPassword: vmAdminUserPassword
  }
}

module spoke02VnetModule 'modules/spoke02Vnet.bicep' = {
  name: 'spoke02VnetModule'
  params: {
    location: location
    spoke01VnetSpace: spoke01VnetSpace
    spoke02VnetSpace: spoke02VnetSpace
    remoteVnetSpace: remoteVnetSpace
    spoke02VnetClientSubnetSpace: spoke02VnetClientSubnetSpace
    hubAfwPrivateIpAddress: hubAzureFirewallPrivateAddress
    spoke02ClientSubnetNsgId: spoke02VnetNsgModule.outputs.spoke02ClientSubnetNsgId
  }
}

module spoke02VmModule 'modules/spoke02Vm.bicep' = {
  name: 'spoke02VmModule'
  params: {
    location: location
    existingSpoke02VnetName: spoke02VnetModule.outputs.spoke02VnetName
    existingClientSubnetName: spoke02VnetModule.outputs.clientSubnetName
    vmAdminUserName: vmAdminUserName
    vmAdminUserPassword: vmAdminUserPassword
  }
}

module peering 'modules/peering.bicep' = {
  name: 'peeringModule'
  params: {
    existingHubVnetName: hubVnetModule.outputs.hubVnetName
    existingSpoke01VnetName: spoke01VnetModule.outputs.spoke01VnetName
    existingSpoke02VnetName: spoke02VnetModule.outputs.spoke02VnetName
  }
  dependsOn: [
    hubGwModule
  ]
}

module vpnConnection 'modules/vpnConnection.bicep' = {
  name: 'vpnConnectionModule'
  params: {
    location: location
    hubVnetSpace: hubVnetSpace
    spoke01VnetSpace: spoke01VnetSpace
    spoke02VnetSpace: spoke02VnetSpace
    remoteVnetSpace: remoteVnetSpace
    existingHubVpnGwPipName: hubGwModule.outputs.hubVpnGwPipName
    existingRemoteVpnGwPipName: remoteGwModule.outputs.remoteVpnGwPipName
    existingHubVpnGwName: hubGwModule.outputs.hubVpnGwName
    existingRemoteVpnGwName: remoteGwModule.outputs.remoteVpnGwName
  }
}

module connectionMonitor 'modules/connectionMonitor.bicep' = {
  name: 'connectionMonitorModule'
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    location: location
    vnetResourceGroupName : resourceGroup().name
    existingRemoteVnetName: remoteVnetModule.outputs.remoteVnetName
    existingRemoteClientSubnetName: remoteVnetModule.outputs.clientSubnetName
    existingSpoke01VnetName: spoke01VnetModule.outputs.spoke01VnetName
    existingApplicationServerSubnetName: spoke01VnetModule.outputs.applicationServerSubnetName
    existingSpoke02VnetName: spoke02VnetModule.outputs.spoke02VnetName
    existingSpoke02ClientSubnet: spoke02VnetModule.outputs.clientSubnetName
    hubLbPrivateEndpointAddress: hubLbPrivateEndpointAddress
    hubAppGwPrivateEndpointAddress: hubAppGwPrivateEndpointAddress
    appGwFrontendIpAddress: appGwFrontendIpAddress
    spoke01LbFrontendIpAddress: spoke01LbFrontendIpAddress
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    spoke01VmModule
    spoke02VmModule
    remoteVmModule
  ]
}

module storageAccountModule 'modules/storageAccount.bicep' = {
  name: 'storageAccountModule'
  params: {
    location: location
  }
}

module nsgFlowLogModule 'modules/nsgFlowlog.bicep' = {
  name: 'nsgFlowLogModule'
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    nsgResourceIds: [
      hubVnetNsgModule.outputs.hubBastionSubnetNsgId
      hubVnetNsgModule.outputs.hubPrivateEndpointSubnetNsgId
      spoke01VnetNsgModule.outputs.appGwSubnetNsgId
      spoke01VnetNsgModule.outputs.privateLinkSubnetNsgId
      spoke01VnetNsgModule.outputs.applicationServerSubnetNsgId
      spoke02VnetNsgModule.outputs.spoke02ClientSubnetNsgId
      remoteVnetNsgModule.outputs.remoteClientSubnetNsgId
    ]
    storageAccountResourceId: storageAccountModule.outputs.storageAccountId
  }
}

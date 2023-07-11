param location string = resourceGroup().location
param existingSpoke01VnetName string
param existingApplicationGatewaySubnetName string
param existingPrivateLinkSubnetName string 
param appGwFrontendIpAddress string = '192.168.0.4'
param hubAppGwPrivateEndpointAddress string
param logAnalyticsWorkspaceId string
param existingHubVnetName string
param existingPrivateEndpointSubnetName string

var appGwName = 'spoke01AppGw'
var appGwFrontendPortName = 'port_80'
var appGwPublicFrontendIpName = 'appGwPublicFrontendIp'
var appGwPrivateFrontendIpName = 'appGwPrivateFrontendIp'
var appGwBackendAddressPoolName = 'myBackendPool'
var appGwBackendHttpSettingName = 'myHTTPSetting'
var appGwHttpListenerName = 'httpListeners'
var appGwProbeName = 'probe'
var appGwPipName = 'spoke01AppGwPip'
var appGwDiagnosticSettingsName = 'send-loganalytics'
var appGwWafPolicyName = 'spoke01AppGwWafPolicy'
var spoke01PrivateEndpointName = 'spoke01AppGwPrivateEndpoint'
var privateLinkConfigurationName = 'privateLinkConfiguration'
var appGwPrivateEndpointNicName = 'spoke01AppGwPrivateEndpointNic'

resource existingHubVnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingHubVnetName
  resource existingPrivateEndpointSubnet 'subnets' existing = {
    name: existingPrivateEndpointSubnetName
  }
}

resource existingSpoke01Vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingSpoke01VnetName
  resource existingApplicationGatewaySubnet 'subnets' existing = {
    name: existingApplicationGatewaySubnetName
  }
  resource existingPrivateLinkSubnet 'subnets' existing = {
    name: existingPrivateLinkSubnetName
  }
}

resource appGwPip 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: appGwPipName
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

resource appGw 'Microsoft.Network/applicationGateways@2022-11-01' = {
  name: appGwName
  location: location
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 1
    }
    gatewayIPConfigurations: [
      {
        name: 'appGwPriveFrontendIp'
        properties: {
          subnet: {
            id: existingSpoke01Vnet::existingApplicationGatewaySubnet.id
          }
        }
      }

    ]
    frontendIPConfigurations: [
      {
        name: appGwPrivateFrontendIpName
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: existingSpoke01Vnet::existingApplicationGatewaySubnet.id
          }
          privateIPAddress: appGwFrontendIpAddress
          privateLinkConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/privateLinkConfigurations',appGwName, privateLinkConfigurationName)
          }
        }
      }
      {
        name: appGwPublicFrontendIpName
        properties: {
          publicIPAddress: {
            id: appGwPip.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: appGwFrontendPortName
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: appGwBackendAddressPoolName
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: appGwBackendHttpSettingName
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 20
          pickHostNameFromBackendAddress: true
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGwName, appGwProbeName)
          }
        }
      }
    ]
    httpListeners: [
      {
        name: appGwHttpListenerName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwName, appGwPrivateFrontendIpName)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwName, appGwFrontendPortName)
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'myRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 10010
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwName, appGwHttpListenerName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwName, appGwBackendAddressPoolName)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwName, appGwBackendHttpSettingName)
          }
        }
      }
    ]
    probes: [
      {
        name: appGwProbeName
        properties: {
          protocol: 'Http'
          path: '/status/200'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
        }
      }
    ]
    privateLinkConfigurations: [ {
        name: privateLinkConfigurationName
        properties: {
          ipConfigurations: [ {
              name: 'ipConfiguration'
              properties: {
                subnet: {
                  id: existingSpoke01Vnet::existingPrivateLinkSubnet.id
                }
                privateIPAllocationMethod: 'Dynamic'
              } 
            }
          ]
        }
      }
    ]
    enableHttp2: false
    firewallPolicy: {
      id: wafpolicy.id
    }
  }
}

resource spoke01AppGwPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  location: location
  name: spoke01PrivateEndpointName
  properties: {
    subnet: {
      id: existingHubVnet::existingPrivateEndpointSubnet.id
    }
    ipConfigurations: [
      {
        name: spoke01PrivateEndpointName
        properties: {
          //groupId:appGwPrivateFrontendIpName
          //memberName: appGwPrivateFrontendIpName
          privateIPAddress: hubAppGwPrivateEndpointAddress
        }
      }
    ]
    customNetworkInterfaceName: appGwPrivateEndpointNicName
    privateLinkServiceConnections: [
      {
        name: spoke01PrivateEndpointName
        properties: {
          privateLinkServiceId: appGw.id
          groupIds: [appGwPrivateFrontendIpName]
        }
      }
    ]
  }
}

resource appGwDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: appGwDiagnosticSettingsName
  scope: appGw
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

resource wafpolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2021-08-01' = {
  name: appGwWafPolicyName
  location: location
  tags: {}
  properties: {
    policySettings: {
      mode: 'Prevention'
      state: 'Enabled'
      fileUploadLimitInMb: 100
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
    }
    managedRules: {
      exclusions: []
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
          ruleGroupOverrides: null
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '0.1'
          ruleGroupOverrides: null
        }
      ]
    }
    customRules: []
  }
}

output appGwBacendAddressPoolId string = resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwName, appGwBackendAddressPoolName)
output appGwName string = appGw.name
output privatelinkFrontEndIpConfigName string = appGwPrivateFrontendIpName

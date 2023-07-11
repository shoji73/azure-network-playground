param location string = resourceGroup().location
param existingSpoke01VnetName string
param existingApplicationServerSubnetName string
param vmSize string = 'Standard_F2s_v2'
param appGwBacendAddressPoolId string
param spoke01LbBackendAddressPoolId string
param vmAdminUserName string = 'azureadmin'
@secure()
param vmAdminUserPassword string

var vmCount = 2
var vmNames = [for i in range(0, vmCount): 'spoke01AppVm${i}']


resource existingSpoke01Vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingSpoke01VnetName
  resource existingApplicationServerSubnet 'subnets' existing = {
    name: existingApplicationServerSubnetName
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}Nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: existingSpoke01Vnet::existingApplicationServerSubnet.id
          }
          applicationGatewayBackendAddressPools: [
            {
              id: appGwBacendAddressPoolId
            }
          ]
          loadBalancerBackendAddressPools: [
            {
              id: spoke01LbBackendAddressPoolId
            }
          ]
        }
      }
    ]
  }
}]

resource virtualMachines 'Microsoft.Compute/virtualMachines@2021-04-01' = [for (vmName, i) in vmNames: {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: '20.04.202305150'
      }
      osDisk: {
        createOption: 'FromImage'
        name: '${vmName}OsDisk'
        diskSizeGB: 32
        deleteOption: 'Detach'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUserName
      adminPassword: vmAdminUserPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}]

resource vmExtensionSetupApp 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}SetupApp'
  location: location
  parent: virtualMachines[i]
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      skipDos2Unix:false
      timestamp:123456789          
    }
    protectedSettings: {
      // Enter src/appServerSetup.sh encoded in base64
      // For example, base64 -w 0 src/appServerSetup.sh
      script: 'IyEvYmluL3NoCnN1ZG8gYXB0IHVwZGF0ZQpzdWRvIGFwdCB1cGdyYWRlIC15CnN1ZG8gYXB0IGluc3RhbGwgYXB0LXRyYW5zcG9ydC1odHRwcyBjYS1jZXJ0aWZpY2F0ZXMgY3VybCBzb2Z0d2FyZS1wcm9wZXJ0aWVzLWNvbW1vbiAteQpjdXJsIC1mc1NMIGh0dHBzOi8vZG93bmxvYWQuZG9ja2VyLmNvbS9saW51eC91YnVudHUvZ3BnIHwgc3VkbyBhcHQta2V5IGFkZCAtCnN1ZG8gYWRkLWFwdC1yZXBvc2l0b3J5ICJkZWIgW2FyY2g9YW1kNjRdIGh0dHBzOi8vZG93bmxvYWQuZG9ja2VyLmNvbS9saW51eC91YnVudHUgZm9jYWwgc3RhYmxlIgpzdWRvIGFwdCB1cGRhdGUKc3VkbyBhcHQgaW5zdGFsbCBkb2NrZXItY2UgLXkKc3VkbyBzeXN0ZW1jdGwgZW5hYmxlIGRvY2tlcgpzdWRvIGRvY2tlciBwdWxsIGtlbm5ldGhyZWl0ei9odHRwYmluCnN1ZG8gZG9ja2VyIHJ1biAtLXJlc3RhcnQ9YWx3YXlzIC1kIC1wIDgwOjgwIGtlbm5ldGhyZWl0ei9odHRwYmlu'
    }
  }
}]




param location string = resourceGroup().location
param existingSpoke02VnetName string
param existingClientSubnetName string
param vmSize string = 'Standard_F2s_v2'
param vmAdminUserName string = 'azureadmin'
@secure()
param vmAdminUserPassword string

var vmCount = 1
var vmNames = [for i in range(0, vmCount): 'spoke02ClientVm${i}']

resource existingSpoke02Vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingSpoke02VnetName
  resource existingApplicationServerSubnet 'subnets' existing = {
    name: existingClientSubnetName
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
            id: existingSpoke02Vnet::existingApplicationServerSubnet.id
          }
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

resource vmName_AzureNetworkWatcherExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for (vmName, i) in vmNames: {
  name: '${vmName}AzureNetworkWatcherExtension'
  location: location
  parent: virtualMachines[i]
  properties: {
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentLinux'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
    settings: {}
  }
}]


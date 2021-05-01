param vmName string
param location string
param insideSubnetId string
param outsideSubnetId string
param enableForwarding bool = false
param createPublicIpNsg bool = false
param enableCloudInit bool = false
@secure()
param adminPassword string

module nicInside 'nic.bicep' = {
  name: '${vmName}-inside'
  params: {
    location: location
    nicName: '${vmName}-inside'
    subnetId: insideSubnetId
    enableForwarding: enableForwarding
    vmName: vmName
  }
}

module nicOutside 'nic.bicep' = {
  name: '${vmName}-outside'
  params: {
    location: location
    nicName: '${vmName}-outside'
    subnetId: outsideSubnetId
    enableForwarding: enableForwarding
    createPublicIpNsg: createPublicIpNsg
    vmName: vmName
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  plan: {
    publisher: 'cisco'
    product: 'cisco-csr-1000v'
    name: '17_3_2-byol'
  }
  properties: {
    osProfile: {
      adminUsername: 'azureuser'
      adminPassword: adminPassword
      computerName: vmName
    }
    hardwareProfile: {
      vmSize: 'Standard_D2_v3'
    }
    storageProfile: {
      imageReference: {
        offer: 'cisco-csr-1000v'
        publisher: 'cisco'
        sku: '17_3_2-byol'
        version: 'latest'
      }
      osDisk: {
        createOption:'FromImage'
        diskSizeGB: 30
        caching:'ReadWrite'
        managedDisk: {
          storageAccountType:'Standard_LRS'
        }
        name: '${vmName}-osDisk'
        osType:'Linux'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary:true
          }
          id: nicOutside.outputs.nicId
        }
        {
          properties: {
            primary:false
          }
          id: nicInside.outputs.nicId
        }
      ]
    }
  }
}

resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status:'Enabled'
    dailyRecurrence:{
      time: '2100'
    }
    notificationSettings: {
      status:'Disabled'
    }
    taskType: 'ComputeVmShutdownTask'
    targetResourceId: vm.id
    timeZoneId: 'GMT Standard Time'
  }
}

output nicOutsidePrivateIp string = nicOutside.outputs.nicPrivateIp
output nicInsidePrivateIp string = nicInside.outputs.nicPrivateIp
output nicOutsidePublicIp string = nicOutside.outputs.nicPublicIp

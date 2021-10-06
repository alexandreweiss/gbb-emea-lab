param vmName string
param location string
param nic0SubnetId string
param nic1SubnetId string
//param nic2SubnetId string
param enableForwarding bool = false
param createPublicIpNsg bool = false
param enableCloudInit bool = false
param nic0BackendPoolId string
param nic1BackendPoolId string
param mySourceIp string = '10.0.0.1'

module nic0 'nic4lb.bicep' = {
  name: '${vmName}-nic0'
  params: {
    location: location
    nicName: '${vmName}-nic0'
    subnetId: nic0SubnetId
    enableForwarding: enableForwarding
    createPublicIpNsg: createPublicIpNsg
    vmName: vmName
    mySourceIp: mySourceIp
    backendPoolId: nic0BackendPoolId
  }
}

module nic1 'nic4lb.bicep' = {
  name: '${vmName}-nic1'
  params: {
    location: location
    nicName: '${vmName}-nic1'
    subnetId: nic1SubnetId
    enableForwarding: enableForwarding
    createPublicIpNsg: createPublicIpNsg
    vmName: vmName
    mySourceIp: mySourceIp
    backendPoolId: nic1BackendPoolId
  }
}

// module nic2 '../../_modules/nic.bicep' = {
//   name: '${vmName}-nic2'
//   params: {
//     location: location
//     nicName: '${vmName}-nic2'
//     subnetId: nic2SubnetId
//     enableForwarding: enableForwarding
//     createPublicIpNsg: createPublicIpNsg
//     vmName: vmName
//     mySourceIp: mySourceIp
//   }
// }

resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  properties: {
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    osProfile: {
      customData: enableCloudInit ? 'I2luY2x1ZGUKaHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2FsZXhhbmRyZXdlaXNzL2diYi1lbWVhLWxhYi9kZXZlbG9wL3Z3YW4tbGFiL2NvbmZpZy1maWxlcy92bS1udmEtZnJjLWNpLnRwbA==' : json('null')
      adminUsername: 'admin-lab'
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/admin-lab/.ssh/authorized_keys'
              keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQBsUy8OllCkhpOU4FplN1b7ypawC/8QM++3gb9EbqZHCJnJdTNhk/0QZVvGsPvWeSazsShgX2TdEMMdDFscWDdAfnoB+hyjhFyWaOfKXFdzafib3HrO0rGUPqW42V6d0N2V5rh23ZFZGX5Bp75KEFnrFgGY1axCebvMvStGzXXffole1sCt0SKbvFptc/MT/ZVSqT0i0ugS0dVXsb4kuo4qnNRUAqvunljDL5oS3ZT7bQtjAvcw+IyYF6Ka9pGc4EuNaYZ2YuaxMyMOKYoMq4Qz8Qk5oF34ATGCPC0SdAgtAByNblbYeB6s+ueWUwSEcKOfIKjl9lxJasCRBRkjl7zp non-prod-test'
            }
          ]
        }
      }
      computerName: vmName
    }
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    storageProfile: {
      imageReference: {
        offer: 'UbuntuServer'
        publisher: 'Canonical'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption:'FromImage'
        diskSizeGB: 30
        caching:'ReadWrite'
        managedDisk: {
          storageAccountType:'Premium_LRS'
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
          id: nic0.outputs.nicId
        }
        {
          properties: {
            primary:false
          }
          id: nic1.outputs.nicId
        }
        // {
        //   properties: {
        //     primary:false
        //   }
        //   id: nic2.outputs.nicId
        // }
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

output nic0PrivateIp string = nic0.outputs.nicPrivateIp
output nic1PrivateIp string = nic1.outputs.nicPrivateIp
// output nic2PrivateIp string = nic2.outputs.nicPrivateIp

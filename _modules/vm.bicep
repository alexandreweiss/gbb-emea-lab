param vmName string
param location string
param subnetId string
param enableForwarding bool = false
param createPublicIpNsg bool = false
param enableCloudInit bool = false
param cloudInitValue string = 'I2luY2x1ZGUKaHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2FsZXhhbmRyZXdlaXNzL2diYi1lbWVhLWxhYi9tYXN0ZXIvdndhbi1sYWIvY29uZmlnLWZpbGVzL3ZtLW52YS1mcmMtY2kudHBs'
param mySourceIp string = '10.0.0.1'
param lbBackendPoolId string = 'no'
param sshKeyValue string = 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQBsUy8OllCkhpOU4FplN1b7ypawC/8QM++3gb9EbqZHCJnJdTNhk/0QZVvGsPvWeSazsShgX2TdEMMdDFscWDdAfnoB+hyjhFyWaOfKXFdzafib3HrO0rGUPqW42V6d0N2V5rh23ZFZGX5Bp75KEFnrFgGY1axCebvMvStGzXXffole1sCt0SKbvFptc/MT/ZVSqT0i0ugS0dVXsb4kuo4qnNRUAqvunljDL5oS3ZT7bQtjAvcw+IyYF6Ka9pGc4EuNaYZ2YuaxMyMOKYoMq4Qz8Qk5oF34ATGCPC0SdAgtAByNblbYeB6s+ueWUwSEcKOfIKjl9lxJasCRBRkjl7zp non-prod-test'

@secure()
param adminPassword string = 'NA'

@allowed([
  'Enabled'
  'Disabled'
])
param autoShutdownStatus string = 'Enabled'

@allowed([
  'desktop'
  'server'
])
param osType string = 'server'

// var osServer = {
//   publisher: 'MicrosoftWindowsServer'
//   offer: 'WindowsServer'
//   sku: '2019-Datacenter'
//   version: 'latest'
// }

var osServer = {
  offer: 'UbuntuServer'
  publisher: 'Canonical'
  sku: '18.04-LTS'
  version: 'latest'
}

var osDesktop = {
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'Windows-10'
  sku: '20h2-ent'
  version: 'latest'
}

var winOsProfile = {
  customData: enableCloudInit ? cloudInitValue : json('null')
  adminUsername: 'admin-lab'
  adminPassword: adminPassword
  computerName: vmName
}

var linuxOsProfile = {
  customData: enableCloudInit ? cloudInitValue : json('null')
  adminUsername: 'admin-lab'
  linuxConfiguration: {
    disablePasswordAuthentication: true
    ssh: {
      publicKeys: [
        {
          path: '/home/admin-lab/.ssh/authorized_keys'
          keyData: sshKeyValue
        }
      ]
    }
  }
  computerName: vmName
}

module nic 'nic.bicep' = {
  name: '${vmName}-nic'
  params: {
    location: location
    nicName: '${vmName}-nic'
    subnetId: subnetId
    enableForwarding: enableForwarding
    createPublicIpNsg: createPublicIpNsg
    vmName: vmName
    mySourceIp: mySourceIp
    lbBackendPoolId: lbBackendPoolId
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  tags: {
    'includeInUpdates': 'true'
  }
  properties: {
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    osProfile: osType == 'server' ? linuxOsProfile : winOsProfile

    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    storageProfile: {
      imageReference: osType == 'desktop' ? osDesktop : osServer
      osDisk: {
        createOption:'FromImage'
        diskSizeGB: osType == 'desktop' ? 127 : 30
        caching:'ReadWrite'
        managedDisk: {
          storageAccountType:'Premium_LRS'
        }
        name: '${vmName}-osDisk'
        osType: osType == 'desktop' ? 'Windows' : 'Linux'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary:true
          }
          id: nic.outputs.nicId
        }
      ]
    }
  }
}

resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status: autoShutdownStatus
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

output nicPrivateIp string = nic.outputs.nicPrivateIp
output nicPublicFqdn string = nic.outputs.nicPublicFqdn

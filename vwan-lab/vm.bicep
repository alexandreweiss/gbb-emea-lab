param vmName string
param location string
param subnetId string

module nic 'nic.bicep' = {
  name: '${vmName}-nic'
  params: {
    location: location
    nicName: '${vmName}-nic'
    subnetId: subnetId
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  properties: {
    osProfile: {
      adminUsername: 'admin-lab'
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQBsUy8OllCkhpOU4FplN1b7ypawC/8QM++3gb9EbqZHCJnJdTNhk/0QZVvGsPvWeSazsShgX2TdEMMdDFscWDdAfnoB+hyjhFyWaOfKXFdzafib3HrO0rGUPqW42V6d0N2V5rh23ZFZGX5Bp75KEFnrFgGY1axCebvMvStGzXXffole1sCt0SKbvFptc/MT/ZVSqT0i0ugS0dVXsb4kuo4qnNRUAqvunljDL5oS3ZT7bQtjAvcw+IyYF6Ka9pGc4EuNaYZ2YuaxMyMOKYoMq4Qz8Qk5oF34ATGCPC0SdAgtAByNblbYeB6s+ueWUwSEcKOfIKjl9lxJasCRBRkjl7zp non-prod-test'
            }
          ]
        }
      }
      computerName: vmName
    }
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    storageProfile: {
      imageReference: {
        offer: 'UbuntuServer'
        publisher: 'Canonical'
        sku: '20_04-lts-gen2'
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
          id: nic.outputs.nicId
        }
      ]
    }
  }
}


param location string = 'westeurope'
param mySourceIp string = '90.45.75.202'

module segmentationVnet '../_modules/vnetMultiSubnets.bicep' = {
  name: 'segmentation-vnet'
  params: {
    vnetName: 'segmentation'
    location: location
    addressSpace: '10.0.1.0/24'
    subnets: [
      {
        name: 'front'
        addressPrefix: '10.0.1.0/28'
        delegations: []
      }
      {
        name: 'middle'
        addressPrefix: '10.0.1.16/28'
        delegations: []
      }
      {
        name: 'back'
        addressPrefix: '10.0.1.32/28'
        delegations: []
      }
      {
        name: 'client'
        addressPrefix: '10.0.1.48/28'
        delegations: []
      }
    ]
  }
}

module frontVm '../_modules/vm.bicep' = {
  name: 'frontvm'
  params: {
    location: location
    subnetId: segmentationVnet.outputs.subnets[0].id
    vmName: 'frontvm'
    cloudInitValue: loadFileAsBase64('./config-file/config-front.tpl')
    createPublicIpNsg: true
    enableCloudInit: true
    mySourceIp: mySourceIp
  }
}

module middleVm '../_modules/vm.bicep' = {
  name: 'middlevm'
  params: {
    location: location
    subnetId: segmentationVnet.outputs.subnets[0].id
    vmName: 'middlevm'
    cloudInitValue: loadFileAsBase64('./config-file/config-front.tpl')
    createPublicIpNsg: true
    enableCloudInit: true
    mySourceIp: mySourceIp
  }
}

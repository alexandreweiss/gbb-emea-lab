param location string = 'westeurope'
param mySourceIp string = '80.215.0.0/16'

module vnetBack '../_modules/vnet.bicep' = {
  name: 'vnetBack'
  params:{
    addressPrefix: '10.0.0.0/29'
    addressSpace: '10.0.0.0/24'
    location: location
    vnetName: 'vnetBack'
  }
}

module vnetClient '../_modules/vnet.bicep' = {
  name: 'vnetClient'
  params:{
    addressPrefix: '10.0.1.0/29'
    addressSpace: '10.0.1.0/24'
    location: location
    vnetName: 'vnetClient'
  }
}

module backVm '../_modules/vm.bicep' = {
  name: 'backvm00'
  params: {
    location: location
    subnetId: vnetBack.outputs.subnetId
    vmName: 'backvm00'
  }
}

module clientVm '../_modules/vm.bicep' = {
  name: 'clientvm00'
  params: {
    location: location
    subnetId: vnetClient.outputs.subnetId
    vmName: 'clientvm00'
    createPublicIpNsg: true
    mySourceIp: mySourceIp
  }
}

module lb '../_modules/lb.bicep' = {
  name: 'ilb'
  params: {
    backendIp: backVm.outputs.nicPrivateIp
    lbName: 'ilb'
    location: location
    subnetId: vnetBack.outputs.subnetId
  }
}

resource backClientPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnetBack.name}/backToClient'
  parent: vnetBack
  properties: {
    remoteVirtualNetwork: {
      id: vnetClient.outputs.vnetId
    }
  }
}

resource clientBackPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnetClient.name}/clientToBack'
  parent: vnetClient
  properties: {
    remoteVirtualNetwork: {
      id: vnetBack.outputs.vnetId
    }
  }
}

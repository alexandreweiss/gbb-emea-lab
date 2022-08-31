param location string = 'westeurope'
@secure()
param erAuthKey string
@secure()
param erCircuitId string

module hub '../_modules/vnetMultiSubnets.bicep' = {
  name: 'hub'
  params: {
    addressSpace: '172.20.20.0/24'
    location: location
    subnets: [
      {
        name: 'RouteServerSubnet'
        addressPrefix: '172.20.20.0/27'
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '172.20.20.32/27'
      }
      {
        name: 'default'
        addressPrefix: '172.20.20.64/28'
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '172.20.20.96/27'
      }
    ]
    vnetName: 'hub'
  }
}

module vpnGw '../_modules/vpngwha.bicep' = {
  name: 'vpnGw'
  dependsOn: [
    routeServer
  ]
  params: {
    asn: 65515
    gwSubnetId: hub.outputs.subnets[3].id
    location: location
    sku: 'HighPerformance'
  }
}

module erGw '../_modules/ergw.bicep' = {
  name: 'erGw'
  dependsOn: [
    routeServer
  ]
  params: {
    erAuthKey: erAuthKey
    erPrivatePeeringCircuitId: erCircuitId
    gwSubnetId: hub.outputs.subnets[3].id
    location: location
    name: 'erGw'
  }
}


module routeServer '../_modules/ars.bicep' = {
  name: 'ars'
  params: {
    location:location
    name: 'ars'
    enableB2b: true
    subnetId: hub.outputs.subnets[0].id
  }
}

module hubVm '../_modules/vm.bicep' = {
  name: 'hubVm'
  params: {
    location: location
    subnetId: hub.outputs.subnets[2].id
    vmName: 'hubVm'
    enableForwarding: true
  }
}

module bastion '../_modules/bastion.bicep' = {
  name: 'bastion'
  params: {
    location: location
    name: 'bastion'
    subnetId: hub.outputs.subnets[1].id 
  }
}


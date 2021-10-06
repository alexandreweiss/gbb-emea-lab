param location string = 'westeurope'
param drLocation string = 'northeurope'
param deployErMain bool = true
param deployDrSite bool = false
param deployBastion bool = false
@secure()
param erAuthKey string
@secure()
param erAuthKey2 string
@secure()
param erPrivatePeeringCircuitId string

// Change the scope to be able to create the resource group before resources
// then we specify scope at resourceGroup level for all others resources
targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'er-lab-0'
  location: location
}

resource rgDr 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'er-dr-lab-0'
  location: location
}

module vnet '../_modules/vnetMultiSubnets.bicep' = {
  name: 'er-hub-vn'
  scope: rg
  params: {
    vnetName: 'er-hub-vn'
    location: location
    addressSpace: '192.168.200.0/24'
    subnets: [
      {
        name: 'GatewaySubnet'
        addressPrefix: '192.168.200.0/27'
      }
      {
        name: 'default'
        addressPrefix: '192.168.200.32/27'
      }
      {
        name: 'AzureBastion'
        addressPrefix: '192.168.200.64/27'
      }
    ]
  }
}

module vnetDr '../_modules/vnetMultiSubnets.bicep' = {
  name: 'er-dr-vn'
  scope: rg
  params: {
    vnetName: 'er-dr-vn'
    location: drLocation
    addressSpace: '192.168.201.0/24'
    subnets: [
      {
        name: 'GatewaySubnet'
        addressPrefix: '192.168.201.0/27'
      }
      {
        name: 'default'
        addressPrefix: '192.168.201.32/27'
      }
      {
        name: 'AzureBastion'
        addressPrefix: '192.168.201.64/27'
      }
    ]
  }
}

module erGw '../_modules/ergw.bicep' = if(deployErMain) {
  name: 'er-gw'
  scope: rg
  params: {
    gwSubnetId: vnet.outputs.subnets[0].id
    location: location
    name: 'er-gw'
    erAuthKey: erAuthKey
    erPrivatePeeringCircuitId: erPrivatePeeringCircuitId
  }
}

module erDrGw '../_modules/ergw.bicep' = if(deployDrSite) {
  name: 'er-dr-gw'
  scope: rgDr
  params: {
    gwSubnetId: vnetDr.outputs.subnets[0].id
    location: drLocation
    name: 'er-dr-gw'
    erAuthKey: erAuthKey2
    erPrivatePeeringCircuitId: erPrivatePeeringCircuitId
  }
}

module vm '../_modules/vm.bicep' = {
  name: 'er-hub-vm'
  scope: rg
  params: {
    location: location
    subnetId: vnet.outputs.subnets[1].id
    vmName: 'er-hub-vm'
  }
}

module nva '../_modules/vm.bicep' = {
  name: 'er-hub-nva'
  scope: rg
  params: {
    location: location
    subnetId: vnet.outputs.subnets[1].id
    vmName: 'er-hub-nva'
  }
}

module bastion '../_modules/bastion.bicep' = if(deployBastion) {
  scope: rg
  name: 'bastion'
  params: {
    location: location
    name: 'bastion'
    subnetId: vnet.outputs.subnets[2].id 
  }
}

module vmDr '../_modules/vm.bicep' =  if(deployDrSite) {
  name: 'er-dr-vm'
  scope: rgDr
  params: {
    location: drLocation
    subnetId: vnetDr.outputs.subnets[1].id
    vmName: 'er-dr-vm'
  }
}


// Location of resources
param location string = 'francecentral'
param drLocation string = 'eastus'

param deployErMain bool = false
param deployMainNva bool = false
param deployMainVm bool = true

// DR site deployment
param deployDrSite bool = false
param deployErDr bool = false
param enableDrPeering bool = false

// Admin
param deployBastion bool = false

// ER circuit info
@secure()
param erAuthKey string
@secure()
param erAuthKey2 string
@secure()
param erCircuitId string

// Change the scope to be able to create the resource group before resources
// then we specify scope at resourceGroup level for all others resources
targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'er-lab-main-1'
  location: location
}

resource rgDr 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'er-lab-dr-1'
  location: drLocation
}

module vnet '../_modules/vnetMultiSubnets.bicep' = {
  name: 'er-main-vn'
  scope: rg
  params: {
    vnetName: 'er-main-vn'
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

module vnetDr '../_modules/vnetMultiSubnets.bicep' = if(deployDrSite) {
  name: 'er-dr-vn'
  scope: rgDr
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

module hubToDrPeering '../_modules/vnet-peering.bicep' = if(enableDrPeering) {
  scope: rg
  name: 'hubToDrPeering'
  params: {
    aSideId: vnet.outputs.vnetId
    aSideName: vnet.name
    bSideId: vnetDr.outputs.vnetId
    bSideName: vnetDr.name
  }
}

module erGw '../_modules/ergw.bicep' = if(deployErMain) {
  name: 'er-main-gw'
  scope: rg
  params: {
    gwSubnetId: vnet.outputs.subnets[0].id
    location: location
    name: 'er-main-gw'
    erAuthKey: erAuthKey
    erPrivatePeeringCircuitId: erCircuitId
  }
}

module erDrGw '../_modules/ergw.bicep' = if(deployErDr) {
  name: 'er-dr-gw'
  scope: rgDr
  params: {
    gwSubnetId: vnetDr.outputs.subnets[0].id
    location: drLocation
    name: 'er-dr-gw'
    erAuthKey: erAuthKey2
    erPrivatePeeringCircuitId: erCircuitId
  }
}

module vm '../_modules/vm.bicep' = if(deployMainVm) {
  name: 'er-main-vm'
  scope: rg
  params: {
    location: location
    subnetId: vnet.outputs.subnets[1].id
    vmName: 'er-main-vm'
  }
}

module nva '../_modules/vm.bicep' = if(deployMainNva) {
  name: 'er-main-nva'
  scope: rg
  params: {
    location: location
    subnetId: vnet.outputs.subnets[1].id
    vmName: 'er-main-nva'
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


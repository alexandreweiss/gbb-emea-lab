param location string = 'westeurope'

// Change the scope to be able to create the resource group before resources
// then we specify scope at resourceGroup level for all others resources
targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'elb-lab'
  location: location
}

module vnet '../_modules/vnetMultiSubnets.bicep' = {
  name: 'vnet'
  scope: rg
  params: {
    addressSpace: '10.78.0.0/24'
    location: location
    subnets: [
      {
        name: 'frontSubnet'
        addressPrefix: '10.78.0.0/28'
      }
      {
        name: 'backSubnet'
        addressPrefix: '10.78.0.16/28'
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.78.0.32/27'
      }
      {
        name: 'admin'
        addressPrefix: '10.78.0.64/28'
      }
    ]
    vnetName: 'vnet'
  }
}

module vm '../_modules/vm.bicep' = {
  name: 'vm-back0'
  scope: rg
  params: {
    location: location
    subnetId: vnet.outputs.subnets[1].id
    vmName: 'vm-back0'
    lbBackendPoolId: elb.outputs.lbBackendId
    createPublicIpNsg: true
  }
}

module elb '../_modules/elb.bicep' = {
  name: 'lb'
  scope: rg
  params: {
    lbName: 'lb'
    location: location
    vnetId: vnet.outputs.vnetId
  }
}

module bastion '../_modules/bastion.bicep' = {
  scope: rg
  name: 'bastion'
  params: {
    location: location
    name: 'bastion'
    subnetId: vnet.outputs.subnets[2].id
  }
}

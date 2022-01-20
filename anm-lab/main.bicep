param usLocation string = 'eastus'
param euLocation string = 'westeurope'

// Change the scope to be able to create the resource group before resources
// then we specify scope at resourceGroup level for all others resources
targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'anm-lab'
  location: usLocation
}

module anm '../_modules/anm.bicep' = {
  scope: rg
  name: 'anm-lab'
  params: {
    location: usLocation
    name: 'anm-lab'
  }
}

module anmConfigA '../_modules/anm-config.bicep' = {
  scope: rg
  name: 'AConfig'
  params: {
    anmName: anm.name
    configName: 'Aconfig'
    topology: 'Mesh'
    groupId: anmGroupA.outputs.anmGroupId
  }
}

module anmConfigB '../_modules/anm-config.bicep' = {
  scope: rg
  name: 'BConfig'
  params: {
    anmName: anm.name
    configName: 'Bconfig'
    topology: 'Mesh'
    groupId: anmGroupB.outputs.anmGroupId
  }
}

module anmGroupA '../_modules/anm-group.bicep' = {
  scope: rg
  name: 'AGroup'
  params: {
    anmName: anm.name
    description: 'vnet from group A'
    membershipCondition: '{"allOf": [{"field": "tags[\'group\']","contains": "A"}]}'
    name: 'Agroup'
   }
}

module anmGroupB '../_modules/anm-group.bicep' = {
  scope: rg
  name: 'BGroup'
  params: {
    anmName: anm.name
    description: 'vnet from group B'
    membershipCondition: '{"allOf": [{"field": "tags[\'group\']","contains": "B"}]}'
    name: 'Bgroup'
   }
}

module vnet1 '../_modules/vnet.bicep' = {
  scope: rg
  name: 'anm-us-vn1'
  params: {
    addressPrefix: '10.1.0.0/24'
    addressSpace: '10.1.0.0/16'
    location: usLocation
    vnetName: 'anm-us-vn1'
    tags : {
      'group': 'A'
    }
  }
}

module vnet2 '../_modules/vnet.bicep' = {
  scope: rg
  name: 'anm-us-vn2'
  params: {
    addressPrefix: '10.2.0.0/24'
    addressSpace: '10.2.0.0/16'
    location: usLocation
    vnetName: 'anm-us-vn2'
    tags : {
      'group': 'A'
    }
  }
}

module vnet3 '../_modules/vnet.bicep' = {
  scope: rg
  name: 'anm-we-vn1'
  params: {
    addressPrefix: '10.3.0.0/24'
    addressSpace: '10.3.0.0/16'
    location: euLocation
    vnetName: 'anm-we-vn1'
    tags : {
      'group': 'B'
    }
  }
}


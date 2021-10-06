// Deploy command
// az group create -n pl-lab -l westeurope
// az deployment group create -n deploy-pl -g pl-lab --template-file main.bicep

param location string = 'westeurope'

module hub '../_modules/vnet.bicep' = {
  name: 'hub'
  params: {
    addressPrefix: '10.0.0.0/28'
    addressSpace: '10.0.0.0/24'
    location: location
    vnetName: 'hub'
  }
}

module spoke '../_modules/vnet.bicep' = {
  name: 'spoke'
  params: {
    addressPrefix: '10.0.1.0/28'
    addressSpace: '10.0.1.0/24'
    location: location
    vnetName: 'spoke'
  }
}

module pl '../_modules/vnet.bicep' = {
  name: 'pl'
  params: {
    addressPrefix: '10.0.2.0/28'
    addressSpace: '10.0.2.0/24'
    location: location
    vnetName: 'pl'
    networkPoliciesState: 'Disabled'
  }
}

resource peeringHubSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${hub.name}/hubToSpoke'
  parent: hub
  properties: {
    remoteVirtualNetwork: {
      id: spoke.outputs.vnetId
    }
  }
}

resource peeringSpokeHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${spoke.name}/spokeToHub'
  parent: spoke
  properties: {
    remoteVirtualNetwork: {
      id: hub.outputs.vnetId
    }
  }
}

resource peeringHubPl 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${hub.name}/hubToPl'
  parent: hub
  properties: {
    remoteVirtualNetwork: {
      id: pl.outputs.vnetId
    }
  }
}

resource peeringPlHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${pl.name}/plToHub'
  parent: pl
  properties: {
    remoteVirtualNetwork: {
      id: hub.outputs.vnetId
    }
  }
}

module sa '../_modules/storageaccount.bicep' = {
  dependsOn: [
    peeringHubPl
    peeringHubSpoke
    peeringPlHub
    peeringSpokeHub
  ]
  name: 'sapl001'
  params: {
    location: location
    name: 'sapl001'
  }
}

resource peSa 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pesapl001'
  location: location
  properties: {
    subnet: {
      id: pl.outputs.subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pesapl001'
        properties: {
          privateLinkServiceId: sa.outputs.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource pe2Sa 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pesapl002'
  location: location
  properties: {
    subnet: {
      id: hub.outputs.subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pesapl002'
        properties: {
          privateLinkServiceId: sa.outputs.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

module spokeVm '../_modules/vm.bicep' = {
  name: 'spokeVm'
  params: {
    location: location
    subnetId: spoke.outputs.subnetId
    vmName: 'spokeVm'
  }
}

module plVm '../_modules/vm.bicep' = {
  name: 'plVm'
  params: {
    location: location
    subnetId: pl.outputs.subnetId
    vmName: 'plVm'
  }
}

module hubVm '../_modules/vm.bicep' = {
  name: 'hubVm'
  params: {
    location: location
    subnetId: hub.outputs.subnetId
    vmName: 'hubVm'
    
  }
}

param location string = 'francecentral'

// Admin

module bastion '../_modules/bastion.bicep' = {
  name: 'bastion'
  params: {
    location: location
    name: 'bastion'
    subnetId: nvaVnet.outputs.subnets[2].id
  }
}

// Networking
module clientVnet './_modules/vnetMultiSubnetsRt.bicep' = {
  name: 'clientVnet'
  params: {
    addressSpace: '10.0.2.0/24'
    location: location
    subnets: [
      {
        name: 'default'
        addressPrefix: '10.0.2.0/28'
        routeTableId: frontRt.id
      }
    ]
    vnetName: 'clientVnet'
  }
}

module nvaVnet './_modules/vnetMultiSubnets.bicep' = {
  name: 'nvaVnet'
  params: {
    addressSpace: '10.0.1.0/24'
    location: location
    subnets: [
      {
        name: 'frontSubnet'
        addressPrefix: '10.0.1.0/28'
        routeTableId: nvaRt.id
      }
      {
        name: 'backSubnet'
        addressPrefix: '10.0.1.16/28'
        routeTableId: nvaRt.id
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.0.1.32/27'
      }
      {
        name: 'admin'
        addressPrefix: '10.0.1.64/28'
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.0.1.128/26'
      }
    ]
    vnetName: 'nvaVnet'
  }
}

module appVnet './_modules/vnetMultiSubnetsRt.bicep' = {
  name: 'appVnet'
  params: {
    addressSpace: '10.0.0.0/24'
    location: location
    subnets: [
      {
        name: 'default'
        addressPrefix: '10.0.0.0/28'
        routeTableId: appRt.id
      }
    ]
    vnetName: 'appVnet'
  }
}

// Route tables
resource nvaRt 'Microsoft.Network/routeTables@2021-02-01' = {
  name: 'nvaRt'
  location: location
}

resource appRt 'Microsoft.Network/routeTables@2021-02-01' = {
  name: 'appRt'
  location: location
  properties: {
    routes: [
      {
        name: 'toNva'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '10.0.0.0/16'
          nextHopIpAddress: azFw.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

resource frontRt 'Microsoft.Network/routeTables@2021-02-01' = {
  name: 'frontRt'
  location: location
  properties: {
    routes: [
      {
        name: 'toNva'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '10.0.0.0/16'
          nextHopIpAddress: azFw.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

// Peerings relationships
resource nvaClientPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${nvaVnet.name}/nvaToClient'
  //parent: nvaVnet
  properties: {
    remoteVirtualNetwork: {
      id: clientVnet.outputs.vnetId
    }
  }
}

resource clientNvaPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${clientVnet.name}/clientToNva'
  //parent: clientVnet
  properties: {
    remoteVirtualNetwork: {
      id: nvaVnet.outputs.vnetId
    }
    allowForwardedTraffic: true
  }
}

resource nvaAppPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${nvaVnet.name}/nvaToApp'
  //parent: nvaVnet
  properties: {
    remoteVirtualNetwork: {
      id: appVnet.outputs.vnetId
    }
  }
}

resource appNvaPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${appVnet.name}/appToNva'
  //parent: appVnet
  properties: {
    remoteVirtualNetwork: {
      id: nvaVnet.outputs.vnetId
    }
    allowForwardedTraffic: true
  }
}

// VMs
module appVm0 '../_modules/vm.bicep' = {
  name: 'appVm0'
  params: {
    location: location
    subnetId: appVnet.outputs.subnets[0].id
    vmName: 'appVm0'
  }
}

module clientVm0 '../_modules/vm.bicep' = {
  name: 'clientVm0'
  params: {
    location: location
    subnetId: clientVnet.outputs.subnets[0].id
    vmName: 'clientVm0'
  }
}

// NVA and LB
// module nvaVm0 './_modules/vm2nics.bicep' = {
//   name: 'nvaVm0'
//   params: {
//     location: location
//     nic0SubnetId: nvaVnet.outputs.subnets[0].id
//     nic1SubnetId: nvaVnet.outputs.subnets[1].id
//     enableForwarding: true
//     enableCloudInit: false
//     vmName: 'nvaVm0'
//     nic0BackendPoolId: lb.outputs.backendPools[0].id
//     nic1BackendPoolId: lb.outputs.backendPools[1].id
//   }
// }

// module nvaVm1 './_modules/vm2nics.bicep' = {
//   name: 'nvaVm1'
//   params: {
//     location: location
//     nic0SubnetId: nvaVnet.outputs.subnets[0].id
//     nic1SubnetId: nvaVnet.outputs.subnets[1].id
//     enableForwarding: true
//     enableCloudInit: false
//     vmName: 'nvaVm1'
//     nic0BackendPoolId: lb.outputs.backendPools[0].id
//     nic1BackendPoolId: lb.outputs.backendPools[1].id
//   }
// }

// module lb './_modules/lb4nva.bicep' = {
//   name: 'ilb'
//   params: {
//     lbConfig: [
//       {
//         name: 'front'
//         subnetId: nvaVnet.outputs.subnets[0].id
//       }
//       {
//         name: 'app'
//         subnetId: nvaVnet.outputs.subnets[1].id
//       }
//     ]
//     lbName: 'ilb'
//     location: location
//     frontSubnetId: nvaVnet.outputs.subnets[0].id
//     appSubnetId: nvaVnet.outputs.subnets[1].id
//   }
// }

resource fwPublicIp 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'az-firewall-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource azFw 'Microsoft.Network/azureFirewalls@2021-02-01' = {
  name: 'azFw'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'azFwIpConfig'
        properties: {
          publicIPAddress: {
            id: fwPublicIp.id
          }
          subnet: {
            id: nvaVnet.outputs.subnets[4].id
          }
        }
      }
    ]
    firewallPolicy: {
      id: fwPolicy.id
    }
  }
}

resource fwPolicy 'Microsoft.Network/firewallPolicies@2023-09-01' = {
  name: 'azFwPolicy'
  location: location
  properties: {
    threatIntelMode: 'Alert'
  }
}

resource azFwRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  name: 'azFwRuleCollectionGroup'
  parent: fwPolicy
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'Global-rules'
        priority: 200
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'any'
            ipProtocols: [
              'Any'
            ]
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '*'
            ]
            sourceAddresses: [
              '*'
            ]
          }
        ]
      }
    ]
  }
}

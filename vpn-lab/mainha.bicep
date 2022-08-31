param location string = 'westeurope'

// Change the scope to be able to create the resource group before resources
// then we specify scope at resourceGroup level for all others resources
targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'vpn-lab'
  location: location
}

module vnet '../_modules/vnetMultiSubnets.bicep' = {
  name: 'vpn-vn'
  scope: rg
  params: {
    vnetName: 'vpn-vn'
    location: location
    addressSpace: '192.168.18.0/24'
    subnets: [
      {
        name: 'GatewaySubnet'
        addressPrefix: '192.168.18.0/27'
      }
      {
        name: 'default'
        addressPrefix: '192.168.18.32/27'
      }
    ]
  }
}

// module vpnGw '../_modules/vpngwha.bicep' = {
//   scope: rg
//   name: 'vpnGw'
//   params: {
//     asn: 65515
//     gwSubnetId: vnet.outputs.subnets[0].id
//     location: location
//     sku: 'HighPerformance'
//   }
// }

module vpnVm '../_modules/vm.bicep' = {
  scope: rg
  name: 'vpnVm'
  params: {
    location: location
    subnetId: vnet.outputs.subnets[1].id
    vmName: 'vpnVm'
    enableForwarding: false
  }
}

param location string = 'francecentral'
@secure()
param adminPassword string
@secure()
param vpnPreSharedKey string
param deployErVpn bool = false
@secure()
param erAuthKey string
@secure()
param erPrivatePeeringCircuitId string


///////////////////// AZURE RESOURCES //////////////////////////////////
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.22.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '172.22.0.0/28'
        }
      }
      {
        name: 'default'
        properties: {
          addressPrefix: '172.22.0.16/28'
        }
      }
      {
        name: 'inside'
        properties: {
          addressPrefix: '172.22.0.32/28'
        }
      }
      {
        name: 'outside'
        properties: {
          addressPrefix: '172.22.0.48/28'
        }
      }
      {
        name: 'RouteServerSubnet'
        properties: {
          addressPrefix: '172.22.0.64/27'
        }
      }
    ]
  }
}

module ergw 'ergw.bicep' = if(deployErVpn) {
  name: 'er-gw'
  params: {
    gwSubnetId: vnet.properties.subnets[0].id
    location: location
    name: 'er-gw'
  }
}

// resource erAvsConnection virtualnetwor = {
//   name: 'er-gw/toAvs'
//   parent: ergw
//   properties: {
//     authorizationKey: erAuthKey
//     expressRouteCircuitPeering: {
//       id: erPrivatePeeringCircuitId
//     }
//   }
// }


resource routeServer 'Microsoft.Network/virtualHubs@2020-11-01' = {
  name: 'vr'
  location: location
  properties: {
    sku: 'Standard'
    allowBranchToBranchTraffic: true
  }
}

resource routeServerIpConfig 'Microsoft.Network/virtualHubs/ipConfigurations@2020-11-01' = {
  name: 'vr'
  parent: routeServer
  properties: {
    subnet: {
      id: vnet.properties.subnets[4].id
    }
  }
}

module csr 'csr.bicep' = {
  name: 'csredge01'
  params: {
    adminPassword: adminPassword
    createPublicIpNsg: true
    enableForwarding: true
    location: location
    vmName: 'csredge'
    insideSubnetId: vnet.properties.subnets[2].id
    outsideSubnetId: vnet.properties.subnets[3].id
  }
}

///////////////////// ONPREM RESOURCES //////////////////////////////////

resource onPremVnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'onprem'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.23.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '172.23.0.0/28'
        }
      }
      {
        name: 'default'
        properties: {
          addressPrefix: '172.23.0.16/28'
        }
      }
    ]
  }
}

module vpnGw 'vpngw.bicep' = if(deployErVpn) {
  name: 'vpngw'
  params: {
    gwSubnetId: onPremVnet.properties.subnets[0].id
    location: location
    asn: 64620
  }
}

resource onPremLng 'Microsoft.Network/localNetworkGateways@2020-11-01' = {
  name: 'toAzure'
  location: location
  properties: {
    bgpSettings: {
      asn: 64610
      bgpPeeringAddress: '192.168.1.1'
      peerWeight: 0
    }
    gatewayIpAddress: csr.outputs.nicOutsidePublicIp
    localNetworkAddressSpace: {
      addressPrefixes: [
        '192.168.1.1/32'
      ]
    }
  }
}

resource onPremAzureConnection 'Microsoft.Network/connections@2020-11-01' = {
  name: 'onPremToAzure'
  location: location
  properties: {
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    connectionMode: 'Default'
    enableBgp: true
    sharedKey: vpnPreSharedKey
    virtualNetworkGateway1: {
      id: vpnGw.outputs.vpnGwId
      properties:{
        
      }
    }
    localNetworkGateway2: {
      id: onPremLng.id
      properties: {
        
      }
    }
  }
}

module azureVm 'vm.bicep' = {
  name: 'hubVm'
  params: {
    location: location
    subnetId: vnet.properties.subnets[1].id
    vmName: 'hubVm'
  }
}

module onPremVm 'vm.bicep' = {
  name: 'onPremVm'
  params: {
    location: location
    subnetId: onPremVnet.properties.subnets[1].id
    vmName: 'onPremVm'
  }
}

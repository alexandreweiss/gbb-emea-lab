param location string = 'francecentral'
param deployCsr bool = true
param deploySpokeCsr bool = true
param simulateOnPremLocation bool = true
param mySourceIp string = '90.103.196.31'
@secure()
param adminPassword string
@secure()
param vpnPreSharedKey string
param deployEr bool = false
@secure()
param erAuthKey string
@secure()
param erPrivatePeeringCircuitId string


///////////////////// AZURE RESOURCES //////////////////////////////////
resource hub 'Microsoft.Network/virtualNetworks@2020-11-01' = {
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

resource spoke 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'spoke'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.24.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '172.24.0.0/28'
        }
      }
    ]
  }
}

resource nva 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'nva'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.25.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '172.25.0.0/28'
        }
      }
      {
        name: 'inside'
        properties: {
          addressPrefix: '172.25.0.32/28'
        }
      }
      {
        name: 'outside'
        properties: {
          addressPrefix: '172.25.0.48/28'
        }
      }
    ]
  }
}

resource nvaHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: 'nvaToHub'
  parent: nva
  properties: {
    remoteVirtualNetwork: {
      id: hub.id
    }
  }
}

resource hubNvaPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: 'hubToNva'
  parent: hub
  properties: {
    remoteVirtualNetwork: {
      id: nva.id
    }
  }
}

resource spokeHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: 'spokeToHub'
  parent: spoke
  properties: {
    remoteVirtualNetwork: {
      id: hub.id
    }
    allowForwardedTraffic: true
    useRemoteGateways: true
  }
  dependsOn: [
    [
      hubSpokePeering
    ]
  ]
}

resource hubSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: 'hubToSpoke'
  parent: hub
  properties: {
    remoteVirtualNetwork: {
      id: spoke.id
    }
    allowGatewayTransit: true
  }
}

module ergw 'ergw.bicep' = if(deployEr) {
  name: 'er-gw'
  params: {
    gwSubnetId: hub.properties.subnets[0].id
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
      id: hub.properties.subnets[4].id
    }
  }
}

module csr 'csr.bicep' = if (deployCsr) {
  name: 'csredge01'
  params: {
    adminPassword: adminPassword
    createPublicIpNsg: true
    enableForwarding: true
    location: location
    vmName: 'csredge'
    insideSubnetId: hub.properties.subnets[2].id
    outsideSubnetId: hub.properties.subnets[3].id
    mySourceIp: mySourceIp
  }
}

module spokeCsr 'csr.bicep' = if (deploySpokeCsr) {
  name: 'csredge02'
  params: {
    adminPassword: adminPassword
    createPublicIpNsg: true
    enableForwarding: true
    location: location
    vmName: 'csredge02'
    insideSubnetId: nva.properties.subnets[1].id
    outsideSubnetId: nva.properties.subnets[2].id
    mySourceIp: mySourceIp
  }
}

///////////////////// ONPREM RESOURCES //////////////////////////////////

resource onPremVnet 'Microsoft.Network/virtualNetworks@2020-11-01' = if(simulateOnPremLocation) {
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

module vpnGw 'vpngwha.bicep' = if(simulateOnPremLocation) {
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
    //gatewayIpAddress: csr.outputs.nicOutsidePublicIp
    gatewayIpAddress: '1.1.1.1'
    localNetworkAddressSpace: {
      addressPrefixes: [
        '192.168.1.1/32'
      ]
    }
  }
}

resource sdWanLng 'Microsoft.Network/localNetworkGateways@2020-11-01' = {
  name: 'toSdwan'
  location: location
  properties: {
    bgpSettings: {
      asn: 64630
      bgpPeeringAddress: '192.168.2.1'
      peerWeight: 0
    }
    gatewayIpAddress: spokeCsr.outputs.nicOutsidePublicIp
    localNetworkAddressSpace: {
      addressPrefixes: [
        '192.168.2.1/32'
      ]
    }
  }
}

resource onPremAzureConnection 'Microsoft.Network/connections@2020-11-01' = if(simulateOnPremLocation) {
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


resource onPremSdwanConnection 'Microsoft.Network/connections@2020-11-01' = if(simulateOnPremLocation) {
  name: 'onPremToSdwan'
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
      id: sdWanLng.id
      properties: {
        
      }
    }
  }
}

module hubVm 'vm.bicep' = {
  name: 'hubVm'
  params: {
    location: location
    subnetId: hub.properties.subnets[1].id
    vmName: 'hubVm'
    mySourceIp: mySourceIp
  }
}

module onPremVm 'vm.bicep' =  if(simulateOnPremLocation) {
  name: 'onPremVm'
  params: {
    location: location
    subnetId: onPremVnet.properties.subnets[1].id
    vmName: 'onPremVm'
    mySourceIp: mySourceIp
  }
}


module spokeVm 'vm.bicep' = {
  name: 'spokevm'
  params: {
    location: location
    subnetId: spoke.properties.subnets[0].id
    vmName: 'spokevm'
    mySourceIp: mySourceIp
  }
}

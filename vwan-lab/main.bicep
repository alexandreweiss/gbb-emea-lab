param frLocation string = 'francecentral'
param ukLocation string = 'uksouth'

// Virtual Wan master
resource vwan 'Microsoft.Network/virtualWans@2020-08-01' = {
  name: 'vwan-lab'
  location: frLocation
  properties: {
  }
}

// vHub FRANCE CENTRAL
resource vhubfrc 'Microsoft.Network/virtualHubs@2020-08-01' = {
  name: 'h-frc'
  location: frLocation
  properties: {
    addressPrefix: '192.168.10.0/24'
    sku: 'Standard'
    virtualWan: {
      id: vwan.id
    }
  }
}

// vHub route table for NVA vNet
// resource frcRtNva 'Microsoft.Network/virtualHubs/routeTables@2020-08-01' = {
//   name: 'rtNva'
//   parent: vhubfrc
//   properties: {
//     attachedConnections: [
//       resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', vhubfrc.name, 'vn-frc-nva-0')
//     ]
//     routes: [
//       {
        
//       }
//     ]
//   }
// }

resource frcRtNva 'Microsoft.Network/virtualHubs/hubRouteTables@2020-08-01' = {
  name: 'rtNva'
  parent: vhubfrc
  properties: {
    routes: [
    ]
  }
}

resource frcRtVnet 'Microsoft.Network/virtualHubs/hubRouteTables@2020-08-01' = {
  name: 'rtVnet'
  parent: vhubfrc
  properties: {
    routes: [
      {
        destinations: [
          '0.0.0.0/0'
        ]
        destinationType: 'CIDR'
        name: 'toInternet'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', vhubfrc.name, 'vn-frc-nva-0')
        nextHopType: 'ResourceId'
      }
    ]
  }
}

// vHub route table for NON NVA vNet
// resource frcRtVnet 'Microsoft.Network/virtualHubs/routeTables@2020-08-01' = {
//   name: 'rtVnet'
//   parent: vhubfrc
//   properties: {
//     routes: [
//       {
//         destinations: [
//           '0.0.0.0/0'
//         ]
//         destinationType: 'CIDR'
//         nextHops: [
//           vnfrcnvaConnection.id
//         ]
//         nextHopType: 'ResourceId'
//       }
//     ]
//     attachedConnections: [
//       resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', vhubfrc.name, 'vn-frc-spoke-0')
//     ]
//   }
// }

// FRC - PEERING TO VHUB
// FRC - NVA VNET to VWAN FRC HUB CONNECTION
resource vnfrcnvaConnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: vnfrcnva.name
  parent: vhubfrc
  properties: {
    remoteVirtualNetwork: {
      id: vnfrcnva.outputs.vnetId
    }
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhubfrc.name, 'rtNva')
      }
      propagatedRouteTables: {
        ids: [
          {
            id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhubfrc.name, 'rtVnet')
          }
        ]
      }
      vnetRoutes: {
        staticRoutes: [
          {
            addressPrefixes: [
              '0.0.0.0/0'
            ]
            name: 'toInternet'
            nextHopIpAddress: vmNvaFrc.outputs.nicPrivateIp
          }
        ]
      }
    }
  }
}

// FRC - NON NVA VNET to VWAN FRC HUB CONNECTION
resource vnfrcspoke0Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: vnfrcspoke0.name
  parent: vhubfrc
  properties: {
    remoteVirtualNetwork: {
      id: vnfrcspoke0.outputs.vnetId
    }
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhubfrc.name, 'rtVnet')
      }
      propagatedRouteTables: {
        ids: [
          {
            id: frcRtVnet.id
          }
          {
            id: frcRtNva.id
          }
        ]
      }
    }
  }
}
// END OF PEERING TO VHUB

// Express Route Scale unit in FRC
resource vhubErGw 'Microsoft.Network/expressRouteGateways@2020-08-01' = {
  name: 'er-frc-gw'
  location: frLocation
  properties: {
    virtualHub: {
      id: vhubfrc.id
    }
    autoScaleConfiguration: {
      bounds: {
        min: 1
      }
    }
  }

}

// FRC - NVA VNET
module vnfrcnva 'vnet.bicep' = {
  name: 'vn-frc-nva-0'
  params: {
    addressPrefix: '192.168.11.0/28'
    addressSpace: '192.168.11.0/24'
    vnetName: 'vn-frc-nva-0'
    location: frLocation
  }
}

// FRC - NON NVA VNET PEERED TO NVA VNET
module vnfrcspoke00 'vnet.bicep' = {
  name: 'vn-frc-spoke-0-0'
  params: {
    addressPrefix: '192.168.12.0/28'
    addressSpace: '192.168.12.0/24'
    vnetName: 'vn-frc-spoke-0-0'
    location: frLocation
  }
}

// FRC - NON NVA VNET PEERED TO NVA VNET
module vnfrcspoke01 'vnet.bicep' = {
  name: 'vn-frc-spoke-0-1'
  params: {
    addressPrefix: '192.168.13.0/28'
    addressSpace: '192.168.13.0/24'
    vnetName: 'vn-frc-spoke-0-1'
    location: frLocation
  }
}

// FRC - NON NVA VNET PEERED TO VHUB FRC
module vnfrcspoke0 'vnet.bicep' = {
  name: 'vn-frc-spoke-0'
  params: {
    addressPrefix: '192.168.14.0/28'
    addressSpace: '192.168.14.0/24'
    vnetName: 'vn-frc-spoke-0'
    location: frLocation
  }
}

// FRC - PEERINGS //

resource nva0Spoke00 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnfrcnva.name}/nva2spoke0'
  parent: vnfrcnva
  properties: {
    remoteVirtualNetwork: {
      id: vnfrcspoke00.outputs.vnetId
    }
  }
}

resource Spoke00Nva0 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnfrcspoke00.name}/spoke02Nva'
  parent: vnfrcspoke00
  properties: {
    remoteVirtualNetwork: {
      id: vnfrcnva.outputs.vnetId
    }
  }
}

resource nva0Spoke01 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnfrcnva.name}/nva2spoke1'
  parent: vnfrcnva
  properties: {
    remoteVirtualNetwork: {
      id: vnfrcspoke01.outputs.vnetId
    }
  }
}

resource Spoke01Nva0 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnfrcspoke01.name}/spoke12Nva'
  parent: vnfrcspoke01
  properties: {
    remoteVirtualNetwork: {
      id: vnfrcnva.outputs.vnetId
    }
  }
}

// END OF PEERINGS



// VWAN UKS vHub
resource vhubuks 'Microsoft.Network/virtualHubs@2020-08-01' = {
  name: 'h-uks'
  location: ukLocation
  properties: {
    addressPrefix: '192.168.20.0/24'
    sku: 'Standard'
    virtualWan: {
      id: vwan.id
    }
  }
}

// UKS - NVA VNET
module vnuksnva 'vnet.bicep' = {
  name: 'vn-uks-nva-0'
  params: {
    addressPrefix: '192.168.21.0/28'
    addressSpace: '192.168.21.0/24'
    vnetName: 'vn-uks-nva-0'
    location: ukLocation
  }
}

// UKS - NON NVA VNET PEERED TO NVA VNET
module vnuksspoke00 'vnet.bicep' = {
  name: 'vn-uks-spoke-0-0'
  params: {
    addressPrefix: '192.168.22.0/28'
    addressSpace: '192.168.22.0/24'
    vnetName: 'vn-uks-spoke-0-0'
    location: ukLocation
  }
}

// UKS - NON NVA VNET PEERED TO NVA VNET
module vnuksspoke01 'vnet.bicep' = {
  name: 'vn-uks-spoke-0-1'
  params: {
    addressPrefix: '192.168.23.0/28'
    addressSpace: '192.168.23.0/24'
    vnetName: 'vn-uks-spoke-0-1'
    location: ukLocation
  }
}

// UKS - NON NVA VNET PEERED TO VHUB UKS
module vnuksspoke0 'vnet.bicep' = {
  name: 'vn-uks-spoke-0'
  params: {
    addressPrefix: '192.168.24.0/28'
    addressSpace: '192.168.24.0/24'
    vnetName: 'vn-uks-spoke-0'
    location: ukLocation
  }
}

// UKS - PEERINGS //

resource uksNva0Spoke00 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnuksnva.name}/nva2spoke0'
  parent: vnuksnva
  properties: {
    remoteVirtualNetwork: {
      id: vnuksspoke00.outputs.vnetId
    }
  }
}

resource uksSpoke00Nva0 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnuksspoke00.name}/spoke02Nva'
  parent: vnuksspoke00
  properties: {
    remoteVirtualNetwork: {
      id: vnuksnva.outputs.vnetId
    }
  }
}

resource uksNva0Spoke01 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnuksnva.name}/nva2spoke1'
  parent: vnuksnva
  properties: {
    remoteVirtualNetwork: {
      id: vnuksspoke01.outputs.vnetId
    }
  }
}

resource uksSpoke01Nva0 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnuksspoke01.name}/spoke12Nva'
  parent: vnuksspoke01
  properties: {
    remoteVirtualNetwork: {
      id: vnuksnva.outputs.vnetId
    }
  }
}

// END OF PEERINGS


// UKS - PEERING TO VHUB
// UKS - NVA VNET to VWAN FRC HUB CONNECTION
resource vnuksnvaConnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: vnuksnva.name
  parent: vhubuks
  properties: {
    remoteVirtualNetwork: {
      id: vnuksnva.outputs.vnetId
    }
  }
}

// UKS - NON NVA VNET to VWAN UKS HUB CONNECTION
resource vnuksspoke0Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: vnuksspoke0.name
  parent: vhubuks
  properties: {
    remoteVirtualNetwork: {
      id: vnuksspoke0.outputs.vnetId
    }
  }
}
// END OF PEERING TO VHUB

// Express Route circuit to FRC



// VMs
// FRC - NVA
module vmNvaFrc 'vm.bicep' = {
  name: 'vm-nva-frc'
  params: {
    location: frLocation
    subnetId: vnfrcnva.outputs.subnetId
    vmName: 'vm-nva-frc'
    enableForwarding: true
    createPublicIp: true
  }
}

// FRC - NON NVA VM IN FAR SPOKE0 PEERED TO NVA VNET
module vmSpoke00Frc 'vm.bicep' = {
  name: 'vm-spoke0-0-frc'
  params: {
    location: frLocation
    subnetId: vnfrcspoke00.outputs.subnetId
    vmName: 'vm-spoke0-0-frc'
    enableForwarding: false
  }
}


// FRC - NON NVA VM IN SPOKE0 PEERED TO VHUB FRC
module vmSpoke0Frc 'vm.bicep' = {
  name: 'vm-spoke0-frc'
  params: {
    location: frLocation
    subnetId: vnfrcspoke0.outputs.subnetId
    vmName: 'vm-spoke0-frc'
    enableForwarding: false
  }
}


// UKS - NON NVA VM IN SPOKE0 PEERED TO VHUB UKS
module vmSpoke0Uks 'vm.bicep' = {
  name: 'vm-spoke0-uks'
  params: {
    location: ukLocation
    subnetId: vnuksspoke0.outputs.subnetId
    vmName: 'vm-spoke0-uks'
    enableForwarding: false
  }
}

// UKS - NVA
module vmNvaUks 'vm.bicep' = {
  name: 'vm-nva-uks'
  params: {
    location: ukLocation
    subnetId: vnuksnva.outputs.subnetId
    vmName: 'vm-nva-uks'
    enableForwarding: true
  }
}

// UKS - NON NVA VM IN FAR SPOKE0 PEERED TO NVA VNET
module vmSpoke00Uks 'vm.bicep' = {
  name: 'vm-spoke0-0-uks'
  params: {
    location: ukLocation
    subnetId: vnuksspoke00.outputs.subnetId
    vmName: 'vm-spoke0-0-uks'
    enableForwarding: false
  }
}
// END OF VMs

param frLocation string = 'francecentral'
param uksLocation string = 'uksouth'
param weLocation string = 'westeurope'
param usLocation string = 'eastus'
param deployEr bool = false
param deployErWe bool = true
param deployVmNwExt bool = false

// Deploy a second FRC vHub and ER GW
param deployFrc2Vhub bool = false
param deployFrcEr2 bool = false
param deployFrcVpn bool = false

// Deploy US vHub and ER GW
param deployUsVhub bool = true

// Deploy a secured hub in WE + VPN
param deployWeSecuredHub bool = false
param deployWeVpn bool = false

// Make FRC and FRC2 secured
param doFrcSecuredHub bool = false
param doFrc2SecuredHub bool = false

param mySourceIp string = '81.49.39.190'

// ER Circuit
@secure()
param erAuthKey string
@secure()
param erCircuitId string

// VPN PSK
@secure()
param psk string

// AVS Ravi ER Circuit
@secure()
param erAuthKeyAvs string
@secure()
param erCircuitIdAvs string

// Windows VM admin password
@secure()
param adminPassword string

var frcDefaultRouteTable = 'defaultRouteTable'
var uksDefaultRouteTable = 'defaultRouteTable'
var usDefaultRouteTable = 'defaultRouteTable'

// Deployment syntax
// az deployment group create -n Deploy -g vwan-lab-0 
// --template-file main.bicep 
// --parameters ..\..\..\secret\vwan-lab.param.json

///////////////////////////////VWAN///////////////////////////////////////////////////


/*
This is the core master vWan **********
*/
resource vwan 'Microsoft.Network/virtualWans@2020-08-01' = {
  name: 'vwan-lab'
  location: frLocation
  properties: {
  }
}

/***************************************
VHUBS 
***************************************/

// /***************************************
// Secured vHub WEST EUROPE
// Firewall Policy
// Firewall
// */

resource weVhub 'Microsoft.Network/virtualHubs@2020-08-01' = if (deployWeSecuredHub) {
  name: 'h-we'
  location: weLocation
  properties: {
    addressPrefix: '192.168.30.0/24'
    sku: 'Standard'
    virtualWan: {
      id: vwan.id
    }
  }
}

module azFwPolicy '../_modules/azfwpolicy.bicep' = {
  name: 'defaultPolicy'
  params: {
    location: frLocation
    name: 'defautPolicy'
  }
}

module weAzFw '../_modules/vhub-azfw.bicep' =  if (deployWeSecuredHub) {
  name: 'azfw-vhub-we'
  params: {
    fwName: 'azfw-vhub-we'
    location: weLocation
    virtualHubId: weVhub.id
    fwPolicyId: azFwPolicy.outputs.fwPolicyId
  }
}


// /***************************************
// vHub France Central + vHub2 France Central
// Firewall Policy
// Firewall (optional doFrcSecuredHub or doFrc2SecuredHub)
// */

resource frcVhub 'Microsoft.Network/virtualHubs@2020-08-01' = {
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

resource frc2Vhub 'Microsoft.Network/virtualHubs@2020-08-01' = if(deployFrc2Vhub) {
  name: 'h-frc-2'
  location: frLocation
  properties: {
    addressPrefix: '192.168.40.0/24'
    sku: 'Standard'
    virtualWan: {
      id: vwan.id
    }
  }
}

// /*
// vHub NVA route table
// */

resource frcRtNva 'Microsoft.Network/virtualHubs/hubRouteTables@2020-08-01' = {
  name: '${frcVhub.name}/rtNva'
  properties: {
    routes: [
    ]
    labels: [
      'nva'
    ]
  }
}

// /*
// vHub default VNET route table
// */

resource frcRtVnet 'Microsoft.Network/virtualHubs/hubRouteTables@2020-08-01' = {
  name: '${frcVhub.name}/rtVnet'
  dependsOn: [
    [
      frcVhubErGw
    ]
    [
      frcVnet4Connection
    ]
  ]
  properties: {
    routes: [
      {
        destinations: [
          '192.168.61.0/24'
        ]
        destinationType: 'CIDR'
        name: 'toOnPrem'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', frcVhub.name, 'frc-vnet4')
        nextHopType: 'ResourceId'
      }
      {
        destinations: [
          '192.168.12.0/24'
        ]
        destinationType: 'CIDR'
        name: 'toVnet7'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', frcVhub.name, 'frc-vnet4')
        nextHopType: 'ResourceId'
      }
      {
        destinations: [
          '192.168.13.0/24'
        ]
        destinationType: 'CIDR'
        name: 'toVnet8'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', frcVhub.name, 'frc-vnet4')
        nextHopType: 'ResourceId'
      }
      {
        destinations: [
          '192.168.22.0/24'
        ]
        destinationType: 'CIDR'
        name: 'toUksVnet5'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', vhubuks.name, 'uks-vnet2')
        nextHopType: 'ResourceId'
      }
      {
        destinations: [
          '192.168.23.0/24'
        ]
        destinationType: 'CIDR'
        name: 'toUksVnet6'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', vhubuks.name, 'uks-vnet2')
        nextHopType: 'ResourceId'
      }
      // {
      //   destinations: [
      //     '0.0.0.0/0'
      //   ]
      //   destinationType: 'CIDR'
      //   name: 'toInternet'
      //   nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', frcVhub.name, 'frc-vnet4')
      //   nextHopType: 'ResourceId'
      // }
    ]
    labels: [
      'vnet'
    ]
  }
}

// /*
// vHub default route table
// */

resource frcRtDefault 'Microsoft.Network/virtualHubs/hubRouteTables@2020-11-01' = {
  name: '${frcVhub.name}/${frcDefaultRouteTable}'
  dependsOn: [
    [
      frcVhubErGw
    ]
    [
      frcVnet4Connection
    ]
  ]
  properties: {
    labels: [
      'default'
    ]
    routes: [
      // {
      //   destinations: [
      //     '0.0.0.0/0'
      //   ]
      //   destinationType: 'CIDR'
      //   nextHop: frcVnet4Connection.id
      //   nextHopType: 'ResourceId'
      //   name: 'toInternet'
      // }
      {
        destinations: [
          '192.168.12.0/24'
        ]
        destinationType: 'CIDR'
        nextHop: frcVnet4Connection.id
        nextHopType: 'ResourceId'
        name: 'toVnet7'
      }
      {
        destinations: [
          '192.168.13.0/24'
        ]
        destinationType: 'CIDR'
        nextHop: frcVnet4Connection.id
        nextHopType: 'ResourceId'
        name: 'toVnet8'
      }
      {
        destinations: [
          '192.168.22.0/24'
        ]
        destinationType: 'CIDR'
        nextHop: uksVnet2Connection.id
        nextHopType: 'ResourceId'
        name: 'toUksVnet5'
      }
      {
        destinations: [
          '192.168.23.0/24'
        ]
        destinationType: 'CIDR'
        nextHop: uksVnet2Connection.id
        nextHopType: 'ResourceId'
        name: 'toUksVnet6'
      }
    ]
  }
}

module frcAzFw '../_modules/vhub-azfw.bicep' =  if (doFrcSecuredHub) {
  name: 'azfw-vhub-frc'
  params: {
    fwName: 'azfw-vhub-frc'
    location: frLocation
    virtualHubId: frcVhub.id
    fwPolicyId: azFwPolicy.outputs.fwPolicyId
  }
}

module frc2AzFw '../_modules/vhub-azfw.bicep' =  if (doFrc2SecuredHub) {
  name: 'azfw-vhub-frc2'
  params: {
    fwName: 'azfw-vhub-frc2'
    location: frLocation
    virtualHubId: frc2Vhub.id
    fwPolicyId: azFwPolicy.outputs.fwPolicyId
  }
}

// /***************************************
// vHub East US
// */

resource usVhub 'Microsoft.Network/virtualHubs@2020-08-01' = if(deployUsVhub) {
  name: 'h-eus'
  location: usLocation
  properties: {
    addressPrefix: '192.168.50.0/24'
    sku: 'Standard'
    virtualWan: {
      id: vwan.id
    }
  }
}

// /*
// vHub default route table
// */

resource usRtDefault 'Microsoft.Network/virtualHubs/hubRouteTables@2020-11-01' = {
  name: '${usVhub.name}/${usDefaultRouteTable}'
  dependsOn: [
  ]
  properties: {
    labels: [
      'default'
    ]
    routes: [    ]
  }
}

// /***************************************
// vHub UK South
// */

resource vhubuks 'Microsoft.Network/virtualHubs@2020-08-01' = {
  name: 'h-uks'
  location: uksLocation
  properties: {
    addressPrefix: '192.168.20.0/24'
    sku: 'Standard'
    virtualWan: {
      id: vwan.id
    }
  }
}

resource uksRtNva 'Microsoft.Network/virtualHubs/hubRouteTables@2020-08-01' = {
  name: '${vhubuks.name}/rtNva'
  properties: {
    routes: [
    ]
    labels: [
      'nva'
    ]
  }
}

resource uksRtVnet 'Microsoft.Network/virtualHubs/hubRouteTables@2020-08-01' = {
  name: '${vhubuks.name}/rtVnet'
  dependsOn: [
    [
      uksVnet2Connection
    ]
    [
      frcVnet4Connection
    ]
  ]
  properties: {
    routes: [
      {
        destinations: [
          '192.168.22.0/24'
        ]
        destinationType: 'CIDR'
        name: 'toVnet5'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', vhubuks.name, 'uks-vnet2')
        nextHopType: 'ResourceId'
      }
      {
        destinations: [
          '192.168.23.0/24'
        ]
        destinationType: 'CIDR'
        name: 'toVnet6'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', vhubuks.name, 'uks-vnet2')
        nextHopType: 'ResourceId'
      }
      {
        destinations: [
          '192.168.12.0/24'
        ]
        destinationType: 'CIDR'
        name: 'toFrcVnet7'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', frcVhub.name, 'frc-vnet4')
        nextHopType: 'ResourceId'
      }
      {
        destinations: [
          '192.168.13.0/24'
        ]
        destinationType: 'CIDR'
        name: 'toFrcVnet8'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', frcVhub.name, 'frc-vnet4')
        nextHopType: 'ResourceId'
      }
      // {
      //   destinations: [
      //     '0.0.0.0/0'
      //   ]
      //   destinationType: 'CIDR'
      //   name: 'toInternet'
      //   nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', vhubuks.name, 'uks-vnet2')
      //   nextHopType: 'ResourceId'
      // }
    ]
    labels: [
      'vnet'
    ]
  }
}

// /*
// vHub default route table
// */

resource uksRtDefault 'Microsoft.Network/virtualHubs/hubRouteTables@2020-11-01' = {
  name: '${vhubuks.name}/${uksDefaultRouteTable}'
  dependsOn: [
    [
      uksVnet2Connection
    ]
  ]
  properties: {
    labels: [
      'default'
    ]
    routes: [
      // {
      //   destinations: [
      //     '0.0.0.0/0'
      //   ]
      //   destinationType: 'CIDR'
      //   nextHop: uksVnet2Connection.id
      //   nextHopType: 'ResourceId'
      //   name: 'toInternet'
      // }
      {
        destinations: [
          '192.168.22.0/24'
        ]
        destinationType: 'CIDR'
        nextHop: uksVnet2Connection.id
        nextHopType: 'ResourceId'
        name: 'toVnet5'
      }
      {
        destinations: [
          '192.168.23.0/24'
        ]
        destinationType: 'CIDR'
        nextHop: uksVnet2Connection.id
        nextHopType: 'ResourceId'
        name: 'toVnet6'
      }
      {
        destinations: [
          '192.168.12.0/24'
        ]
        destinationType: 'CIDR'
        nextHop: frcVnet4Connection.id
        nextHopType: 'ResourceId'
        name: 'toFrcVnet7'
      }
      {
        destinations: [
          '192.168.13.0/24'
        ]
        destinationType: 'CIDR'
        nextHop: frcVnet4Connection.id
        nextHopType: 'ResourceId'
        name: 'toFrcVnet8'
      }
    ]
  }
}

/***************************************
END OF VHUBS 
***************************************/

/***************************************
VNETS 
***************************************/



/***************************************
END OF VNETS 
***************************************/

// FRC - PEERING TO VHUB
// FRC - NVA VNET to VWAN FRC HUB CONNECTION
resource frcVnet4Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: frcVnet4.name
  parent: frcVhub
  properties: {
    remoteVirtualNetwork: {
      id: frcVnet4.outputs.vnetId
    }
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', frcVhub.name, frcDefaultRouteTable)
      }
      propagatedRouteTables: {
        ids: [
          // {
          //   id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', frcVhub.name, 'rtVnet')
          // }
          {
            id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', frcVhub.name, frcDefaultRouteTable)
          }
        ]
        labels: [
          'default'
        ]
      }
      vnetRoutes: {
        staticRoutes: [
          // {
          //   addressPrefixes: [
          //     '192.168.2.0/24'
          //   ]
          //   name: 'toOnPrem'
          //   nextHopIpAddress: frcVmNva.outputs.nicPrivateIp
          // }
          // {
          //   addressPrefixes: [
          //     '0.0.0.0/0'
          //   ]
          //   name: 'toInternet'
          //   nextHopIpAddress: frcVmNva.outputs.nicPrivateIp
          // }
          {
            addressPrefixes: [
              '192.168.12.0/24'
            ]
            name: 'toVnet7'
            nextHopIpAddress: frcVmNva.outputs.nicPrivateIp
          }
          {
            addressPrefixes: [
              '192.168.13.0/24'
            ]
            name: 'toVnet8'
            nextHopIpAddress: frcVmNva.outputs.nicPrivateIp
          }
        ]
      }
    }
  }
}

// FRC - NON NVA VNET to VWAN FRC HUB CONNECTION
resource frcVnet3Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: frcVnet3.name
  parent: frcVhub
  properties: {
    remoteVirtualNetwork: {
      id: frcVnet3.outputs.vnetId
    }
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', frcVhub.name, 'rtVnet')
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
    enableInternetSecurity: true
  }
}

//TEMP PEERING TO TEST TO HUB
resource frcVnet9Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: frcVnet9.name
  parent: frcVhub
  properties: {
    remoteVirtualNetwork: {
      id: frcVnet9.outputs.vnetId
    }
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', frcVhub.name, frcDefaultRouteTable)
      }
      propagatedRouteTables: {
        ids: [
          {
            id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', frcVhub.name, frcDefaultRouteTable)
          }
        ]
      }
    }
    enableInternetSecurity: true
  }
}

//US PEERING TO HUB
resource usVnet10Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = if(deployUsVhub) {
  name: usVnet10.name
  parent: usVhub
  properties: {
    remoteVirtualNetwork: {
      id: usVnet10.outputs.vnetId
    }
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', usVhub.name, usDefaultRouteTable)
      }
      propagatedRouteTables: {
        ids: [
          {
            id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', usVhub.name, usDefaultRouteTable)
          }
        ]
        labels: [
          'default'
        ]
      }
    }
    enableInternetSecurity: true
  }
}
// END OF PEERING TO VHUB

///////////////////////////////////////GW S2S/P2S/ER///////////////////////////////////////////
// Express Route Scale unit in FRC
resource frcVhubErGw 'Microsoft.Network/expressRouteGateways@2020-08-01' = if(deployEr) {
  name: 'gw-frc-er'
  location: frLocation
  properties: {
    virtualHub: {
      id: frcVhub.id
    }
    autoScaleConfiguration: {
      bounds: {
        min: 1
      }
    }
  }
  resource erCircuit 'expressRouteConnections@2020-08-01' = {
    name: 'con-ldn-er'
    properties: {
      authorizationKey: erAuthKey
      expressRouteCircuitPeering: {
        id: erCircuitId
      }
      routingConfiguration: {
        associatedRouteTable: {
          id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', frcVhub.name, 'defaultRouteTable')
        }
        propagatedRouteTables: {
          ids: [
            {
              id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', frcVhub.name, 'rtNva')
            }
            {
              id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', frcVhub.name, 'defaultRouteTable')
            }
          ]
        }
      }
    }
  }
}

resource weVhubErGw 'Microsoft.Network/expressRouteGateways@2020-08-01' = if(deployErWe) {
  name: 'gw-we-er'
  location: weLocation
  properties: {
    virtualHub: {
      id: weVhub.id
    }
    autoScaleConfiguration: {
      bounds: {
        min: 1
      }
    }
  }
  resource erCircuit 'expressRouteConnections@2020-08-01' = {
    name: 'con-${weLocation}-er'
    properties: {
      authorizationKey: erAuthKey
      expressRouteCircuitPeering: {
        id: erCircuitId
      }
      routingConfiguration: {
        associatedRouteTable: {
          id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', frcVhub.name, 'defaultRouteTable')
        }
        propagatedRouteTables: {
          ids: [
            {
              id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', weVhub.name, 'rtNva')
            }
            {
              id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', weVhub.name, 'defaultRouteTable')
            }
          ]
        }
      }
    }
  }
}

module frcVhubVpnGw '../_modules/vwanvpngw.bicep' = if(deployFrcVpn) {
  name: 'gw-frc-vpn'
  params: {
    asn: 65515
    gwName: 'gw-frc-vpn'
    location: frLocation
    vHubId: frcVhub.id
  }
}

module weVhubVpnGw '../_modules/vwanvpngw.bicep' = if(deployWeVpn) {
  name: 'gw-we-vpn'
  params: {
    asn: 65515
    gwName: 'gw-we-vpn'
    location: weLocation
    vHubId: weVhub.id
  }
}

module weVpnSite1 '../_modules/vwanvpnsite.bicep' = if(deployWeVpn) {
  name: 'Longvilliers'
  params: {
    asn: 65510
    bgpIp: '192.168.17.1'
    location: weLocation
    name: 'Longvilliers'
    publicIp: 'ferme.ananableu.fr'
    vWanId: vwan.id
    vpnGatewayName: weVhubVpnGw.name
    psk: psk
  }
}

module frcVpnSite1 '../_modules/vwanvpnsite.bicep' = if(deployFrcVpn) {
  name: 'Longvilliers-frc'
  params: {
    asn: 65510
    bgpIp: '192.168.17.1'
    location: frLocation
    name: 'Longvilliers-frc'
    publicIp: 'ferme.ananableu.fr'
    vWanId: vwan.id
    vpnGatewayName: frcVhubVpnGw.name
    psk: psk
  }
}

resource frcVhubErGw2 'Microsoft.Network/expressRouteGateways@2020-08-01' = if(deployFrcEr2) {
  name: 'gw-frc-er2'
  location: frLocation
  properties: {
    virtualHub: {
      id: frc2Vhub.id
    }
    autoScaleConfiguration: {
      bounds: {
        min: 1
      }
    }
  }
  resource erCircuit 'expressRouteConnections@2020-08-01' = {
    name: 'con-avs-er'
    properties: {
      authorizationKey: erAuthKeyAvs
      expressRouteCircuitPeering: {
        id: erCircuitIdAvs
      }
      routingConfiguration: {
        associatedRouteTable: {
          id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', frc2Vhub.name, 'defaultRouteTable')
        }
        propagatedRouteTables: {
          ids: [
            {
              id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', frc2Vhub.name, 'defaultRouteTable')
            }
          ]
        }
      }
    }
  }
}

// FRC - NVA VNET
module frcVnet4 'vnet.bicep' = {
  name: 'frc-vnet4'
  params: {
    addressPrefix: '192.168.11.0/28'
    addressSpace: '192.168.11.0/24'
    vnetName: 'frc-vnet4'
    location: frLocation
  }
}

// FRC - NON NVA VNET PEERED TO NVA VNET
module frcVnet7 'vnet.bicep' = {
  name: 'frc-vnet7'
  params: {
    addressPrefix: '192.168.12.0/28'
    addressSpace: '192.168.12.0/24'
    vnetName: 'frc-vnet7'
    location: frLocation
    routeTableId: frcVnet78Rt.id
  }
}

// FRC - NON NVA VNET PEERED TO NVA VNET
module frcVnet8 'vnet.bicep' = {
  name: 'frc-vnet8'
  params: {
    addressPrefix: '192.168.13.0/28'
    addressSpace: '192.168.13.0/24'
    vnetName: 'frc-vnet8'
    location: frLocation
    routeTableId: frcVnet78Rt.id
  }
}

// FRC - UDR FOR NON NVA VNET PEERED TO NVA VNET
resource frcVnet78Rt 'Microsoft.Network/routeTables@2020-11-01' = {
  name: 'frc-vnet7-vnet8-rt'
  location: frLocation
  properties: {
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: frcVmNva.outputs.nicPrivateIp
          nextHopType:'VirtualAppliance'
        }
      }
    ]
  }
}

// FRC - NON NVA VNET PEERED TO VHUB FRC
module frcVnet3 'vnet.bicep' = {
  name: 'frc-vnet3'
  params: {
    addressPrefix: '192.168.14.0/28'
    addressSpace: '192.168.14.0/24'
    vnetName: 'frc-vnet3'
    location: frLocation
  }
}

//TEMP FOR TEST
module frcVnet9 'vnet.bicep' = {
  name: 'frc-vnet9'
  params: {
    addressPrefix: '192.168.19.0/28'
    addressSpace: '192.168.19.0/24'
    vnetName: 'frc-vnet9'
    location: frLocation
  }
}

//US FOR TEST
module usVnet10 'vnet.bicep' = if(deployUsVhub) {
  name: 'us-vnet10'
  params: {
    addressPrefix: '192.168.51.0/28'
    addressSpace: '192.168.51.0/24'
    vnetName: 'us-vnet10'
    location: usLocation
  }
}

// FRC - PEERINGS //

resource vnet4Vnet7Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${frcVnet4.name}/vnet4toVnet7'
  properties: {
    remoteVirtualNetwork: {
      id: frcVnet7.outputs.vnetId
    }
  }
}

resource vnet7Vnet4Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${frcVnet7.name}/vnet7toVnet4'
  properties: {
    remoteVirtualNetwork: {
      id: frcVnet4.outputs.vnetId
    }
    allowForwardedTraffic: true
  }
}

resource vnet4Vnet8Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${frcVnet4.name}/vnet4toVnet8'
  properties: {
    remoteVirtualNetwork: {
      id: frcVnet8.outputs.vnetId
    }
  }
}

resource vnet8Vnet4Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${frcVnet8.name}/vnet8toVnet4'
  properties: {
    remoteVirtualNetwork: {
      id: frcVnet4.outputs.vnetId
    }
    allowForwardedTraffic: true
  }
}

// END OF PEERINGS

// UKS - NVA VNET
module uksVnet2 'vnet.bicep' = {
  name: 'uks-vnet2'
  dependsOn: [
  ]
  params: {
    addressPrefix: '192.168.21.0/28'
    addressSpace: '192.168.21.0/24'
    vnetName: 'uks-vnet2'
    location: uksLocation
  }
}

// UKS - NON NVA VNET PEERED TO NVA VNET
module uksVnet5 'vnet.bicep' = {
  name: 'uks-vnet5'
  params: {
    addressPrefix: '192.168.22.0/28'
    addressSpace: '192.168.22.0/24'
    vnetName: 'uks-vnet5'
    location: uksLocation
    routeTableId: uksVnet56Rt.id
  }
}

// UKS - NON NVA VNET PEERED TO NVA VNET
module uksVnet6 'vnet.bicep' = {
  name: 'uks-vnet6'
  params: {
    addressPrefix: '192.168.23.0/28'
    addressSpace: '192.168.23.0/24'
    vnetName: 'uks-vnet6'
    location: uksLocation
    routeTableId: uksVnet56Rt.id
  }
}

resource uksVnet56Rt 'Microsoft.Network/routeTables@2020-11-01' = {
  name: 'uks-vnet5-vnet6-rt'
  location: uksLocation
  properties: {
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: uksVmNva.outputs.nicPrivateIp
          nextHopType:'VirtualAppliance'
        }
      }
    ]
  }
}

// UKS - NON NVA VNET PEERED TO VHUB UKS
module uksVnet1 'vnet.bicep' = {
  name: 'uks-vnet1'
  params: {
    addressPrefix: '192.168.24.0/28'
    addressSpace: '192.168.24.0/24'
    vnetName: 'uks-vnet1'
    location: uksLocation
  }
}

// UKS - PEERINGS //

resource uksVnet2Vnet5Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${uksVnet2.name}/vnet2toVnet5'
  properties: {
    remoteVirtualNetwork: {
      id: uksVnet5.outputs.vnetId
    }
  }
}

resource uksVnet5Vnet2Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${uksVnet5.name}/vnet5toVnet2'
  properties: {
    remoteVirtualNetwork: {
      id: uksVnet2.outputs.vnetId
    }
    allowForwardedTraffic: true
  }
}

resource uksVnet2Vnet6Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${uksVnet2.name}/vnet2ToVnet6'
  properties: {
    remoteVirtualNetwork: {
      id: uksVnet6.outputs.vnetId
    }
  }
}

resource uksVnet6Vnet2Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${uksVnet6.name}/vnet6toVnet2'
  properties: {
    remoteVirtualNetwork: {
      id: uksVnet2.outputs.vnetId
    }
    allowForwardedTraffic: true
  }
}

// END OF PEERINGS


///////////////////// UKS - PEERING TO VHUB ////////////////////////////////
// UKS - NVA VNET to VWAN FRC HUB CONNECTION
resource uksVnet2Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: uksVnet2.name
  parent: vhubuks
  properties: {
    remoteVirtualNetwork: {
      id: uksVnet2.outputs.vnetId
    }
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhubuks.name, uksDefaultRouteTable)
      }
      propagatedRouteTables: {
        ids: [
          // {
          //   id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhubuks.name, 'rtVnet')
          // }
          {
            id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhubuks.name, uksDefaultRouteTable)
          }
        ]
        labels: [
          'default'
        ]
      }
      vnetRoutes: {
        staticRoutes: [
          // {
          //   addressPrefixes: [
          //     '0.0.0.0/0'
          //   ]
          //   name: 'toInternet'
          //   nextHopIpAddress: uksVmNva.outputs.nicPrivateIp
          // }
          {
            addressPrefixes: [
              '192.168.22.0/24'
            ]
            name: 'toVnet5'
            nextHopIpAddress: uksVmNva.outputs.nicPrivateIp
          }
          {
            addressPrefixes: [
              '192.168.23.0/24'
            ]
            name: 'toVnet6'
            nextHopIpAddress: uksVmNva.outputs.nicPrivateIp
          }
        ]
      }
    }
  }
}


// UKS - NON NVA VNET to VWAN UKS HUB CONNECTION
resource uksVnet1Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: uksVnet1.name
  parent: vhubuks
  properties: {
    remoteVirtualNetwork: {
      id: uksVnet1.outputs.vnetId
    }
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhubuks.name, 'rtVnet')
      }
      propagatedRouteTables: {
        ids: [
          {
            id: uksRtVnet.id
          }
          {
            id: uksRtNva.id
          }
        ]
      }
    }
    enableInternetSecurity: true
  }
}
// END OF PEERING TO VHUB

// Express Route circuit to FRC

// /////////////////////// VMs ///////////////////////////////
// // FRC - NVA
module frcVmNva '../_modules/vm.bicep' = {
  name: 'frc-nva'
  params: {
    location: frLocation
    subnetId: frcVnet4.outputs.subnetId
    vmName: 'frc-nva'
    enableForwarding: true
    createPublicIpNsg: true
    enableCloudInit: true
    mySourceIp: mySourceIp
  }
}

// // FRC - NON NVA VM IN FAR SPOKE0 PEERED TO NVA VNET
module frcVmVnet7 '../_modules/vm.bicep' = {
  name: 'frc-vm7'
  params: {
    location: frLocation
    subnetId: frcVnet7.outputs.subnetId
    vmName: 'frc-vm7'
    enableForwarding: false
    mySourceIp: mySourceIp
  }
}

module frcVmVnet7Nw '../_modules/nwext.bicep' = if(deployVmNwExt) {
  name: '${frcVmVnet7.name}-nw-ext'
  params: {
    location: frLocation
    vmName: frcVmVnet7.name
  }
  
}


// // FRC - NON NVA VM IN SPOKE0 PEERED TO VHUB FRC
module frcVmVnet3 '../_modules/vm.bicep' = {
  name: 'frc-vm3'
  params: {
    location: frLocation
    subnetId: frcVnet3.outputs.subnetId
    vmName: 'frc-vm3'
    enableForwarding: false
    mySourceIp: mySourceIp
  }
}

module frcVmVnet3Nw '../_modules/nwext.bicep' = if(deployVmNwExt) {
  name: '${frcVmVnet3.name}-nw-ext'
  params: {
    location: frLocation
    vmName: frcVmVnet3.name
  }
  
}

// // FRC - NON NVA VM IN VNET PEERED TO VHUB FRC WITH DEFAULT ROUTE TABLE
module frcVmVnet9 '../_modules/vm.bicep' = {
  name: 'frc-vm9'
  params: {
    location: frLocation
    subnetId: frcVnet9.outputs.subnetId
    vmName: 'frc-vm9'
    mySourceIp: mySourceIp
  }
}

module frcWinVmVnet9 '../_modules/vm.bicep' = {
  name: 'frc-vm9-win'
  params: {
    location: frLocation
    subnetId: frcVnet9.outputs.subnetId
    vmName: 'frc-vm9-win'
    mySourceIp: mySourceIp
    osType: 'desktop'
    adminPassword: adminPassword
  }
}

// // US - NON NVA VM IN VNET PEERED TO VHUB US WITH DEFAULT ROUTE TABLE
module usVmVnet10 '../_modules/vm.bicep' = {
  name: 'us-vm10'
  params: {
    location: usLocation
    subnetId: usVnet10.outputs.subnetId
    vmName: 'us-vm10'
    mySourceIp: mySourceIp
  }
}

// // UKS - NON NVA VM IN SPOKE0 PEERED TO VHUB UKS
module uksVmVnet1 '../_modules/vm.bicep' = {
  name: 'uks-vm1'
  params: {
    location: uksLocation
    subnetId: uksVnet1.outputs.subnetId
    vmName: 'uks-vm1'
    mySourceIp: mySourceIp
  }
}

// // UKS - NVA
module uksVmNva '../_modules/vm.bicep' = {
  name: 'uks-nva'
  params: {
    location: uksLocation
    subnetId: uksVnet2.outputs.subnetId
    vmName: 'uks-nva'
    enableForwarding: true
    createPublicIpNsg: true
    enableCloudInit: true
    mySourceIp: mySourceIp
  }
}

// // UKS - NON NVA VM IN FAR SPOKE0 PEERED TO NVA VNET
// module uksVmVnet5 '../_modules/vm.bicep' = {
//   name: 'uks-vm5'
//   params: {
//     location: uksLocation
//     subnetId: uksVnet5.outputs.subnetId
//     vmName: 'uks-vm5'
//     mySourceIp: mySourceIp
//   }
// }

// module uksVmVnet5Nw '../_modules/nwext.bicep' = if(deployVmNwExt) {
//   name: '${uksVmVnet5.name}-nw-ext'
//   params: {
//     location: uksLocation
//     vmName: uksVmVnet5.name
//   }
  
// }

// END OF VMs

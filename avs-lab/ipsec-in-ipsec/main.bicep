param location string = 'francecentral'
@secure()
param adminPassword string
@secure()
param vpnPreSharedKey string
param deployErVpn bool = false
param deployVr bool = false
param vWanVpnIn0 string = '20.49.231.67'
param vWanVpnIn1 string = '20.49.231.66'
param vWanBgpIn0 string = '10.0.5.14'
param vWanBgpIn1 string = '10.0.5.15'


///////////////////// AZURE RESOURCES //////////////////////////////////
resource onPremVnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'onprem'
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
          routeTable: {
            id: onPremRt.id
          }
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

module csr 'csr.bicep' = {
  name: 'csredge02'
  params: {
    adminPassword: adminPassword
    createPublicIpNsg: true
    enableForwarding: true
    location: location
    vmName: 'csredge02'
    insideSubnetId: onPremVnet.properties.subnets[2].id
    outsideSubnetId: onPremVnet.properties.subnets[3].id
  }
}

resource routeServer 'Microsoft.Network/virtualHubs@2020-11-01' = if(deployVr) {
  name: 'vr0'
  location: location
  dependsOn: [
    vpnGw
  ]
  properties: {
    sku: 'Standard'
  }
}

resource routeServerIpConfig 'Microsoft.Network/virtualHubs/ipConfigurations@2020-11-01' = if(deployVr) {
  name: 'vr0'
  parent: routeServer
  properties: {
    subnet: {
      id: onPremVnet.properties.subnets[4].id
    }
  }
}

module vpnGw 'vpngw.bicep' = if(deployErVpn) {
  name: 'vpngw'
  dependsOn: [
    onPremVnet
  ]
  params: {
    gwName: 'vpngw'
    gwSubnetId: onPremVnet.properties.subnets[0].id
    location: location
    asn: 64630
  }
}

resource vWanLngIn0 'Microsoft.Network/localNetworkGateways@2020-11-01' = {
  name: 'toAzureIn0'
  location: location
  properties: {
    gatewayIpAddress: vWanVpnIn0
    localNetworkAddressSpace: {
      addressPrefixes: [
        '10.0.6.0/24'
      ]
    }
  }
}

resource vWanLngIn1 'Microsoft.Network/localNetworkGateways@2020-11-01' = {
  name: 'toAzureIn1'
  location: location
  properties: {
    gatewayIpAddress: vWanVpnIn1
    localNetworkAddressSpace: {
      addressPrefixes: [
        '10.0.6.0/24'
      ]
    }
  }
}

module onPremAzureIn0Connection 'vpnConnection.bicep' = {
  name: 'toAzureIn0'
  dependsOn: [
    [
      vpnGw
    ]
  ]
  params: {
    connectionName: 'toAzureIn0'
    lngId: vWanLngIn0.id
    location: location
    vpnGwId: vpnGw.outputs.vpnGwId
    vpnPreSharedKey: vpnPreSharedKey
  }
}

module onPremAzureIn1Connection 'vpnConnection.bicep' = {
  name: 'toAzureIn1'
  dependsOn: [
    [
      onPremAzureIn0Connection
    ]
  ]
  params: {
    connectionName: 'toAzureIn1'
    lngId: vWanLngIn1.id
    location: location
    vpnGwId: vpnGw.outputs.vpnGwId
    vpnPreSharedKey: vpnPreSharedKey
  }
}

module onPremVm 'vm.bicep' = {
  name: 'onpremvm0'
  params: {
    location: location
    subnetId: onPremVnet.properties.subnets[1].id
    vmName: 'onpremvm0'
    createPublicIpNsg: true
  }
}

resource onPremRt 'Microsoft.Network/routeTables@2020-11-01' = {
  name: 'onpremvm-rt'
  location: location
  properties: {
    routes: [
      {
        name: 'toAvs'
        properties: {
          addressPrefix: '10.0.7.0/24'
          nextHopIpAddress: '172.22.0.36'
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

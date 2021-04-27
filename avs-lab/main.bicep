param location string = 'francecentral'
@secure()
param adminPassword string
param deployErVpn bool = false


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
  name: 'ergw'
  params: {
    gwSubnetId: vnet.properties.subnets[0].id
    location: location
  }
}

resource routeServer 'Microsoft.Network/virtualHubs@2020-11-01' = {
  name: 'vr'
  location: location
  properties: {
    sku: 'Standard'
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



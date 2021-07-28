param location string
param gwSubnetId string
param asn int

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
  name: 'vpn-gw'
  location: location
  properties: {
    gatewayType: 'Vpn'
    sku: {
      name: 'Standard'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: gwSubnetId
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    bgpSettings: {
      asn: asn
    }
    enableBgp: true
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation1'
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: 'vpngw-pip'
  location: location
  sku: {
    name:'Basic'
    tier:'Regional'
  }
  properties: {
   publicIPAllocationMethod: 'Dynamic'
  }
}

output vpnGwId string = vpnGateway.id

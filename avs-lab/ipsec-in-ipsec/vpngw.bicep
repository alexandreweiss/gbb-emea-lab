param location string
param gwName string
param gwSubnetId string
param asn int

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
  name: gwName
  location: location
  dependsOn: [
    publicIp
  ]
  properties: {
    gatewayType: 'Vpn'
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
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
  name: '${gwName}-pip'
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

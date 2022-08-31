param location string = 'westeurope'
@secure()
param vpnPreSharedKey string
param lng1Id string
param lng2Id string
param vpnGwId string

resource spokeGw 'Microsoft.Network/localNetworkGateways@2022-01-01' = {
  name: 'toSpokeGw'
  location: location
  properties: {
    bgpSettings: {
      asn: 65510
      bgpPeeringAddress: '169.254.100.1'
      peerWeight: 0
    }
    gatewayIpAddress: '20.23.170.41'
    localNetworkAddressSpace: {
      addressPrefixes: [
        '169.254.100.1/32'
      ]
    }
  }
}

resource spokeHaGw 'Microsoft.Network/localNetworkGateways@2022-01-01' = {
  name: 'toSpokeHaGw'
  location: location
  properties: {
    bgpSettings: {
      asn: 65510
      bgpPeeringAddress: '169.254.100.5'
      peerWeight: 0
    }
    gatewayIpAddress: '20.123.252.136'
    localNetworkAddressSpace: {
      addressPrefixes: [
        '169.254.100.5/32'
      ]
    }
  }
}

resource azureToSpokeGw 'Microsoft.Network/connections@2022-01-01' = {
  name: 'azureToSpokeGw'
  location: location
  properties: {
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    connectionMode: 'Default'
    enableBgp: true
    sharedKey: vpnPreSharedKey
    virtualNetworkGateway1: {
      id: vpnGwId
      properties:{
        
      }
    }
    localNetworkGateway2: {
      id: lng1Id
      properties: {
        
      }
    }
  }
}

resource azureToSpokeHaGw 'Microsoft.Network/connections@2022-01-01' = {
  name: 'azureToSpokeHaGw'
  location: location
  properties: {
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    connectionMode: 'Default'
    enableBgp: true
    sharedKey: vpnPreSharedKey
    virtualNetworkGateway1: {
      id: vpnGwId
      properties:{
        
      }
    }
    localNetworkGateway2: {
      id: lng2Id
      properties: {
        
      }
    }
  }
}

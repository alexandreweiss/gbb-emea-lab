param location string
param connectionName string
param vpnGwId string
param lngId string
@secure()
param vpnPreSharedKey string

resource onPremAzureIn1Connection 'Microsoft.Network/connections@2020-11-01' = {
  name: connectionName
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
      id: lngId
      properties: {
        
      }
    }
  }
}

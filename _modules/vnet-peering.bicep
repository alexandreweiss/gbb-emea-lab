param aSideName string
param bSideName string
param aSideId string
param bSideId string

resource peeringAtoB 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${aSideName}/${aSideName}To${bSideName}'
  properties: {
    remoteVirtualNetwork: {
      id: bSideId
    }
    allowGatewayTransit: true
  }
}

resource peeringBtoA 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${bSideName}/${bSideName}To${aSideName}'
  properties: {
    remoteVirtualNetwork: {
      id: aSideId
    }
    allowForwardedTraffic: true
    useRemoteGateways: true
  }
}

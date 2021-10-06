param parentVnetName string
param remoteVnetName string
param parentVnet object
param remoteVnet object

var parentVnetVar = resourceId('Microsoft.Network/virtualNetworks', remoteVnetName)

resource peeringTo 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${parentVnetName}/to${remoteVnetName}'
  parent: parentVnetVar
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnet.id
    }
  }
}

resource peeringFrom 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${remoteVnetName}/to${parentVnetName}'
  parent: resourceId('Microsoft.Network/virtualNetworks', remoteVnetName)
  properties: {
    remoteVirtualNetwork: {
      id: parentVnet.id
    }
  }
}

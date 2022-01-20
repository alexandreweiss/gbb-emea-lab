param location string
param name string

resource anm 'Microsoft.Network/networkManagers@2021-02-01-preview' = {
  name: name
  location: location
  properties: {
    displayName: name
    networkManagerScopes: {
      subscriptions: [
        subscription().id
      ]
    }
    networkManagerScopeAccesses: [
      'Connectivity'
    ]
  }
}

output anmId string = anm.id

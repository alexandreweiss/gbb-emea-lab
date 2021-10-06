param location string

resource publicIpPrefix 'Microsoft.Network/publicIPPrefixes@2021-02-01' = {
  name: 'publicIpPrefix'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    prefixLength: 31
    publicIPAddressVersion: 'IPv4'
  }
}

resource natGateway 'Microsoft.Network/natGateways@2020-06-01' = {
  name: 'natGateway'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpPrefixes: [
      {
        id: publicIpPrefix.id
      }
    ]
  }
}

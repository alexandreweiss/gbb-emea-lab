param wwwIp string
param vnetId string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'test.local'
  location: 'global'
}

resource www 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${privateDnsZone.name}/www'
  location: 'global'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: wwwIp
      }
    ]
  }
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZone.name}/toVnet'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

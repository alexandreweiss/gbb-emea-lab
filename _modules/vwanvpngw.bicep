param location string
param asn int
param gwName string
param vHubId string
param vWanId string
param site1Asn int
param site1Ip string

resource vpnGw 'Microsoft.Network/vpnGateways@2021-02-01' = {
  name: gwName
  location: location
  properties: {
    bgpSettings: {
      asn: asn
    }
    virtualHub: {
      id: vHubId
    }
  } 
}

resource vpnSite1 'Microsoft.Network/vpnSites@2021-02-01' = {
  name: 'Stella'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.15.0/24'
      ]
    }
    bgpProperties: {
      asn: site1Asn
      bgpPeeringAddress: '192.168.15.111'
      peerWeight: 0
    }
    deviceProperties: {
      deviceVendor: 'Ubiquiti'
      deviceModel: 'ER-X'
      linkSpeedInMbps: 12
    }
    ipAddress: site1Ip
    virtualWan: {
      id: vWanId
    }
  }
  
}

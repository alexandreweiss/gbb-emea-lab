param location string
param asn int
param gwName string
param vHubId string
// param vWanId string
// param site1Asn int
// param site1Ip string
// param site1Name string
// param site1BpgIp string
// param site1Bw int

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

// resource vpnSite1 'Microsoft.Network/vpnSites@2021-02-01' = {
//   name: site1Name
//   location: location
//   properties: {
//     bgpProperties: {
//       asn: site1Asn
//       bgpPeeringAddress: site1BpgIp
//       peerWeight: 0
//     }
//     deviceProperties: {
//       deviceVendor: 'Ubiquiti'
//       deviceModel: 'ER-X'
//       linkSpeedInMbps: site1Bw
//     }
//     ipAddress: site1Ip
//     virtualWan: {
//       id: vWanId
//     }
//   }
  
// }

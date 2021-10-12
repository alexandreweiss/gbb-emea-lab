param location string
param name string
param enableB2b bool = true
param subnetId string
param peer1Asn int
param peer1Ip string
param peer2Asn int
param peer2Ip string

resource routeServer 'Microsoft.Network/virtualHubs@2021-02-01' = {
  name: name
  location: location
  properties: {
    sku: 'Standard'
    allowBranchToBranchTraffic: enableB2b
  }
}

resource routeServerIpConfig 'Microsoft.Network/virtualHubs/ipConfigurations@2021-02-01' = {
  name: '${routeServer.name}/ipConfig'
  dependsOn: [
    routeServer
  ]
  properties: {
    subnet: {
      id: subnetId
    }
    publicIPAddress: {
      id: publicIp.id
    }
  }
}

resource routeServerPeer1 'Microsoft.Network/virtualHubs/bgpConnections@2021-02-01' = {
  dependsOn: [
    routeServerIpConfig
  ]
  name: '${routeServer.name}/toPeer1'
  properties: {
    peerAsn: peer1Asn
    peerIp: peer1Ip
  }
}

resource routeServerPeer2 'Microsoft.Network/virtualHubs/bgpConnections@2021-02-01' = {
  dependsOn: [
    routeServerPeer1
  ]
  name: '${routeServer.name}/toPeer2'
  properties: {
    peerAsn: peer2Asn
    peerIp: peer2Ip
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: '${name}-pip'
  location: location
  sku: {
    name:'Standard'
    tier:'Regional'
  }
  properties: {
   publicIPAllocationMethod: 'Static'
  }
}

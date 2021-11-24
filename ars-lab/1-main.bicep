param location string = 'westeurope'

module hub '../_modules/vnetMultiSubnets.bicep' = {
  name: 'hub'
  params: {
    addressSpace: '172.20.20.0/24'
    location: location
    subnets: [
      {
        name: 'RouteServerSubnet'
        addressPrefix: '172.20.20.0/27'
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '172.20.20.32/27'
      }
      {
        name: 'default'
        addressPrefix: '172.20.20.64/28'
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '172.20.20.96/27'
      }
    ]
    vnetName: 'hub'
  }
}

module spoke1 '../_modules/vnet.bicep' = {
  name: 'spoke1'
  params: {
    addressPrefix: '172.20.21.0/28'
    addressSpace: '172.20.21.0/24'
    location: location
    vnetName: 'spoke1'
  }
}

module vpnGw '../_modules/vpngw.bicep' = {
  name: 'vpnGw'
  params: {
    asn: 65515
    gwSubnetId: hub.outputs.subnets[3].id
    location: location
    sku: 'HighPerformance'
  }
}

resource peeringHubSpoke1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${hub.name}/hubToSpoke1'
  properties: {
    remoteVirtualNetwork: {
      id: spoke1.outputs.vnetId
    }
    allowGatewayTransit: true
  }
}

resource peeringSpoke1Hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${spoke1.name}/spoke1ToHub'
  properties: {
    remoteVirtualNetwork: {
      id: hub.outputs.vnetId
    }
    allowForwardedTraffic: true
    useRemoteGateways: true
  }
}

module routeServer '../_modules/ars.bicep' = {
  name: 'ars'
  params: {
    location:location
    name: 'ars'
    enableB2b: true
    subnetId: hub.outputs.subnets[0].id
    peer1Asn: 65001
    peer1Ip: hubVm.outputs.nicPrivateIp
  }
}

module spoke1Vm '../_modules/vm.bicep' = {
  name: 'spoke1Vm'
  params: {
    location: location
    subnetId: spoke1.outputs.subnetId
    vmName: 'spoke1Vm'
  }
}

module hubVm '../_modules/vm.bicep' = {
  name: 'hubVm'
  params: {
    location: location
    subnetId: hub.outputs.subnets[2].id
    vmName: 'hubVm'
    enableForwarding: true
    enableCloudInit: true
    cloudInitValue: 'IyEvYmluL2Jhc2gKCiMjIE5PVEU6CiMjIGJlZm9yZSBydW5uaW5nIHRoZSBzY3JpcHQsIGN1c3RvbWl6ZSB0aGUgdmFsdWVzIG9mIHZhcmlhYmxlcyBzdWl0YWJsZSBmb3IgeW91ciBkZXBsb3ltZW50LiAKIyMgYXNuX3F1YWdnYTogQXV0b25vbW91cyBzeXN0ZW0gbnVtYmVyIGFzc2lnbmVkIHRvIHF1YWdnYQojIyBiZ3Bfcm91dGVySWQ6IElQIGFkZHJlc3Mgb2YgcXVhZ2dhIFZNCiMjIGJncF9uZXR3b3JrMTogZmlyc3QgbmV0d29yayBhZHZlcnRpc2VkIGZyb20gcXVhZ2dhIHRvIHRoZSByb3V0ZXIgc2VydmVyIChpbmNsdXNpdmUgb2Ygc3VibmV0bWFzaykKIyMgYmdwX25ldHdvcmsyOiBzZWNvbmQgbmV0d29yayBhZHZlcnRpc2VkIGZyb20gcXVhZ2dhIHRvIHRoZSByb3V0ZXIgc2VydmVyIChpbmNsdXNpdmUgb2Ygc3VibmV0bWFzaykKIyMgYmdwX25ldHdvcmszOiB0aGlyZCBuZXR3b3JrIGFkdmVydGlzZWQgZnJvbSBxdWFnZ2EgdG8gdGhlIHJvdXRlciBzZXJ2ZXIgKGluY2x1c2l2ZSBvZiBzdWJuZXRtYXNrKQojIyByb3V0ZXNlcnZlcl9JUDE6IGZpcnN0IElQIGFkZHJlc3Mgb2YgdGhlIHJvdXRlciBzZXJ2ZXIgCiMjIHJvdXRlc2VydmVyX0lQMjogc2Vjb25kIElQIGFkZHJlc3Mgb2YgdGhlIHJvdXRlciBzZXJ2ZXIKCmFzbl9xdWFnZ2E9NjUwMDEKYmdwX3JvdXRlcklkPTE3Mi4yMC4yMC42OApiZ3BfbmV0d29yazE9MTcyLjIwLjIwLjY0LzI0CnJvdXRlc2VydmVyX0lQMT0xNzIuMjAuMjAuNApyb3V0ZXNlcnZlcl9JUDI9MTcyLjIwLjIwLjUKCgpzdWRvIGFwdC1nZXQgLXkgdXBkYXRlCgojIyBJbnN0YWxsIHRoZSBRdWFnZ2Egcm91dGluZyBkYWVtb24KZWNobyAiSW5zdGFsbGluZyBxdWFnZ2EiCnN1ZG8gYXB0LWdldCAteSBpbnN0YWxsIHF1YWdnYQoKIyMgIHJ1biB0aGUgdXBkYXRlcyBhbmQgZW5zdXJlIHRoZSBwYWNrYWdlcyBhcmUgdXAgdG8gZGF0ZSBhbmQgdGhlcmUgaXMgbm8gbmV3IHZlcnNpb24gYXZhaWxhYmxlIGZvciB0aGUgcGFja2FnZXMKc3VkbyBhcHQtZ2V0IC15IHVwZGF0ZSAtLWZpeC1taXNzaW5nCgojIyBFbmFibGUgSVB2NCBmb3J3YXJkaW5nCmVjaG8gIm5ldC5pcHY0LmNvbmYuYWxsLmZvcndhcmRpbmc9MSIgfCBzdWRvIHRlZSAtYSAvZXRjL3N5c2N0bC5jb25mIAplY2hvICJuZXQuaXB2NC5jb25mLmRlZmF1bHQuZm9yd2FyZGluZz0xIiB8IHN1ZG8gdGVlIC1hIC9ldGMvc3lzY3RsLmNvbmYgCnN5c2N0bCAtcAoKIyMgQ3JlYXRlIGEgZm9sZGVyIGZvciB0aGUgcXVhZ2dhIGxvZ3MKZWNobyAiY3JlYXRpbmcgZm9sZGVyIGZvciBxdWFnZ2EgbG9ncyIKc3VkbyBta2RpciAtcCAvdmFyL2xvZy9xdWFnZ2EgJiYgc3VkbyBjaG93biBxdWFnZ2E6cXVhZ2dhIC92YXIvbG9nL3F1YWdnYQpzdWRvIHRvdWNoIC92YXIvbG9nL3plYnJhLmxvZwpzdWRvIGNob3duIHF1YWdnYTpxdWFnZ2EgL3Zhci9sb2cvemVicmEubG9nCgojIyBDcmVhdGUgdGhlIGNvbmZpZ3VyYXRpb24gZmlsZXMgZm9yIFF1YWdnYSBkYWVtb24KZWNobyAiY3JlYXRpbmcgZW1wdHkgcXVhZ2dhIGNvbmZpZyBmaWxlcyIKc3VkbyB0b3VjaCAvZXRjL3F1YWdnYS9iYWJlbGQuY29uZgpzdWRvIHRvdWNoIC9ldGMvcXVhZ2dhL2JncGQuY29uZgpzdWRvIHRvdWNoIC9ldGMvcXVhZ2dhL2lzaXNkLmNvbmYKc3VkbyB0b3VjaCAvZXRjL3F1YWdnYS9vc3BmNmQuY29uZgpzdWRvIHRvdWNoIC9ldGMvcXVhZ2dhL29zcGZkLmNvbmYKc3VkbyB0b3VjaCAvZXRjL3F1YWdnYS9yaXBkLmNvbmYKc3VkbyB0b3VjaCAvZXRjL3F1YWdnYS9yaXBuZ2QuY29uZgpzdWRvIHRvdWNoIC9ldGMvcXVhZ2dhL3Z0eXNoLmNvbmYKc3VkbyB0b3VjaCAvZXRjL3F1YWdnYS96ZWJyYS5jb25mCgojIyBDaGFuZ2UgdGhlIG93bmVyc2hpcCBhbmQgcGVybWlzc2lvbiBmb3IgY29uZmlndXJhdGlvbiBmaWxlcywgdW5kZXIgL2V0Yy9xdWFnZ2EgZm9sZGVyCmVjaG8gImFzc2lnbiB0byBxdWFnZ2EgdXNlciB0aGUgb3duZXJzaGlwIG9mIGNvbmZpZyBmaWxlcyIKc3VkbyBjaG93biBxdWFnZ2E6cXVhZ2dhIC9ldGMvcXVhZ2dhL2JhYmVsZC5jb25mICYmIHN1ZG8gY2htb2QgNjQwIC9ldGMvcXVhZ2dhL2JhYmVsZC5jb25mCnN1ZG8gY2hvd24gcXVhZ2dhOnF1YWdnYSAvZXRjL3F1YWdnYS9iZ3BkLmNvbmYgJiYgc3VkbyBjaG1vZCA2NDAgL2V0Yy9xdWFnZ2EvYmdwZC5jb25mCnN1ZG8gY2hvd24gcXVhZ2dhOnF1YWdnYSAvZXRjL3F1YWdnYS9pc2lzZC5jb25mICYmIHN1ZG8gY2htb2QgNjQwIC9ldGMvcXVhZ2dhL2lzaXNkLmNvbmYKc3VkbyBjaG93biBxdWFnZ2E6cXVhZ2dhIC9ldGMvcXVhZ2dhL29zcGY2ZC5jb25mICYmIHN1ZG8gY2htb2QgNjQwIC9ldGMvcXVhZ2dhL29zcGY2ZC5jb25mCnN1ZG8gY2hvd24gcXVhZ2dhOnF1YWdnYSAvZXRjL3F1YWdnYS9vc3BmZC5jb25mICYmIHN1ZG8gY2htb2QgNjQwIC9ldGMvcXVhZ2dhL29zcGZkLmNvbmYKc3VkbyBjaG93biBxdWFnZ2E6cXVhZ2dhIC9ldGMvcXVhZ2dhL3JpcGQuY29uZiAmJiBzdWRvIGNobW9kIDY0MCAvZXRjL3F1YWdnYS9yaXBkLmNvbmYKc3VkbyBjaG93biBxdWFnZ2E6cXVhZ2dhIC9ldGMvcXVhZ2dhL3JpcG5nZC5jb25mICYmIHN1ZG8gY2htb2QgNjQwIC9ldGMvcXVhZ2dhL3JpcG5nZC5jb25mCnN1ZG8gY2hvd24gcXVhZ2dhOnF1YWdnYXZ0eSAvZXRjL3F1YWdnYS92dHlzaC5jb25mICYmIHN1ZG8gY2htb2QgNjYwIC9ldGMvcXVhZ2dhL3Z0eXNoLmNvbmYKc3VkbyBjaG93biBxdWFnZ2E6cXVhZ2dhIC9ldGMvcXVhZ2dhL3plYnJhLmNvbmYgJiYgc3VkbyBjaG1vZCA2NDAgL2V0Yy9xdWFnZ2EvemVicmEuY29uZgoKIyMgaW5pdGlhbCBzdGFydHVwIGNvbmZpZ3VyYXRpb24gZm9yIFF1YWdnYSBkYWVtb25zIGFyZSByZXF1aXJlZAplY2hvICJTZXR0aW5nIHVwIGRhZW1vbiBzdGFydHVwIGNvbmZpZyIKZWNobyAnemVicmE9eWVzJyA+IC9ldGMvcXVhZ2dhL2RhZW1vbnMKZWNobyAnYmdwZD15ZXMnID4+IC9ldGMvcXVhZ2dhL2RhZW1vbnMKZWNobyAnb3NwZmQ9bm8nID4+IC9ldGMvcXVhZ2dhL2RhZW1vbnMKZWNobyAnb3NwZjZkPW5vJyA+PiAvZXRjL3F1YWdnYS9kYWVtb25zCmVjaG8gJ3JpcGQ9bm8nID4+IC9ldGMvcXVhZ2dhL2RhZW1vbnMKZWNobyAncmlwbmdkPW5vJyA+PiAvZXRjL3F1YWdnYS9kYWVtb25zCmVjaG8gJ2lzaXNkPW5vJyA+PiAvZXRjL3F1YWdnYS9kYWVtb25zCmVjaG8gJ2JhYmVsZD1ubycgPj4gL2V0Yy9xdWFnZ2EvZGFlbW9ucwoKZWNobyAiYWRkIHplYnJhIGNvbmZpZyIKY2F0IDw8RU9GID4gL2V0Yy9xdWFnZ2EvemVicmEuY29uZgohCmludGVyZmFjZSBldGgwCiEKaW50ZXJmYWNlIGxvCiEKaXAgZm9yd2FyZGluZwohCmxpbmUgdnR5CiEKRU9GCgoKZWNobyAiYWRkIHF1YWdnYSBjb25maWciCmNhdCA8PEVPRiA+IC9ldGMvcXVhZ2dhL2JncGQuY29uZgohCnJvdXRlciBiZ3AgJGFzbl9xdWFnZ2EKIGJncCByb3V0ZXItaWQgJGJncF9yb3V0ZXJJZAogbmV0d29yayAkYmdwX25ldHdvcmsxCiBuZWlnaGJvciAkcm91dGVzZXJ2ZXJfSVAxIHJlbW90ZS1hcyA2NTUxNQogbmVpZ2hib3IgJHJvdXRlc2VydmVyX0lQMSBzb2Z0LXJlY29uZmlndXJhdGlvbiBpbmJvdW5kCiBuZWlnaGJvciAkcm91dGVzZXJ2ZXJfSVAyIHJlbW90ZS1hcyA2NTUxNQogbmVpZ2hib3IgJHJvdXRlc2VydmVyX0lQMiBzb2Z0LXJlY29uZmlndXJhdGlvbiBpbmJvdW5kCiEKIGFkZHJlc3MtZmFtaWx5IGlwdjYKIGV4aXQtYWRkcmVzcy1mYW1pbHkKIGV4aXQKIQpsaW5lIHZ0eQohCkVPRgoKIyMgdG8gc3RhcnQgZGFlbW9ucyBhdCBzeXN0ZW0gc3RhcnR1cAplY2hvICJlbmFibGUgemVicmEgYW5kIHF1YWdnYSBkYWVtb25zIGF0IHN5c3RlbSBzdGFydHVwIgpzeXN0ZW1jdGwgZW5hYmxlIHplYnJhLnNlcnZpY2UKc3lzdGVtY3RsIGVuYWJsZSBiZ3BkLnNlcnZpY2UKCiMjIHJ1biB0aGUgZGFlbW9ucwplY2hvICJzdGFydCB6ZWJyYSBhbmQgcXVhZ2dhIGRhZW1vbnMiCnN5c3RlbWN0bCBzdGFydCB6ZWJyYSAKc3lzdGVtY3RsIHN0YXJ0IGJncGQK'
  }
}

module hubVm2 '../_modules/vm.bicep' = {
  name: 'hubVm2'
  params: {
    location: location
    subnetId: hub.outputs.subnets[2].id
    vmName: 'hubVm2'
    enableForwarding: true
  }
}

module bastion '../_modules/bastion.bicep' = {
  name: 'bastion'
  dependsOn: [
    routeServer
  ]
  params: {
    location: location
    name: 'bastion'
    subnetId: hub.outputs.subnets[1].id 
  }
}


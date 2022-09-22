// Deploy command
// az group create -n pl-lab -l westeurope
// az deployment group create -n deploy-pl -g pl-lab --template-file main.bicep

param location string = 'westeurope'

module hub '../_modules/vnetMultiSubnets.bicep' = {
  name: 'hub'
  params: {
    vnetName: 'hub'
    location: location
    addressSpace: '10.0.0.0/24'
    subnets: [
      {
        name: 'default'
        addressPrefix: '10.0.0.0/28'
        delegations: []
      }
      {
        name: 'GatewayEth0Mgt'
        addressPrefix: '10.0.0.16/28'
        delegations: []
      }
      {
        name: 'GatewayEth1'
        addressPrefix: '10.0.0.32/28'
        delegations: []
      }
      {
        name: 'GatewayEth0Mgt-hagw'
        addressPrefix: '10.0.0.64/28'
        delegations: []
      }
      {
        name: 'GatewayEth1-hagw'
        addressPrefix: '10.0.0.80/28'
        delegations: []
      }
      {
        name: 'InboundDnsResolver'
        addressPrefix: '10.0.0.96/28'
        delegations: [
          {
            name: 'DnsResolver'
            properties: {
              serviceName:'Microsoft.Network/DnsResolvers'
            }
          }
        ]
      }
    ]
  }
}

module spoke '../_modules/vnetMultiSubnets.bicep' = {
  name: 'spoke'
  params: {
    vnetName: 'spoke'
    location: location
    addressSpace: '10.0.1.0/24'
    subnets: [
      {
        name: 'default'
        addressPrefix: '10.0.1.0/28'
        delegations: []
      }
      {
        name: 'GatewayEth0Mgt'
        addressPrefix: '10.0.1.16/28'
        delegations: []
      }
      {
        name: 'GatewayEth0Mgt-hagw'
        addressPrefix: '10.0.1.32/28'
        delegations: []
      }
      {
        name: 'privateEndpoints'
        addressPrefix: '10.0.1.48/28'
        delegations: []
      }
    ]
  }
}

module pl '../_modules/vnet.bicep' = {
  name: 'pl'
  params: {
    addressPrefix: '10.0.2.0/28'
    addressSpace: '10.0.2.0/24'
    location: location
    vnetName: 'pl'
    networkPoliciesState: 'Enabled'
  }
}

resource peeringHubSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${hub.name}/hubToSpoke'
  properties: {
    remoteVirtualNetwork: {
      id: spoke.outputs.vnetId
    }
  }
}

resource peeringSpokeHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${spoke.name}/spokeToHub'
  properties: {
    remoteVirtualNetwork: {
      id: hub.outputs.vnetId
    }
  }
}

resource peeringHubPl 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${hub.name}/hubToPl'
  properties: {
    remoteVirtualNetwork: {
      id: pl.outputs.vnetId
    }
  }
}

resource peeringPlHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${pl.name}/plToHub'
  properties: {
    remoteVirtualNetwork: {
      id: hub.outputs.vnetId
    }
  }
}

module sa '../_modules/storageaccount.bicep' = {
  dependsOn: [
    peeringHubPl
    peeringHubSpoke
    peeringPlHub
    peeringSpokeHub
  ]
  name: 'sapl002'
  params: {
    location: location
    name: 'sapl002'
  }
}

resource peSa 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pesapl001'
  location: location
  properties: {
    subnet: {
      id: pl.outputs.subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pesapl001'
        properties: {
          privateLinkServiceId: sa.outputs.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource pe2Sa 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pesapl002'
  location: location
  properties: {
    subnet: {
      id: hub.outputs.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: 'pesapl002'
        properties: {
          privateLinkServiceId: sa.outputs.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource peSaSpoke 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pesapl003'
  location: location
  properties: {
    subnet: {
      id: spoke.outputs.subnets[3].id
    }
    privateLinkServiceConnections: [
      {
        name: 'pesapl001'
        properties: {
          privateLinkServiceId: sa.outputs.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource peSaSpokeDnsRecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  name: '${peSaSpoke.name}/peDnsGroup'
   properties: {
     privateDnsZoneConfigs: [
       {
         name: 'primary'
         properties: {
          privateDnsZoneId: privateDnsZone.id
         }
       }
     ]
   }
}

module spokeVm '../_modules/vm.bicep' = {
  name: 'spokeVm'
  params: {
    location: location
    subnetId: spoke.outputs.subnets[0].id
    vmName: 'spokeVm'
  }
}

module plVm '../_modules/vm.bicep' = {
  name: 'plVm'
  params: {
    location: location
    subnetId: pl.outputs.subnetId
    vmName: 'plVm'
  }
}

module hubVm '../_modules/vm.bicep' = {
  name: 'hubVm'
  params: {
    location: location
    subnetId: hub.outputs.subnets[0].id
    vmName: 'hubVm'
    
  }
}

// PRIVATE DNS RESOLVER

resource dnsResolver 'Microsoft.Network/dnsResolvers@2020-04-01-preview' = {
  name: 'dnsResolverWe'
  location: location
  properties: {
    virtualNetwork: {
      id: hub.outputs.vnetId
    }
  }
}

resource dnsInbound 'Microsoft.Network/dnsResolvers/inboundEndpoints@2020-04-01-preview' = {
  name: '${dnsResolver.name}/dnsInbound'
  location: location
  properties: {
    ipConfigurations: [
      {
        subnet: {
          id: hub.outputs.subnets[5].id
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZone.name}/toHub'
  location: 'global'
  properties: {
    registrationEnabled: false
   virtualNetwork: {
    id: hub.outputs.vnetId
   } 
  }
}


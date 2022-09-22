// Deploy command
// az group create -n pl-lab -l westeurope
// az deployment group create -n deploy-pl -g pl-lab --template-file main.bicep

param location string = 'westeurope'
param transitVnetId string = '/subscriptions/56474334-838c-466b-9ac3-3903c86886e7/resourceGroups/rg-av-AVX-Transit-Firenet-Vnet-185481/providers/Microsoft.Network/virtualNetworks/AVX-Transit-Firenet-Vnet'
param transitPrivateEndpointsSubnet string = '${transitVnetId}/subnets/privateEndpoints'
param transitDnsInboundSubnet string = '${transitVnetId}/subnets/InboundDnsResolver'

module sa '../_modules/storageaccount.bicep' = {
  name: 'sapl001'
  params: {
    location: location
    name: 'sapl001'
  }
}

resource peSa 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pe0-sapl001'
  location: location
  properties: {
    subnet: {
      id: transitPrivateEndpointsSubnet
    }
    privateLinkServiceConnections: [
      {
        name: 'pe0-sapl001'
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

resource peSaDnsRecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  name: '${peSa.name}/peDnsGroup'
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

// PRIVATE DNS RESOLVER

resource dnsResolver 'Microsoft.Network/dnsResolvers@2020-04-01-preview' = {
  name: 'dnsResolver'
  location: location
  properties: {
    virtualNetwork: {
      id: transitVnetId
    }
  }
}

// Private resolver Inbound endpoint
resource dnsInbound 'Microsoft.Network/dnsResolvers/inboundEndpoints@2020-04-01-preview' = {
  name: '${dnsResolver.name}/dnsInbound'
  location: location
  properties: {
    ipConfigurations: [
      {
        subnet: {
          id: transitDnsInboundSubnet
        }
      }
    ]
  }
}

// Private DNS Zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
}

// Private DNS zone link to vnet
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZone.name}/toTransit'
  location: 'global'
  properties: {
    registrationEnabled: false
   virtualNetwork: {
    id: transitVnetId
   } 
  }
}

output inboundDnsIp string = dnsInbound.properties.ipConfigurations[0].privateIpAddress

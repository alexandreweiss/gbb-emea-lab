param vnetName string
param addressPrefix string
param addressSpace string
param location string
param tags object = {}
param routeTableId string = 'non'
@allowed([
  'Enabled'
  'Disabled'
])
param networkPoliciesState string = 'Enabled'

var routeTableVar = {
  routeTable: {
    id: routeTableId 
  }
}

var nonRouteTable = {
  addressPrefix: addressPrefix
  privateEndpointNetworkPolicies: networkPoliciesState
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: routeTableId == 'non' ? nonRouteTable : union(nonRouteTable, routeTableVar)
      }
    ]
  }
  tags: tags
}

output vnetId string = vnet.id
output subnetId string = vnet.properties.subnets[0].id

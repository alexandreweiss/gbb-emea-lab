param vnetName string
param addressSpace string
param addressPrefix string
param location string
param routeTableId string = 'non'

var routeTableVar = {
  routeTable: {
    id: routeTableId 
  }
}

var nonRouteTable = {
  addressPrefix: addressPrefix
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
}

output vnetId string = vnet.id
output subnetId string = vnet.properties.subnets[0].id

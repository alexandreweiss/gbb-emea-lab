param vnetName string
param subnets array
param addressSpace string
param location string


resource vnet 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [ for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
          delegations: subnet.delegations != [] ? subnet.delegations : []
        }
      }]
  }
}

output vnetId string = vnet.id
output subnets array = vnet.properties.subnets

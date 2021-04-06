param nicName string
param location string
param subnetId string

resource nic 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: nicName
  location: location
  properties: {
    enableIPForwarding:true
    ipConfigurations: [
      {
        name: 'ipconfig0'
        properties: {
          primary:true
          privateIPAllocationMethod:'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

output nicId string = nic.id

param nicName string
param location string
param subnetId string
param enableForwarding bool
param createPublicIp bool

//var publicIpId = createPublicIp ? json('{ id: ${publicIp.id} }') : json('notCreated')

resource nic 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: nicName
  location: location
  properties: {
    enableIPForwarding: enableForwarding
    ipConfigurations: [
      {
        name: 'ipconfig0'
        properties: {
          primary:true
          privateIPAllocationMethod:'Dynamic'
          subnet: {
            id: subnetId
          }
          //publicIPAddress: publicIpId
        }
      }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-08-01' = if(createPublicIp) {
  name: nicName
  location: location
  sku: {
    name:'Standard'
    tier:'Regional'
  }
  properties: {
   publicIPAllocationMethod: 'Static' 
  }
}

output nicId string = nic.id
output nicPrivateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress

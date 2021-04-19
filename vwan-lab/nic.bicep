param nicName string
param location string
param subnetId string
param enableForwarding bool
param createPublicIp bool

resource nicPip 'Microsoft.Network/networkInterfaces@2020-08-01' = if(createPublicIp) {
  name: '${nicName}-public'
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
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

resource nicNoPip 'Microsoft.Network/networkInterfaces@2020-08-01' = if(!createPublicIp) {
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
        }
      }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-08-01' = if(createPublicIp) {
  name: '${nicName}-pip'
  location: location
  sku: {
    name:'Standard'
    tier:'Regional'
  }
  properties: {
   publicIPAllocationMethod: 'Static' 
  }
}

output nicId string = createPublicIp ? '${nicPip.id}' : '${nicNoPip.id}'
output nicPrivateIp string = createPublicIp ? '${nicPip.properties.ipConfigurations[0].properties.privateIPAddress}' : '${nicNoPip.properties.ipConfigurations[0].properties.privateIPAddress}' 

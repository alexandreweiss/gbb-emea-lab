param nicName string
param location string
param subnetId string
param enableForwarding bool = false
param createPublicIpNsg bool = false
param mySourceIp string
param vmName string


resource nicPip 'Microsoft.Network/networkInterfaces@2020-08-01' = if(createPublicIpNsg) {
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
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource nicNoPip 'Microsoft.Network/networkInterfaces@2020-08-01' = if(!createPublicIpNsg) {
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

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-08-01' = if(createPublicIpNsg) {
  name: '${nicName}-pip'
  location: location
  sku: {
    name:'Standard'
    tier:'Regional'
  }
  properties: {
   publicIPAllocationMethod: 'Static'
   dnsSettings: {
     domainNameLabel: vmName
   }
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = if(createPublicIpNsg) {
  name: '${vmName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh'
        properties: {
          access:'Allow'
          description:'Allow SSH from outside'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
          direction:'Inbound'
          protocol:'Tcp'
          priority: 200
          sourceAddressPrefix: mySourceIp
          sourcePortRange: '*'
        }
      }
      {
        name: 'deny-from-internet'
        properties: {
          access:'Deny'
          description:'Deny_From_Internet'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction:'Inbound'
          protocol:'*'
          priority: 210
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
        }
      }
      {
        name: 'allow-all-vnet-vnet'
        properties: {
          access:'Allow'
          description:'allow all vnets'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction:'Inbound'
          protocol:'*'
          priority: 220
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

output nicId string = createPublicIpNsg ? '${nicPip.id}' : '${nicNoPip.id}'
output nicPrivateIp string = createPublicIpNsg ? '${nicPip.properties.ipConfigurations[0].properties.privateIPAddress}' : '${nicNoPip.properties.ipConfigurations[0].properties.privateIPAddress}' 

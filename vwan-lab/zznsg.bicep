param name string
param location string
param mySourceIp string = '90.103.116.130'

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: '${name}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh'
        properties: {
          access:'Allow'
          description:'Allow SSH from outside'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction:'Inbound'
          protocol:'Tcp'
          priority: 200
          sourceAddressPrefix: mySourceIp
          sourcePortRange: '*'
        }
      }
    ]
  }
}


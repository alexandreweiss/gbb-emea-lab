param nicName string
param location string
param subnetId string
param enableForwarding bool = false
param createPublicIpNsg bool = false
param mySourceIp string
param vmName string
param lbBackendPoolId string = 'no'

var lbBackend = {
  loadBalancerBackendAddressPools: {
    id: lbBackendPoolId
  }
}

var nicProperties = {
  primary:true
  privateIPAllocationMethod:'Dynamic'
  subnet: {
    id: subnetId
  }
  publicIPAddress: {
    id: publicIp.id
  }
}

resource nicPip 'Microsoft.Network/networkInterfaces@2020-08-01' = if(createPublicIpNsg) {
  name: '${nicName}-public'
  location: location
  properties: {
    enableIPForwarding: enableForwarding
    ipConfigurations: [
      {
        name: 'ipconfig0'
        properties: lbBackendPoolId == 'no' ? nicProperties : union(nicProperties,lbBackend)
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
        name: 'allow-http'
        properties: {
          access:'Allow'
          description:'Allow probe from afd backend'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
          direction:'Inbound'
          protocol:'Tcp'
          priority: 210
          sourceAddressPrefix: mySourceIp
          sourcePortRange: '*'
        }
      }
      {
        name: 'allow-rfc1918C-in-out'
        properties: {
          access:'Allow'
          description:'Allow FRC1918 C from WW'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction:'Inbound'
          protocol:'*'
          priority: 305
          sourceAddressPrefix: '192.168.0.0/16'
          sourcePortRange: '*'
        }
      }
      {
        name: 'allow-rfc1918C-out'
        properties: {
          access:'Allow'
          description:'Allow FRC1918 C from WW'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction:'Outbound'
          protocol: '*'
          priority: 300
          sourceAddressPrefix: '192.168.0.0/16'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

output nicId string = createPublicIpNsg ? '${nicPip.id}' : '${nicNoPip.id}'
output nicPrivateIp string = createPublicIpNsg ? '${nicPip.properties.ipConfigurations[0].properties.privateIPAddress}' : '${nicNoPip.properties.ipConfigurations[0].properties.privateIPAddress}'
output nicPublicFqdn string = createPublicIpNsg ? '${publicIp.properties.ipAddress}' : 'NA'

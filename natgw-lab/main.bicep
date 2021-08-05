param vnetName string = 'natGwVnet'
param subNetName string = 'default'
param z1SubNetName string = 'z1Subnet'
param vnetAddressSpace string = '192.168.0.0/24'
param vnetSubnetPrefix string = '192.168.0.0/28'
param vnetZonalSubnetPrefix string = '192.168.0.16/28'
param bastionSubnetPrefix string = '192.168.0.32/27'
param natGatewayName string = 'natGateway'
param zonalNatGatewayName string = 'zonalNatGateway'
param location string = resourceGroup().location

var publicIpName = '${natGatewayName}-ip'
var zonalPublicIpName = '${natGatewayName}-zonal-ip'

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource zonalPublicIp 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: zonalPublicIpName
  location: location
  zones: [
    '1'
  ]
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource publicIpPrefix 'Microsoft.Network/publicIPPrefixes@2021-02-01' = {
  name: 'publicIpPrefix'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    prefixLength: 31
    publicIPAddressVersion: 'IPv4'
  }
}

resource natGateway 'Microsoft.Network/natGateways@2021-02-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicIp.id
      }
    ]
    publicIpPrefixes: [
      {
        id: publicIpPrefix.id
      }
    ]
  }
}

resource zonalNatGateway 'Microsoft.Network/natGateways@2021-02-01' = {
  name: zonalNatGatewayName
  location: location
  zones: [
    '1'
  ]
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: zonalPublicIp.id
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: subNetName
        properties: {
          addressPrefix: vnetSubnetPrefix
          natGateway: {
            id: natGateway.id
          }
        }
      }
      {
        name: z1SubNetName
        properties: {
          addressPrefix: vnetZonalSubnetPrefix
          natGateway: {
            id: zonalNatGateway.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  name: '${vnet.name}/${subNetName}'
  properties: {
    addressPrefix: vnetSubnetPrefix
    natGateway: {
      id: natGateway.id
    }
  }
}

module nonZonalVm '../_modules/vm.bicep' = {
  name: 'nonZonalVm'
  params: {
    location: location 
    subnetId: vnet.properties.subnets[0].id
    vmName: 'nonZonalVm'
  }
}

module z1Vm '../_modules/vm.bicep' = {
  name: 'z1Vm'
  params: {
    location: location 
    subnetId: vnet.properties.subnets[1].id
    vmName: 'z1Vm'
  }
}

module bastion '../_modules/bastion.bicep' = {
  name: 'bastion'
  params: {
    location: location
    name: 'bastion'
    subnetId: vnet.properties.subnets[2].id
  }
}

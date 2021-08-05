param lbName string
param location string
param lbConfig array
param frontSubnetId string
param appSubnetId string


resource slb 'Microsoft.Network/loadBalancers@2020-11-01' = {
  name: lbName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    backendAddressPools: [
      {
        name: '${lbConfig[0].name}-front'
      }
      {
        name: '${lbConfig[1].name}-app'
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontIpConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: frontSubnetId
          }
        }
      }
      {
        name: 'appIpConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: appSubnetId
          }
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'haPortFront'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, '${lbConfig[0].name}-front')
          }
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, 'frontIpConfig')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, 'lbProbe')
          }
          protocol: 'All'
          backendPort: 0
          frontendPort: 0
          idleTimeoutInMinutes: 15
        }
      }
      {
        name: 'haPortApp'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, '${lbConfig[1].name}-app')
          }
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, 'appIpConfig')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, 'lbProbe')
          }
          protocol: 'All'
          backendPort: 0
          frontendPort: 0
          idleTimeoutInMinutes: 15
        }
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Tcp'
          port: 22
          intervalInSeconds: 15
          numberOfProbes: 2
        }
        name: 'lbProbe'
      }
    ]
  }
}

output backendPools array = slb.properties.backendAddressPools
output frontFrontEndIp string = slb.properties.frontendIPConfigurations[0].properties.privateIPAddress
output appFrontEndIp string = slb.properties.frontendIPConfigurations[1].properties.privateIPAddress

param lbName string
param location string
param vnetId string


resource elb 'Microsoft.Network/loadBalancers@2020-11-01' = {
  name: lbName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    backendAddressPools: [
      {
        name: 'bePool0'
        properties: {
          loadBalancerBackendAddresses: [
            {
              name: 'beAddress1'
            }
          ]
          
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'ipConfig0'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'http'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, 'bePool0')
          }
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, 'ipConfig0')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, 'lbProbe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 15
        }
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 2
        }
        name: 'lbProbe'
      }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: '${lbName}-pip'
  location: location
  sku: {
    name:'Standard'
    tier:'Regional'
  }
  properties: {
   publicIPAllocationMethod: 'Static'
  }
}

output lbBackendId string = elb.properties.backendAddressPools[0].id

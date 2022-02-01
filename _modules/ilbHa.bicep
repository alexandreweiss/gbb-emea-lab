param lbName string
param location string
param subnetId string
param backendIp string


resource slb 'Microsoft.Network/loadBalancers@2021-05-01' = {
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
            properties: {
              loadBalancerFrontendIPConfiguration: {
                id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations',lbName,'ipConfig0')
              }
              ipAddress: backendIp
              subnet: {
                id: subnetId
              }
            }
          }
        ]
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'ipConfig0'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'HAPort'
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
          protocol: 'All'
          frontendPort: 0
          backendPort: 0
          idleTimeoutInMinutes: 15
        }
      }
    ]
    inboundNatRules: [
      {
        name: 'tcp22'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendPools', lbName, 'bePool0')
          }
          backendPort: 22
          frontendPort: 22
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, 'ipConfig0')
          }
          protocol: 'Tcp'
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

output ilbPrivateIp string = slb.properties.frontendIPConfigurations[0].properties.privateIPAddress

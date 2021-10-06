param lbName string
param location string
param subnetId string
param backendIp string


resource slb 'Microsoft.Network/loadBalancers@2020-11-01' = {
  name: lbName
  location: location
  properties: {
    backendAddressPools: [
      {
        name: 'bePool0'
        properties: {
          loadBalancerBackendAddresses: [
            {
              name: 'beAddress1'
              properties: {
                ipAddress: backendIp
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


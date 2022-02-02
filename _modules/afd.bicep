param afdName string
param backendFqdn string
param frontFqdn string

resource afd 'Microsoft.Network/frontDoors@2020-05-01' = {
  name: afdName
  location: 'global'
  properties: {
    friendlyName: '${afdName}-lab'
    backendPools: [
      {
        name: 'bePool'
        properties: {
          backends: [
            {
              address: backendFqdn
              httpPort: 80
              httpsPort: 443
              priority: 1
              weight: 100
            }
          ]
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontdoors/healthProbeSettings', afdName, 'httpProbe')
          }
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontdoors/loadBalancingSettings', afdName, 'httpLb')
          }
        }
      }
    ]
    healthProbeSettings: [
      {
        name: 'httpProbe'
        properties: {
          healthProbeMethod: 'HEAD'
          intervalInSeconds: 200
          path: '/'
          protocol: 'Http'
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: 'httpLb'
        properties: {
          successfulSamplesRequired: 3
          sampleSize: 10
        }
      }
    ]
    routingRules: [
      {
        name: 'routingRule'
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontdoors/frontendEndpoints', afdName, 'frontend')
            }
            
          ]
          acceptedProtocols: [
            'Http'
          ]
          patternsToMatch: [
            '/*'
          ]
          routeConfiguration:  {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            backendPool: {
              id: resourceId('Microsoft.Network/frontdoors/backendPools', afdName, 'bePool')
            }
            // cacheConfiguration: {
            //   // cacheDuration: 'P1Y0M0DT0H0M0S'
            //   dynamicCompression: 'Enabled'
            // }
          }
        }
      }
    ]
    frontendEndpoints: [
      {
        name: 'frontend'
        properties: {
          hostName: frontFqdn
        }
      }
      {
        name: 'defaultFe'
        properties: {
          hostName: '${afdName}.azurefd.net'
        }
      }
    ]
  }
}

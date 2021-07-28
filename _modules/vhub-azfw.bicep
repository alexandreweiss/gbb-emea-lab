param fwName string
param location string
param virtualHubId string

resource azfwWe 'Microsoft.Network/azureFirewalls@2020-11-01' = {
  name: fwName
  location: location
  properties: {
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
    sku: {
      name: 'AZFW_Hub'
      tier: 'Standard'
    }
    virtualHub: {
      id: virtualHubId
    }
    firewallPolicy: {
      id: fwPolicy.id
    }
  
  }
}

resource fwPolicy 'Microsoft.Network/firewallPolicies@2020-11-01' = {
  name: 'defaultPolicy'
  location: location
  properties: {
    threatIntelMode: 'Alert'
  }
  
}

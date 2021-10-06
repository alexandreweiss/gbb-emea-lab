param fwName string
param location string
param virtualHubId string
param fwPolicyId string

resource azfw 'Microsoft.Network/azureFirewalls@2020-11-01' = {
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
      id: fwPolicyId
    }
  
  }
}

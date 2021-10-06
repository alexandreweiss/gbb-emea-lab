param location string
param name string

resource fwPolicy 'Microsoft.Network/firewallPolicies@2020-11-01' = {
  name: name
  location: location
  properties: {
    threatIntelMode: 'Alert'
  }
  
}

output fwPolicyId string = fwPolicy.id

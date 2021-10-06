param location string
param gwSubnetId string
param name string
@secure()
param erAuthKey string
@secure()
param erPrivatePeeringCircuitId string

resource erGateway 'Microsoft.Network/virtualNetworkGateways@2021-02-01' = {
  name: name
  location: location
  properties: {
    gatewayType: 'ExpressRoute'
    sku: {
      name: 'Standard'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: gwSubnetId
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

resource erConnection 'Microsoft.Network/connections@2021-02-01' = {
  name: '${name}toLondon'
  location: location
  properties: {
    authorizationKey: erAuthKey
    virtualNetworkGateway1: {
      id: erGateway.id
      properties: {
      }
    }
    connectionType: 'ExpressRoute'
    peer: {
      id: erPrivatePeeringCircuitId
    }
  }
}

// resource erCircuit 'Microsoft.Network/expressRouteGateways/expressRouteConnections@2021-02-01' = {
//   name: '${erGateway.name}/london'
//   dependsOn: [
//     erGateway
//   ]
//   properties: {
//     authorizationKey: erAuthKey
//     expressRouteCircuitPeering: {
//       id: erPrivatePeeringCircuitId
//     }
//   }
// }

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: '${name}-pip'
  location: location
  sku: {
    name:'Basic'
    tier:'Regional'
  }
  properties: {
   publicIPAllocationMethod: 'Dynamic'
  }
}

output erGwId string = erGateway.id

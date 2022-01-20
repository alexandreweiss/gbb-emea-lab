param anmName string
param configName string
param groupId string
param isGlobal bool = true

@allowed([
  'Mesh'
  'HubAndSpoke'
])
param topology string

resource config 'Microsoft.Network/networkManagers/connectivityConfigurations@2021-02-01-preview' = {
  name: '${anmName}/${configName}'
  properties: {
    connectivityTopology: topology
    appliesToGroups: [
      {
        networkGroupId: groupId
      }
    ]
    isGlobal: isGlobal
  }
}

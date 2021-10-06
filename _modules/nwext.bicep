param vmName string
param location string

resource nwext 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${vmName}/nw-ext'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentLinux'
    typeHandlerVersion: '1.4'
  }
}

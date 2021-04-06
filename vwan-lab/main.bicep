param location string = 'francecentral'

// Virtual Wan master
resource vwan 'Microsoft.Network/virtualWans@2020-08-01' = {
  name: 'vwan-lab'
  location: location
  properties: {
  }
}

// vHub FRANCE CENTRAL
resource vhubfrc 'Microsoft.Network/virtualHubs@2020-08-01' = {
  name: 'h-frc'
  location: 'francecentral'
  properties: {
    addressPrefix: '192.168.10.0/24'
    sku: 'Standard'
    virtualWan: {
      id: vwan.id
    }
  }
}

// NVA VNET
module vnfrcnva 'vnet.bicep' = {
  name: 'vn-frc-nva-0'
  params: {
    addressPrefix: '192.168.11.0/28'
    addressSpace: '192.168.11.0/24'
    vnetName: 'vn-frc-nva-0'
    location: 'francecentral'
  }
}

// NON NVA FRA VNET 0
module vnfrcspoke00 'vnet.bicep' = {
  name: 'vn-frc-spoke-0-0'
  params: {
    addressPrefix: '192.168.12.0/28'
    addressSpace: '192.168.12.0/24'
    vnetName: 'vn-frc-spoke-0-0'
    location: 'francecentral'
  }
}

// NON NVA FAR VNET 1
module vnfrcspoke01 'vnet.bicep' = {
  name: 'vn-frc-spoke-0-1'
  params: {
    addressPrefix: '192.168.13.0/28'
    addressSpace: '192.168.13.0/24'
    vnetName: 'vn-frc-spoke-0-1'
    location: 'francecentral'
  }
}

// NON NVA VNET 0
module vnfrcspoke0 'vnet.bicep' = {
  name: 'vn-frc-spoke-0'
  params: {
    addressPrefix: '192.168.14.0/28'
    addressSpace: '192.168.14.0/24'
    vnetName: 'vn-frc-spoke-0'
    location: 'francecentral'
  }
}

// PEERINGS //
//
resource nva0Spoke00 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnfrcnva.name}/nva2spoke0'
  parent: vnfrcnva
  properties: {
    remoteVirtualNetwork: {
      id: vnfrcspoke00.outputs.vnetId
    }
  }
}

resource Spoke00Nva0 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnfrcspoke00.name}/spoke02Nva'
  parent: vnfrcspoke00
  properties: {
    remoteVirtualNetwork: {
      id: vnfrcnva.outputs.vnetId
    }
  }
}

resource nva0Spoke01 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnfrcnva.name}/nva2spoke1'
  parent: vnfrcnva
  properties: {
    remoteVirtualNetwork: {
      id: vnfrcspoke01.outputs.vnetId
    }
  }
}

resource Spoke01Nva0 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnfrcspoke01.name}/spoke12Nva'
  parent: vnfrcspoke01
  properties: {
    remoteVirtualNetwork: {
      id: vnfrcnva.outputs.vnetId
    }
  }
}

// END OF PEERINGS

// VWAN Virtual Network Connection for NVA VNET and SPOKE VNET
resource vnfrcnvaConnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: vnfrcnva.name
  parent: vhubfrc
  properties: {
    remoteVirtualNetwork: {
      id: vnfrcnva.outputs.vnetId
    }
  }
}

resource vnfrcspoke0Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: vnfrcspoke0.name
  parent: vhubfrc
  properties: {
    remoteVirtualNetwork: {
      id: vnfrcspoke0.outputs.vnetId
    }
  }
}

// VWAN UKS vHub
resource vhubuks 'Microsoft.Network/virtualHubs@2020-08-01' = {
  name: 'h-uks'
  location: 'uksouth'
  properties: {
    addressPrefix: '192.168.20.0/24'
    sku: 'Standard'
    virtualWan: {
      id: vwan.id
    }
  }
}

// VMs

module vmNvaFrc 'vm.bicep' = {
  name: 'vm-nva-frc'
  params: {
    location: 'francecentral'
    subnetId: vnfrcnva.outputs.subnetId
    vmName: 'vm-nva-frc'
  }
}

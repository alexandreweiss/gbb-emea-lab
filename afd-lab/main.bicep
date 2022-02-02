param location string = 'westeurope'

/* 
Update frontFqdn variable with your own domain which will create a specific listener on the AFD instance.
You must create a CNAME in your DNS domain tool (aka. afd-fe.ananableu.fr here) that points to afd-fe.azurefd.net
*/
param frontFqdn string = 'afd-fe.ananableu.fr'

// Update the afdName variable to whatever fit : it is in your own subscription
param afdName string = 'afd-ananableu-0'

// Replace with your source IP for remote connection
param mySourceIp string = '81.49.39.190'

// Change the scope to be able to create the resource group before resources
// then we specify scope at resourceGroup level for all others resources
targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'afd-lab-2'
  location: location
}

var random = uniqueString(rg.id)

module afd '../_modules/afd.bicep' = {
  scope: rg
  name: afdName
  params: {
    afdName: afdName
    backendFqdn: nginx.outputs.nicPublicFqdn
    frontFqdn: frontFqdn
  }
}

module vnet '../_modules/vnet.bicep' = {
  scope: rg
  name: 'afdVnet'
  params: {
    addressPrefix: '10.0.0.0/24'
    addressSpace: '10.0.0.0/16'
    location: location
    vnetName: 'afdVnet'
  }
}

module nginx '../_modules/vm.bicep' = {
  scope: rg
  name: 'nginx${random}'
  params: {
    location: location
    subnetId: vnet.outputs.subnetId
    vmName: 'nginx${random}'
    createPublicIpNsg: true
    mySourceIp: mySourceIp
    cloudInitValue: 'I2Nsb3VkLWNvbmZpZwpwYWNrYWdlczoKICAtIG5naW54CndyaXRlX2ZpbGVzOgogIC0gb3duZXI6IHJvb3Q6cm9vdAogICAgYXBwZW5kOiAwCiAgICBwYXRoOiAvZXRjL25naW54L3NpdGVzLWF2YWlsYWJsZS9hZmQuY29uZgogICAgY29udGVudDogfAogICAgICBzZXJ2ZXIgewogICAgICAgICAgbGlzdGVuIDgwIGRlZmF1bHRfc2VydmVyOwogICAgICAgICAgbGlzdGVuIFs6Ol06ODAgZGVmYXVsdF9zZXJ2ZXI7CiAgICAgICAgICByb290IC92YXIvd3d3L2h0bWw7CiAgICAgICAgICBpbmRleCBpbmRleC5odG1sIGluZGV4Lmh0bSBpbmRleC5uZ2lueC1kZWJpYW4uaHRtbDsKICAgICAgICAgIHNlcnZlcl9uYW1lIF87CiAgICAgICAgICBsb2NhdGlvbiAvIHsKICAgICAgICAgICAgICAgICAgdHJ5X2ZpbGVzICR1cmkgJHVyaS8gPTQwNDsKICAgICAgICAgIH0KICAgICAgICAgIGxvY2F0aW9uIC9uZ2lueF9zdGF0dXMgewogICAgICAgICAgICBzdHViX3N0YXR1czsKICAgICAgICAgIH0KcnVuY21kOgogIC0gbG4gLXMgL2V0Yy9uZ2lueC9zaXRlcy1hdmFpbGFibGUvYWZkLmNvbmYgL2V0Yy9uZ2lueC9zaXRlcy1lbmFibGVkL2FmZC5jb25mCiAgLSBybSAtcmYgL2V0Yy9uZ2lueC9zaXRlcy1lbmFibGVkL2RlZmF1bHQKICAtIHN1ZG8gc3lzdGVtY3RsIGVuYWJsZSAtLW5vdyBuZ2lueAogIC0gc3VkbyBzeXN0ZW1jdGwgcmVsb2FkIG5naW54'
    enableCloudInit: true
  }
}

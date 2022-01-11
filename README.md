
# gbb-emea-lab

Place to host all GGB EMEA Labs artifacts

# avs-lab

![AVS Lab schema](/images/onprem-avs-rs.png)

## Intent

This lab is to demonstrate usage of the Azure Route Server to propagate route learnt from an NVA (Cisco CSR 1000v with branch site connected via IPSec) to another remote branch connected via an Express Route Circuit

Onprem site is simulated by an Azure VPN Gateway and a VM all in Azure.

## Description

### Requirements

- You have to create a .json parameter file with the two variables below. This file should be kept outside of your repo as i'm doing to keep you secrets secure.

Also you can override the default parameter of variables described earlier by adding them here with the expected value :

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "adminPassword": {
            "value": "** admin password of CSR **"
        },
        "vpnPreShared": {
            "value": "** VPN Pre shared key value **"
        }
    }
}
```

### Deployment

You need to run the following after :

- installing the latest version of az cli,
- created the resource group where you want to deploy

```
az deployment group create -n Deploy -g avs-lab --template-file main.bicep --parameters ..\..\..\secret\avs-lab.param.json <--- you have to update path to your param file.
```

Once the deployment is done, you will have to configure :

- Peering of your security equipment or the CSR with the router server using the [documentation here](https://docs.microsoft.com/azure/route-server/quickstart-configure-route-server-portal#set-up-peering-with-nva)

- Branch to branch to enabled to allow route propagation between the security equipment, the route server and the Express Gateway. This will enable end to end routing from on-premises site to AVS based VMs

- Configuration of T0/T1 and NVA on AVS is out of the scope of this lab.


### Variables

- location : Azure region where to deploy this architecture

- deployCsr : true/false. This is used if you want to deploy a test CSR in the hub to use it as a VPN gateway collecting IPSEC from remote location. It comes with no config. A sample is in the config directory that enables IPSEC + BGP

- simulateOnPremLocation : true/false. if you want to deploy a vnet with a VPN gateway and a test VM to be connected to the Cisco CSR 1000v or any routing equipment that terminates VPN in the hub

- deployEr : true/false. If  you want to deploy or not the Express Route Gateway.

### HUB Virtual network in Azure

Hub virtual network is devided into multiple subnets :

- GatewaySubnet : host the Express Route gateway that is connected to AVS ER circuit

- default : the hubVm is deployed in that subnet just for connectivity test pursposes from the hub

- inside : it has the internal routing equipment NIC (in this example, the CSR 1000v inside NIC)

- outside : it has the external routing equipment NIC (in this example, the CSR 1000v outside NIC). This NIC also has a public IP attached to receive remote branches IPSEC tunnels

- RouteServerSubnet : this is the subnet reserved to Azure Route Server that must be a /27

### ONPREM virtual network (to simulate onPrem location)

A virtual network called "onprem" is deployed if selected with :

- GAtewaySUbnet : host the VPN Gateway connecting back to the routing equipment into the hub

- default : the onpremVm is deployed in that subnet just for connectivity test pursposes from the onprem simulated location

# vwan-lab

![vWan Lab schema](/images/vwan-lab-schema-1.png)

## Intent

This Lab is to demonstrate the publically documented scenario of vWan with an NVA on a spoke along with the BICEP langage to deploy

***This lab is in constent evolution adding component for every test so it is possible that it is not deploying successfully at first time and that you may have to redeploy multiple times, tweeking the templates but the base is there ;)***

## Parameters

Using the below parameter, you can choose to add component :

### param deployEr bool = false 
### param deployErWe bool = false 

Set to true if you want to deploy ER Gateway and circuit connectivity (you must already have an ER Circuit available with an authorization key)

We = WestEurope

### param deployFrcVhub2 bool = false

### param deployVmNxExt bool = false

Deploy VM Network extension in VMs

### param deployFrc2Vhub bool = false

Deploy a second vhub in France

### param deployFrcVpn bool = false

Set to true if you want to deploy a VPN Gateway in the first Frc vHub

### param deployFrcEr2 bool = false

Set to true if you want to deploy an ER Gateway in the second Frc vHub

### param deployUsVhub bool = true
Set to true if you want to deploy a vHub in US

### param deployUsEr bool = false

Set to true if you want to deploy an ER Gateway in the US vHub

### param deployUsVpn bool = false

Set to true if you want to deploy a VPN Gateway in the US vHub

### param deployWeSecuredHub bool = false

Set to true if you want to deploy an AzFw and a secured vHub in West Europe to cover secured hub scenario

### param deployWeSecuredHub bool = false

Set to true to make WE vHub a secured hub

### param deployWeVpn bool = false

Set to true if you want to deploy a VPN Gateway in the WE vHub

### param doFrcSecuredHub bool = true

Set to true to make FRC a secured hub

### param doFrc2SecuredHub bool = false

Set to true to make FRC2 a secured hub

## Requirement

- Personnalize your public IP to be able to connect to NVA VM from Internet (it gets applied to the NVA VM NSG)
It seats into the nic.bicep file :
param mySourceIp string =

- The deployEr switch help overcome waiting 30 min ER GW deployment every time you run deploy the bicep. Set it to true only the first time (still need to troubleshoot the issue as nothing is changed on the ER GW accross deployments)

- The rtVnet of the FRC hub is referencing a 192.168.2.0/24 that represents my onprem site so you would no need it.

- You have to create a .json parameter file with the two variable if you intent to connect an ER Circuit using an authorization key. This file should be kept outside of your repo as i'm doing to keep you secrets secure :

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "erAuthKey": {
            "value": "**Authorization key value**"
        },
        "erCircuitId": {
            "value": "/subscriptions/**sub Id **/resourceGroups/**ER Circuit ResourceGroup**/providers/Microsoft.Network/expressRouteCircuits/**ER Circuit Name**/peerings/AzurePrivatePeering"
        }
    }
}
```

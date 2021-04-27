
# gbb-emea-lab

Place to host all GGB EMEA Labs artifacts

# avs-lab

## Intent

This lab is to demonstrate usage of the Azure Route Server to propagate route learnt from an NVA (Cisco CSR 1000v with branch site connected via IPSec) to another remote branch connected via an Express Route Circuit

Onprem site is simulated by an Azure VPN Gateway and a VM all in Azure.

## Requirements

- You have to create a .json parameter file with the two variables below. This file should be kept outside of your repo as i'm doing to keep you secrets secure :

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

# vwan-lab

## Intent

This Lab is to demonstrate the publically documented scenario of vWan with an NVA on a spoke along with the BICEP langage to deploy

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

# Azure Route Server (ARS) Lab

## Context


### 0-main
This lab is to demonstrate that two NVAs (spoke1Vm and spoke2Vm) cannot share their routes using ARS as a route reflector.
ARS is just here to install routes learnt from spoke1Vm into hub vnet.
Same with spoke2Vm.

### 1-main
This lab is to demonstrate the route predescence between UDR, ARS, System routes etc ...
It deploys ARS in a hub vnet along with a VM running Quagga peered with ARS.
The spoke1 is peered to the hub with a test VM

### 2-main
This lab deploys in the specific order
- ARS with B2B enabled
- VPN + ER GW
- Connect an ER circuit

This is to reproduce an unexpected behavior where, if ARS is deloyed first, ER route are not propagated to VPN GW.
It is seen via the BGP peers view in the VPN Gateway as "route received: 0"


## Deployment

`az group create -g ars-lab -l 'westeurope'`

`az deployment group create -n deploy-ars -g ars-lab --template-file` **x**`-main.bicep`

## Diagram

![Lab schema](/images/ars-lab.png)
# Azure Route Server (ARS) Lab

## Context

This lab is to demonstrate that two NVAs (spoke1Vm and spoke2Vm) cannot share their routes using ARS as a route reflector.
ARS is just here to install routes learnt from spoke1Vm into hub vnet.
Same with spoke2Vm.

## Deployment

`az group create -g ars-lab -l 'westeurope'`

`az deployment group create -n deploy-ars -g ars-lab --template-file main.bicep`

## Diagram

![Lab schema](/images/ars-lab-schema.png)
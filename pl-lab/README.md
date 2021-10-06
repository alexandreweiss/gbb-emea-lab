# Private Link Lab

## Context

This lab is to demonstrate the non transitive nature of vnet peering also with private endpoint.
Placing a PE of a storage account in a spoke (pl vnet) will not make it available from another spoke (spoke vnet) peered to the same hub (hub vnet)

(We are injecting the same storage account two times which is not recommanded in normal situation as it would lead the DNS to resolve 2 different IPs for the same storage account)

## Deployment

`az group create -g pl-lab -l 'westeurope'`

`az deployment group create -n deploy-pl -g pl-lab --template-file main.bicep`

## Diagram

![Lab schema](/images/pl-lab-schema.png)
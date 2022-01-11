# Notes from the field

This readme is a notepad for reallife tested scenarios

## Using an Express Route local to connect to resources worlwide

### Use case

I can connect to an Azure resource in a vnet located in a different geography via my ER circuit local SKU and ER gateway deployed in my local geography.

### How to

You can use the script located in the er-lab folder to deploy 2 vnets in different regions.

The idea is 
- to use 2 regions in two different geographies
- to connect an ER circuit to one of the region
- enable peering between the two vnet

"location" and "drLocation" variable can be used to deploy each vnet in a different region.

"enableDrPeering" set to true if you want to use vnet peering between the two location




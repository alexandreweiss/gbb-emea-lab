[< back](../README.md)

# seg-lab


## Intent

This Lab is to demonstrate 3 tier application with

***This lab is in constent evolution adding component for every test so it is possible that it is not deploying successfully at first time and that you may have to redeploy multiple times, tweeking the templates but the base is there ;)***

## Deployment

### Create a resource group 

az group create -n MyRg -l myLocation

### Deploy

az deployment group create --resource-group myRg --template-file main.bicep


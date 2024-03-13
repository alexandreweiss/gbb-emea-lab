# lbNva-lab

![Lab schema](/images/lbnva-lab-schema.png)

## Deployment command line
az group create -n lbnva-lab -l francecentral

az deployment group create --name lbNva-lab --resource-group lbnva-lab --template-file ./main.bicep --location francecentral
[< back](../README.md)

# anm-lab

## Intent

This lab helps to gain insights from an ANM deployment.
It creates a bunch of vNets parts of 2 different groups.
Groups are set to dynamic membership based on the 'group' tag being A or B

## Deployment

This bicep file uses a subscription deployment model so it includes already the RG name in it.
Just run the below command from the anm-lab folder to deploy :

`az deployment sub create -n anm-lab -l eastus --template-file .\main.bicep`
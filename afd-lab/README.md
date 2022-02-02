[< back](../README.md)

# afd-lab

## Intent

This lab is to demonstrate a basic Azure Front Door environment take its origin on an NGINX VM with the /nginx_status page
Finally, just point to http://frontFqdn/nginx_status to see the result

## Requirements

You must have your own domain name. Here, i'm using one that is 'ananableu.fr' and you will be required to validate the domain in AFD by creating a CNAME pointing back to your AFDNAME.azurefd.net

## Parameters

### param frontFqdn string
is the FQDN your AFD will answer to. It is your own domain

### param afdName string
is the name of your AFD deployment in your subscription

### param mySourceIp string
is the source IP your are connecting from

## Schema

[AFD Schema](../images/afd-lab-schema.png)
variable "vnet_name" {
   description =   "Name of the vNet to be created"
}

variable "address_space" {
   description =   "Address space of the vNet of the form x.x.x.x/x"
}

variable "resource_group_name" {
   description =   "Name of the resource group to deploy the vNet to"
}

variable "location" { 
    description = "Physical location where resource are deployed"
    default = "francecentral"
}

variable "short_location" {
    description = "Friendly location name used in components naming"
    default = "frc"
}

variable "subnet_names" {   
   type = list(string)
   description = "Names of the subnet to create"
 }

variable "subnet_prefixes" {   
   type = list(string)
   description = "The address prefix to use for the subnet"
 }

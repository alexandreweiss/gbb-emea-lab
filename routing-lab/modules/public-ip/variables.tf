variable "nb_public_ips" {
    type = number
    description = "Quantity of public IP to create"
    default = 1
 }

 variable "public_ip_name" {
    type = string
    description = "Name of public IP to create"
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

variable "public_ip_allocation_method" {
    description = "How public IP gets allocated. Can be either Dynamic or Static"
    default =   "Dynamic"
}
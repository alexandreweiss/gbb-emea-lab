variable "tags" {
  type        = map
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    source = "gbb-emea-lab"
  }
}

variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created"
  default     = "terraform-compute"
}

variable "location" {
  description = "The location/region where the resource is created. Changing this forces a new resource to be created."
}

variable "short_location" {
    description = "Friendly location name used in components naming"
    default = "frc"
}

variable "route_table_name" {
    type = string
    description = "Names of route table"
}

variable "route_name" {
    type = list(string)
    description = "Names of routes"
}

variable "route_prefix" {
    type = list(string)
    description = "Prefix of routes"
}

variable "next_hop_type" {
    type = list(string)
    description = "Type of routes"
}

variable "next_hop_in_ip_address" {
    type = list(string)
    description = "Next hop for routes"
}
 
variable "subnet_ids" {   
   type = list(string)
   description = "Id of the subnet to associate to rtable"
   default = []
 }
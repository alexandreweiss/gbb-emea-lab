variable "location" { 
    description = "Physical location where resource are deployed"
    default = "francecentral"
}

variable "short_location" {
    description = "Friendly location name used in components naming"
    default = "frc"
}

variable "resource_group_name" {
   description =   "Name of the resource group to deploy the vNet to"
}

variable "rules" {
  description = "Security rules for the network security group using this format name = [priority, direction, access, protocol, source_port_range, destination_port_range, source_address_prefix, destination_address_prefix, description]"
  type        = list(any)
  default     = []
}

# source address prefix to be applied to all rules
variable "source_address_prefix" {
  type    = list(string)
  default = ["*"]

  # Example ["10.0.3.0/24"] or ["VirtualNetwork"]
}

# Destination address prefix to be applied to all rules
variable "destination_address_prefix" {
  type    = list(string)
  default = ["*"]

  # Example ["10.0.3.0/32","10.0.3.128/32"] or ["VirtualNetwork"] 
}

variable "security_group_name" {
    description = "Name of the NSG"
}

variable "tags" {
  type        = map
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    source = "gbb-emea-lab"
  }
}

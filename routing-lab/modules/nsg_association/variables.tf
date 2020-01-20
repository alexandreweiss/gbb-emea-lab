variable "subnet_ids" {
    type = list(string)
    description = "The subnet id to associate with the NSG."
}

variable "network_security_group_ids" { 
    type = list(string)
    description = "The subnet id to associate with the NSG."
}
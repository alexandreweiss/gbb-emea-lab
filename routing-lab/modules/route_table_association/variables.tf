variable "tags" {
  type        = map
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    source = "gbb-emea-lab"
  }
}

variable "subnet_ids" {   
   type = list(string)
   description = "Id of the subnet to associate to rtable"
   default = []
}
 
variable "route_table_ids" {   
   type = list(string)
   description = "Id of the route table to associate with subnet"
   default = []
 }
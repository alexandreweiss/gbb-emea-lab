variable "vm_hostname" { 
    type        = string
    description = "name of the extension to install"
}

variable "extension_name" { 
    type        = string
    description = "name of the extension to install"
}

variable "tags" {
  type        = map
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    source = "gbb-emea-lab"
  }
}

variable "resource_group_name" {
   description =   "Name of the resource group to deploy the vNet to"
}

variable "location" { 
    description = "Physical location where resource are deployed"
    default = "francecentral"
}

variable "trigger" {
    description = "A trigger to get the extension deployed every time"
    default = "rerunExtension"
}

variable "settings" {
  type = string
  default = <<SETTINGS
    {
      "commandToExecute": "sudo ./install-router.sh",
      "fileUris": [
        "https://raw.githubusercontent.com/alexandreweiss/gbb-emea-lab/develop/routing-lab/config/router/install-router.sh",
        "https://raw.githubusercontent.com/alexandreweiss/gbb-emea-lab/develop/routing-lab/config/router/ans-router.yml",
        "https://raw.githubusercontent.com/alexandreweiss/gbb-emea-lab/develop/routing-lab/config/router/ans-inventory.yml"
      ]
    }
  SETTINGS
}

variable "nb_instances" {
  description = "Specify the number of extension instances. Should match number of VMs"
  default     = "1"
}
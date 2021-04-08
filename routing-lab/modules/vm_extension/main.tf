resource "azurerm_virtual_machine_extension" "cse" {
  count                = length(var.nb_instances)
  name                 = var.extension_name
  location             = var.location
  resource_group_name  = var.resource_group_name
  virtual_machine_name = "${var.vm_hostname}${count.index}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  settings             = var.settings
  tags = var.tags
}
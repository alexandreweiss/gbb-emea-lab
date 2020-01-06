resource "azurerm_virtual_machine_extension" "cse" {
  name                 = var.extension_name
  location             = var.location
  resource_group_name  = var.resource_group_name
  virtual_machine_name = var.vm_hostname
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  settings             = <<SETTINGS
    {
      ${var.settings}
    }
  SETTINGS
  tags = var.tags
}
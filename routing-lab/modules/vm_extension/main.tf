resource "azurerm_virtual_machine_extension" "cse" {
  name                 = var.extension_name
  location             = var.location
  resource_group_name  = var.resource_group_name
  virtual_machine_name = var.virtual_machine_name
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "${var.command_to_execute}"
        "fileUris": "${var.file_uris}"
    }
SETTINGS
  tags = var.tags
}
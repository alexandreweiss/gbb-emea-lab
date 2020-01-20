output "subnet_ids" {
    description = "list all subnets of vnet as object"
    value = "${azurerm_subnet.subnet.*.id}"
}

output "name" {
    description = "Name of the vNet"
    value = "${azurerm_virtual_network.vnet.name}"
}

output "id" {
    description = "Id of the vNet"
    value = "${azurerm_virtual_network.vnet.id}"
}
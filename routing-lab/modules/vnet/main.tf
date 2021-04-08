resource "azurerm_virtual_network" "vnet" {
    name                = var.vnet_name
    location            = var.location
    address_space       = ["${var.address_space}"]
    resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "subnet" {
    count                       = length(var.subnet_names)
    name                        = var.subnet_names[count.index]
    virtual_network_name        = azurerm_virtual_network.vnet.name
    resource_group_name         = var.resource_group_name
    address_prefix              = var.subnet_prefixes[count.index]
    network_security_group_id   = length(var.network_security_group_ids) > 0 ? var.network_security_group_ids[count.index] : ""
    route_table_id              = length(var.route_table_ids) > 0 ? var.route_table_ids[count.index] : ""
}
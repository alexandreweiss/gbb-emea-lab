resource "azurerm_subnet_route_table_association" "rtable-association" {
    count               = length(var.subnet_ids)
    subnet_id           = var.subnet_ids[count.index]
    route_table_id      = var.route_table_ids[count.index]
}
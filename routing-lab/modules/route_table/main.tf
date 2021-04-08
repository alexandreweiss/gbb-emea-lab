resource "azurerm_route_table" "rtable" {
  name                          = var.route_table_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = false

  tags = var.tags
}

resource "azurerm_route" "route" {
    count                   = length(var.route_name)
    route_table_name        = var.route_table_name
    name                    = var.route_name[count.index]
    resource_group_name     = var.resource_group_name
    address_prefix          = var.route_prefix[count.index]
    next_hop_type           = var.next_hop_type[count.index]
    next_hop_in_ip_address  = var.next_hop_in_ip_address[count.index]
}

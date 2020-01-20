resource "azurerm_network_security_group" "nsg" {
  name                = var.security_group_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "rules" {
  count                       = length(var.rules)
  name                        = lookup(var.rules[count.index], "name", "default_rule_name")
  priority                    = lookup(var.rules[count.index], "priority")
  direction                   = lookup(var.rules[count.index], "direction", "Any")
  access                      = lookup(var.rules[count.index], "access", "Allow")
  protocol                    = lookup(var.rules[count.index], "protocol", "*")
  source_port_ranges          = split(",", replace(lookup(var.rules[count.index], "source_port_range", "*"), "*", "0-65535"))
  destination_port_ranges     = split(",", replace(lookup(var.rules[count.index], "destination_port_range", "*"), "*", "0-65535"))
  source_address_prefix       = lookup(var.rules[count.index], "source_address_prefix", "*")
  destination_address_prefix  = lookup(var.rules[count.index], "destination_address_prefix", "*")
  description                 = lookup(var.rules[count.index], "description", "Security rule for ${lookup(var.rules[count.index], "name", "default_rule_name")}")
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
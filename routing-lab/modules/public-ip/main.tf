resource "azurerm_public_ip" "public-ip" {
    count               = var.nb_public_ips
    name                = "${var.public_ip_name}-${var.short_location}-pip${count.index}"
    location            = var.location
    resource_group_name = var.resource_group_name
    domain_name_label   = "${var.public_ip_name}-${var.short_location}-pip${count.index}"
    allocation_method   = var.public_ip_allocation_method
    sku                 = var.sku
}

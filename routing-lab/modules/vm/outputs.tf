output "ip_address" {
   value = "${azurerm_network_interface.nic.ip_configuration[0].private_ip_address}"
}
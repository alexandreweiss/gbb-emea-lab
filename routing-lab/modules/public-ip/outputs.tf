output "id" {
   value = "${azurerm_public_ip.public-ip.*.id}"
}
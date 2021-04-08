module "os" {
  source       = "./os"
  vm_os_simple = "${var.vm_os_simple}"
}

resource "azurerm_virtual_machine" "vm-linux-multinic" {
  depends_on                    = [azurerm_network_interface.nic-core,azurerm_network_interface.nic-edge]
  count                         = !contains(list("${var.vm_os_simple}","${var.vm_os_offer}"), "Windows") && var.is_windows_image != "true" && var.data_disk == "false" ? var.nb_instances : 0
  name                          = "${var.vm_hostname}${count.index}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  vm_size                       = var.vm_size
  network_interface_ids         = [azurerm_network_interface.nic-core.id,azurerm_network_interface.nic-edge.id]
  primary_network_interface_id  = azurerm_network_interface.nic-core.id
  delete_os_disk_on_termination = var.delete_os_disk_on_termination

  storage_image_reference {
    id        = var.vm_os_id
    publisher = var.vm_os_id == "" ? coalesce(var.vm_os_publisher, module.os.calculated_value_os_publisher) : ""
    offer     = var.vm_os_id == "" ? coalesce(var.vm_os_offer, module.os.calculated_value_os_offer) : ""
    sku       = var.vm_os_id == "" ? coalesce(var.vm_os_sku, module.os.calculated_value_os_sku) : ""
    version   = var.vm_os_id == "" ? var.vm_os_version : ""
  }

  storage_os_disk {
    name              = "osdisk-${var.vm_hostname}-${count.index}"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = var.storage_account_type
  }

  os_profile {
    computer_name  = var.vm_hostname
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data    = var.custom_data
  }

  os_profile_linux_config {
    disable_password_authentication = true

  ssh_keys {
    path     = "/home/${var.admin_username}/.ssh/authorized_keys"
    key_data = "file(var.ssh_key)"
    }
  }

  tags = var.tags
}

resource "azurerm_network_interface" "nic-core" {
  name                          = "nic-${var.vm_hostname}-core"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  enable_accelerated_networking = var.enable_accelerated_networking

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = var.core_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = module.nic-core-pip.id[0]
  }

  tags = var.tags
}

resource "azurerm_network_interface" "nic-edge" {
  name                          = "nic-${var.vm_hostname}-edge"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  enable_accelerated_networking = var.enable_accelerated_networking

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = var.edge_subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

module "nic-core-pip" {
  source = "../public-ip/"

  location            = var.location
  resource_group_name = var.resource_group_name
  short_location      = var.short_location
  public_ip_name      = var.public_ip_name
}
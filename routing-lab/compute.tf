# Create VMs in s1
# Test VM
module "s1-vm" {
    source              = "./modules/vm"
    location            = var.location
    vm_os_simple        = "UbuntuServer"
    vm_hostname         = "s1-vm"
    public_ip_name      = "bgp-s1-vm"
    subnet_id           = "${module.vnet-s1-core.subnet_ids[0]}"
    resource_group_name = azurerm_resource_group.routing-lab-rg.name
}

# s1 edge router
module "s1-edge" {
    source              = "./modules/vm"
    location            = var.location
    vm_os_simple        = "UbuntuServer"
    vm_hostname         = "s1-edge"
    public_ip_name      = "bgp-s1-edge"
    subnet_id           = "${module.vnet-s1-edge.subnet_ids[0]}"
    resource_group_name = azurerm_resource_group.routing-lab-rg.name
}

module "s1-edge-extenstion" {
    source              = "./modules/vm_extension"

    location            = var.location
    vm_hostname         = "s1-edge"
    extension_name      = "InstallQuagga"
    resource_group_name = azurerm_resource_group.routing-lab-rg.name
    settings            = <<SETTINGS
        {
        "commandToExecute": "sudo ./install-router.sh s1-edge",
        "fileUris": [
            "https://raw.githubusercontent.com/alexandreweiss/gbb-emea-lab/develop/routing-lab/config/router/install-router.sh",
            "https://raw.githubusercontent.com/alexandreweiss/gbb-emea-lab/develop/routing-lab/config/router/ans-router.yml",
            "https://raw.githubusercontent.com/alexandreweiss/gbb-emea-lab/develop/routing-lab/config/router/ans-inventory.yml"
        ]
        }
    SETTINGS
}

# Create VMs in s2
# Test VM
module "s2-vm" {
    source              = "./modules/vm"
    location            = var.location
    vm_os_simple        = "UbuntuServer"
    vm_hostname         = "s2-vm"
    public_ip_name      = "bgp-s2-vm"
    subnet_id           = "${module.vnet-s2-core.subnet_ids[0]}"
    resource_group_name = azurerm_resource_group.routing-lab-rg.name
}

# s2 edge router
module "s2-edge" {
    source              = "./modules/vm"
    location            = var.location
    vm_os_simple        = "UbuntuServer"
    vm_hostname         = "s2-edge"
    public_ip_name      = "bgp-s2-edge"
    subnet_id           = "${module.vnet-s2-edge.subnet_ids[0]}"
    resource_group_name = azurerm_resource_group.routing-lab-rg.name
}

# Create s1 routers in Interco
# First router
module "s1-interco-1" {
    source              = "./modules/vm"
    location            = var.location
    vm_os_simple        = "UbuntuServer"
    vm_hostname         = "s1-interco-1"
    public_ip_name      = "bgp-s1-interco-1"
    subnet_id           = "${module.vnet-interco.subnet_ids[0]}"
    resource_group_name = azurerm_resource_group.routing-lab-rg.name
}

# Second router
module "s1-interco-2" {
    source              = "./modules/vm"
    location            = var.location
    vm_os_simple        = "UbuntuServer"
    vm_hostname         = "s1-interco-2"
    public_ip_name      = "bgp-s1-interco-2"
    subnet_id           = "${module.vnet-interco.subnet_ids[0]}"
    resource_group_name = azurerm_resource_group.routing-lab-rg.name
}

# Create s2 routers in Interco
# First router
module "s2-interco-1" {
    source              = "./modules/vm"
    location            = var.location
    vm_os_simple        = "UbuntuServer"
    vm_hostname         = "s2-interco-1"
    public_ip_name      = "bgp-s2-interco-1"
    subnet_id           = "${module.vnet-interco.subnet_ids[0]}"
    resource_group_name = azurerm_resource_group.routing-lab-rg.name
}

# Second router
module "s2-interco-2" {
    source              = "./modules/vm"
    location            = var.location
    vm_os_simple        = "UbuntuServer"
    vm_hostname         = "s2-interco-2"
    public_ip_name      = "bgp-s2-interco-2"
    subnet_id           = "${module.vnet-interco.subnet_ids[0]}"
    resource_group_name = azurerm_resource_group.routing-lab-rg.name
}
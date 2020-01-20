# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "routing-lab-rg" {
    name     = "${var.resource_group_name}-${var.short_location}"
    location = var.location
}

## START of site 1
# Core - Create virtual network
module "vnet-s1-core" {
   source = "./modules/vnet"

   vnet_name            = "routing-s1-core-vn"
   address_space        = "10.0.0.0/24"
   resource_group_name  = azurerm_resource_group.routing-lab-rg.name
   subnet_names         = ["default"]
   subnet_prefixes      = ["10.0.0.0/27"]
   network_security_group_ids = ["${module.nsg-all-subnets.id}"]
   route_table_ids      = ["${module.s1-route-table.id}"]
   location             = var.location
}

# Route Table to s1 edge

module "s1-route-table" {
   source = "./modules/route_table/"

   route_table_name        = "s1-core-rt"
   route_name              = ["toEdgeRouter"]
   route_prefix            = ["192.168.0.0/24"]
   next_hop_type           = ["VirtualAppliance"]
   next_hop_in_ip_address  = ["${module.s1-edge.ip_address}"]
   subnet_ids              = ["${module.vnet-s1-core.subnet_ids[0]}"]   
   location                = var.location
   resource_group_name     = azurerm_resource_group.routing-lab-rg.name
}

# Edge - Create virtual network
module "vnet-s1-edge" {
   source               = "./modules/vnet"

   vnet_name            = "routing-s1-edge-vn"
   address_space        = "10.0.1.0/24"
   resource_group_name  = azurerm_resource_group.routing-lab-rg.name
   subnet_names         = ["default"]
   subnet_prefixes      = ["10.0.1.0/27"]
   network_security_group_ids = ["${module.nsg-all-subnets.id}"]
   location             = var.location
}

# Peering s1-core with s1-edge

resource "azurerm_virtual_network_peering" "s1-core-to-edge" {
   name                       = "s1CoreTos1Edge"
   resource_group_name        = azurerm_resource_group.routing-lab-rg.name
   virtual_network_name       = module.vnet-s1-core.name
   remote_virtual_network_id  = module.vnet-s1-edge.id
}

resource "azurerm_virtual_network_peering" "s1-edge-to-core" {
   name                       = "s1EdgeTos1Core"
   resource_group_name        = azurerm_resource_group.routing-lab-rg.name
   virtual_network_name       = module.vnet-s1-edge.name
   remote_virtual_network_id  = module.vnet-s1-core.id
}

# Interco 1 - Create virtual network
module "vnet-interco" {
   source               = "./modules/vnet"

   vnet_name            = "routing-interco-vn"
   address_space        = "172.16.0.0/24"
   resource_group_name  = azurerm_resource_group.routing-lab-rg.name
   subnet_names         = ["default"]
   subnet_prefixes      = ["172.16.0.0/27"]
   network_security_group_ids = ["${module.nsg-all-subnets.id}"]
   location             = var.location
}

# Peering s1-edge with interco

resource "azurerm_virtual_network_peering" "s1-edge-to-interco" {
   name                       = "s1EdgeToInterco"
   resource_group_name        = azurerm_resource_group.routing-lab-rg.name
   virtual_network_name       = module.vnet-s1-edge.name
   remote_virtual_network_id  = module.vnet-interco.id
}

resource "azurerm_virtual_network_peering" "interco-to-s1-edge" {
   name                       = "intercoTos1Edge"
   resource_group_name        = azurerm_resource_group.routing-lab-rg.name
   virtual_network_name       = module.vnet-interco.name
   remote_virtual_network_id  = module.vnet-s1-edge.id
}

## END of site 1

## START of site 2
# Core - Create virtual network
module "vnet-s2-core" {
   source               = "./modules/vnet"

vnet_name               = "routing-s2-core-vn"
   address_space        = "192.168.0.0/24"
   resource_group_name  = azurerm_resource_group.routing-lab-rg.name
   subnet_names         = ["default"]
   subnet_prefixes      = ["192.168.0.0/27"]
   network_security_group_ids = ["${module.nsg-all-subnets.id}"]
   route_table_ids      = ["${module.s2-route-table.id}"]
   location             = var.location
}

# Route Table to s2 edge

module "s2-route-table" {
   source                  = "./modules/route_table/"

   route_table_name        = "s2-core-rt"
   route_name              = ["toEdgeRouter"]
   route_prefix            = ["10.0.0.0/24"]
   next_hop_type           = ["VirtualAppliance"]
   next_hop_in_ip_address  = ["${module.s2-edge.ip_address}"]
   subnet_ids              = ["${module.vnet-s2-core.subnet_ids[0]}"]
   location                = var.location
   resource_group_name  = azurerm_resource_group.routing-lab-rg.name
}

# Edge - Create virtual network
module "vnet-s2-edge" {
   source               = "./modules/vnet"

   vnet_name            = "routing-s2-edge-vn"
   address_space        = "192.168.1.0/24"
   resource_group_name  = azurerm_resource_group.routing-lab-rg.name
   subnet_names         = ["default"]
   subnet_prefixes      = ["192.168.1.0/27"]
   network_security_group_ids = ["${module.nsg-all-subnets.id}"]
   location             = var.location
}

# Peering s2-core with s2-edge

resource "azurerm_virtual_network_peering" "s2-core-to-edge" {
   name                       = "s2CoreTos2Edge"
   resource_group_name        = azurerm_resource_group.routing-lab-rg.name
   virtual_network_name       = module.vnet-s2-core.name
   remote_virtual_network_id  = module.vnet-s2-edge.id
}

resource "azurerm_virtual_network_peering" "s2-edge-to-core" {
   name                       = "s2EdgeTos2Core"
   resource_group_name        = azurerm_resource_group.routing-lab-rg.name
   virtual_network_name       = module.vnet-s2-edge.name
   remote_virtual_network_id  = module.vnet-s2-core.id
}

# Peering s2-edge with interco

resource "azurerm_virtual_network_peering" "s2-edge-to-interco" {
   name                       = "s2EdgeToInterco"
   resource_group_name        = azurerm_resource_group.routing-lab-rg.name
   virtual_network_name       = module.vnet-s2-edge.name
   remote_virtual_network_id  = module.vnet-interco.id
}

resource "azurerm_virtual_network_peering" "interco-to-s2-edge" {
   name                       = "intercoTos2Edge"
   resource_group_name        = azurerm_resource_group.routing-lab-rg.name
   virtual_network_name       = module.vnet-interco.name
   remote_virtual_network_id  = module.vnet-s2-edge.id
}

## END of site 2

## Common configuration

module "route-table-association" {
   source = "./modules/route_table_association"

   subnet_ids           = ["${module.vnet-s1-core.subnet_ids[0]}","${module.vnet-s2-core.subnet_ids[0]}"]
   route_table_ids      = ["${module.s1-route-table.id}","${module.s2-route-table.id}"]
}

module "nsg-all-subnets" {
   source                     = "./modules/nsg"

   resource_group_name        = azurerm_resource_group.routing-lab-rg.name
   location                   = var.location
   security_group_name        = "nsg-all"
   rules                      = [
      {
         name                   = "ssh"
         priority               = "100"
         direction              = "Inbound"
         access                 = "Allow"
         protocol               = "tcp"
         destination_port_range = "22"
         description            = "Allow SSH access from outside"
      }
   ]
}
#    subnet_ids                 = ["${module.vnet-s1-core.subnet_ids[0]}","${module.vnet-s1-edge.subnet_ids[0]}","${module.vnet-s2-core.subnet_ids[0]}","${module.vnet-s2-edge.subnet_ids[0]}","${module.vnet-interco.subnet_ids[0]}"]
# }

module "ngs-association" {
   source = "./modules/nsg_association"

   subnet_ids                 = ["${module.vnet-s1-core.subnet_ids[0]}","${module.vnet-s1-edge.subnet_ids[0]}","${module.vnet-s2-core.subnet_ids[0]}","${module.vnet-s2-edge.subnet_ids[0]}","${module.vnet-interco.subnet_ids[0]}"]
   network_security_group_ids = ["${module.nsg-all-subnets.id}","${module.nsg-all-subnets.id}","${module.nsg-all-subnets.id}","${module.nsg-all-subnets.id}","${module.nsg-all-subnets.id}"]
}
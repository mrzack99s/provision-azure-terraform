terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.36.0"
    }
  }
}

provider "azurerm" {
  features {}
}

##### 1st [Create a resource groups]
#Crete global rg
resource "azurerm_resource_group" "global-rg" {
  name     = "tf-global-rg"
  location = "Southeast Asia"
}

#Crete hub rg
resource "azurerm_resource_group" "hub-rg" {
  count    = length(var.provide_objects)
  name     = "tf-hub-${var.provide_objects[count.index]["role"]}-rg"
  location = var.provide_objects[count.index]["location"]
}

#Crete spoke rg
resource "azurerm_resource_group" "spoke-rg" {
  count    = length(var.provide_objects)
  name     = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  location = var.provide_objects[count.index]["location"]
}


##### 2nd [Create a public ip]
#Crete PIP
resource "azurerm_public_ip" "pip" {
  count               = length(var.provide_objects)
  name                = "tf-pip-${var.provide_objects[count.index]["role"]}"
  resource_group_name = "tf-hub-${var.provide_objects[count.index]["role"]}-rg"
  location            = var.provide_objects[count.index]["location"]
  domain_name_label   = "tf-m-pip-${var.provide_objects[count.index]["role"]}"
  sku                 = "Standard"
  allocation_method   = "Static"
  depends_on          = [azurerm_resource_group.hub-rg]
}

##### 3rd [Create a virtual network]
## vnet hub
resource "azurerm_virtual_network" "hvnet" {
  count               = length(var.provide_objects)
  name                = "vnet-hub-${var.provide_objects[count.index]["role"]}"
  location            = var.provide_objects[count.index]["location"]
  resource_group_name = "tf-hub-${var.provide_objects[count.index]["role"]}-rg"
  address_space       = [var.provide_objects[count.index]["subnets"]["hub"]["main_subnet"]]
  depends_on          = [azurerm_resource_group.hub-rg]
}

## vnet spoke
resource "azurerm_virtual_network" "svnet" {
  count               = length(var.provide_objects)
  name                = "vnet-spoke-${var.provide_objects[count.index]["role"]}"
  location            = var.provide_objects[count.index]["location"]
  resource_group_name = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  address_space       = [var.provide_objects[count.index]["subnets"]["spoke"]["main_subnet"]]
  depends_on          = [azurerm_resource_group.spoke-rg]
}


##### 4th [Create a network security {basic}]
#Create hub NSG
resource "azurerm_network_security_group" "spoke-nsg" {
  count               = length(var.provide_objects)
  name                = "tf-hub-${var.provide_objects[count.index]["role"]}-nsg"
  location            = var.provide_objects[count.index]["location"]
  resource_group_name = "tf-hub-${var.provide_objects[count.index]["role"]}-rg"

  depends_on = [azurerm_resource_group.hub-rg]
}

#Create spoke NSG
resource "azurerm_network_security_group" "hub-nsg" {
  count               = length(var.provide_objects)
  name                = "tf-spoke-${var.provide_objects[count.index]["role"]}-nsg"
  location            = var.provide_objects[count.index]["location"]
  resource_group_name = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"

  depends_on = [azurerm_resource_group.spoke-rg]
}

## Hub nsg rules
#Create rule [allow 80]
resource "azurerm_network_security_rule" "hub-nsg-rule-http" {
  count                       = length(var.provide_objects)
  name                        = "allow-80"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "tf-hub-${var.provide_objects[count.index]["role"]}-rg"
  network_security_group_name = "tf-hub-${var.provide_objects[count.index]["role"]}-nsg"
  depends_on                  = [azurerm_network_security_group.hub-nsg]
}

#Create rule [allow 22]
resource "azurerm_network_security_rule" "hub-nsg-rule-ssh" {
  count                       = length(var.provide_objects)
  name                        = "allow-22"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "tf-hub-${var.provide_objects[count.index]["role"]}-rg"
  network_security_group_name = "tf-hub-${var.provide_objects[count.index]["role"]}-nsg"
  depends_on                  = [azurerm_network_security_group.hub-nsg]
}

#Create rule [allow 2222]
resource "azurerm_network_security_rule" "hub-nsg-rule-ssh-vm2" {
  count                       = length(var.provide_objects)
  name                        = "allow-2222"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "2222"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "tf-hub-${var.provide_objects[count.index]["role"]}-rg"
  network_security_group_name = "tf-hub-${var.provide_objects[count.index]["role"]}-nsg"
  depends_on                  = [azurerm_network_security_group.hub-nsg]
}

## Spoke nsg rules
#Create rule [allow 80]
resource "azurerm_network_security_rule" "nsg-rule-http" {
  count                       = length(var.provide_objects)
  name                        = "allow-80"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  network_security_group_name = "tf-spoke-${var.provide_objects[count.index]["role"]}-nsg"
  depends_on                  = [azurerm_network_security_group.spoke-nsg]
}

#Create rule [allow 22]
resource "azurerm_network_security_rule" "nsg-rule-ssh" {
  count                       = length(var.provide_objects)
  name                        = "allow-22"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  network_security_group_name = "tf-spoke-${var.provide_objects[count.index]["role"]}-nsg"
  depends_on                  = [azurerm_network_security_group.spoke-nsg]
}

#Create rule [allow 2222]
resource "azurerm_network_security_rule" "nsg-rule-ssh-vm2" {
  count                       = length(var.provide_objects)
  name                        = "allow-2222"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "2222"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  network_security_group_name = "tf-spoke-${var.provide_objects[count.index]["role"]}-nsg"
  depends_on                  = [azurerm_network_security_group.spoke-nsg]
}

##### 5th [Create a subnet of virtual network]
# Create hub subnet 
resource "azurerm_subnet" "hsubnet" {
  count                = length(var.provide_objects)
  name                 = "tf-hub-${var.provide_objects[count.index]["role"]}-internal"
  resource_group_name  = "tf-hub-${var.provide_objects[count.index]["role"]}-rg"
  virtual_network_name = "vnet-hub-${var.provide_objects[count.index]["role"]}"
  address_prefixes     = [var.provide_objects[count.index]["subnets"]["hub"]["subnet"]]
  depends_on           = [azurerm_virtual_network.hvnet, azurerm_network_security_group.hub-nsg]
}

# Create spoke subnet 
resource "azurerm_subnet" "ssubnet" {
  count                = length(var.provide_objects)
  name                 = "tf-spoke-${var.provide_objects[count.index]["role"]}-internal"
  resource_group_name  = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  virtual_network_name = "vnet-spoke-${var.provide_objects[count.index]["role"]}"
  address_prefixes     = [var.provide_objects[count.index]["subnets"]["spoke"]["subnet"]]
  depends_on           = [azurerm_virtual_network.svnet, azurerm_network_security_group.spoke-nsg]
}

#Create hub peering
resource "azurerm_virtual_network_peering" "hpeering" {
  count                        = length(var.provide_objects)
  name                         = "peering-${element(azurerm_virtual_network.hvnet.*.name, count.index)}-to-${element(azurerm_virtual_network.svnet.*.name, count.index)}"
  resource_group_name          = "tf-hub-${var.provide_objects[count.index]["role"]}-rg"
  virtual_network_name         = element(azurerm_virtual_network.hvnet.*.name, count.index)
  remote_virtual_network_id    = element(azurerm_virtual_network.svnet.*.id, count.index)
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  # `allow_gateway_transit` must be set to false for vnet Global Peering
  allow_gateway_transit = false
  depends_on            = [azurerm_virtual_network.hvnet, azurerm_virtual_network.svnet]
}

#Create spoke peering
resource "azurerm_virtual_network_peering" "speering" {
  count                        = length(var.provide_objects)
  name                         = "peering-${element(azurerm_virtual_network.svnet.*.name, count.index)}-to-${element(azurerm_virtual_network.hvnet.*.name, count.index)}"
  resource_group_name          = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  virtual_network_name         = element(azurerm_virtual_network.svnet.*.name, count.index)
  remote_virtual_network_id    = element(azurerm_virtual_network.hvnet.*.id, count.index)
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  # `allow_gateway_transit` must be set to false for vnet Global Peering
  allow_gateway_transit = false
  depends_on            = [azurerm_virtual_network.hvnet, azurerm_virtual_network.svnet]
}

##### 6th [Subnet allocation to NSG]
#Hub
resource "azurerm_subnet_network_security_group_association" "hub-nsg-subnet" {
  count                     = length(var.provide_objects)
  subnet_id                 = azurerm_subnet.hsubnet[count.index].id
  network_security_group_id = azurerm_network_security_group.hub-nsg[count.index].id

  depends_on = [azurerm_network_security_group.hub-nsg]
}

#Spoke
resource "azurerm_subnet_network_security_group_association" "nsg-subnet" {
  count                     = length(var.provide_objects)
  subnet_id                 = azurerm_subnet.ssubnet[count.index].id
  network_security_group_id = azurerm_network_security_group.spoke-nsg[count.index].id

  depends_on = [azurerm_network_security_group.spoke-nsg]
}

##### 7th [Create a network interfaces]
#Create NIC VM1
resource "azurerm_network_interface" "s-nic-vm" {
  count               = length(var.provide_objects)
  name                = "tf-spoke-${var.provide_objects[count.index]["role"]}-nic"
  location            = var.provide_objects[count.index]["location"]
  resource_group_name = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"

  ip_configuration {
    name                          = "internal-vms1"
    subnet_id                     = azurerm_subnet.ssubnet[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [azurerm_subnet.ssubnet]
}

#Create NIC2 VM2
resource "azurerm_network_interface" "s-nic-vm2" {
  count               = length(var.provide_objects)
  name                = "tf-spoke-${var.provide_objects[count.index]["role"]}-nic2"
  location            = var.provide_objects[count.index]["location"]
  resource_group_name = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"

  ip_configuration {
    name                          = "internal-vms2"
    subnet_id                     = azurerm_subnet.ssubnet[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [azurerm_subnet.ssubnet]
}

##### 8th [Create a virtual machines]
#Create VMs 1
resource "azurerm_linux_virtual_machine" "s-vm" {
  count                           = length(var.provide_objects)
  name                            = "tf-spoke-${var.provide_objects[count.index]["role"]}-vm"
  location                        = var.provide_objects[count.index]["location"]
  resource_group_name             = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  size                            = "Standard_B1s"
  admin_username                  = "user"
  admin_password                  = "user@123456"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.s-nic-vm[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = "30"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  depends_on = [azurerm_network_interface.s-nic-vm]

}

#Create VMs 2
resource "azurerm_linux_virtual_machine" "s-vm2" {
  count                           = length(var.provide_objects)
  name                            = "tf-spoke-${var.provide_objects[count.index]["role"]}-vm2"
  location                        = var.provide_objects[count.index]["location"]
  resource_group_name             = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  size                            = "Standard_B1s"
  admin_username                  = "user"
  admin_password                  = "user@123456"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.s-nic-vm2[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = "30"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  depends_on = [azurerm_network_interface.s-nic-vm2]

}


##### 9th [Create a Load Balancer]
#Create LB
resource "azurerm_lb" "lb" {
  count               = length(var.provide_objects)
  name                = "tf-spoke-${var.provide_objects[count.index]["role"]}-lb"
  location            = var.provide_objects[count.index]["location"]
  resource_group_name = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "lb-spoke-${var.provide_objects[count.index]["role"]}-pip"
    public_ip_address_id = azurerm_public_ip.pip[count.index].id
  }

  depends_on = [azurerm_public_ip.pip]
}

#Create Backend pools
resource "azurerm_lb_backend_address_pool" "lb-bend-pool" {
  count               = length(var.provide_objects)
  resource_group_name = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  loadbalancer_id     = azurerm_lb.lb[count.index].id
  name                = "tf-spoke-${var.provide_objects[count.index]["role"]}-lb-backpool"
  depends_on          = [azurerm_lb.lb]
}

#VMs1 allocation to backend pool
resource "azurerm_network_interface_backend_address_pool_association" "al-bend-pool" {
  count                   = length(var.provide_objects)
  network_interface_id    = azurerm_network_interface.s-nic-vm[count.index].id
  ip_configuration_name   = "internal-vms1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb-bend-pool[count.index].id

  depends_on = [azurerm_lb_backend_address_pool.lb-bend-pool, azurerm_network_interface.s-nic-vm]
}

#VMs1 allocation to backend pool
resource "azurerm_network_interface_backend_address_pool_association" "al-bend-pool2" {
  count                   = length(var.provide_objects)
  network_interface_id    = azurerm_network_interface.s-nic-vm2[count.index].id
  ip_configuration_name   = "internal-vms2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb-bend-pool[count.index].id

  depends_on = [azurerm_lb_backend_address_pool.lb-bend-pool, azurerm_network_interface.s-nic-vm2]
}

#Forward port 22
resource "azurerm_lb_nat_rule" "lb-fwd22" {
  count                          = length(var.provide_objects)
  resource_group_name            = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  loadbalancer_id                = azurerm_lb.lb[count.index].id
  name                           = "fwd-spoke-${var.provide_objects[count.index]["role"]}-port-22"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "lb-spoke-${var.provide_objects[count.index]["role"]}-pip"
  depends_on                     = [azurerm_lb.lb, azurerm_lb_backend_address_pool.lb-bend-pool]
}

#Forward port 2222
resource "azurerm_lb_nat_rule" "lb-fwd2222" {
  count                          = length(var.provide_objects)
  resource_group_name            = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  loadbalancer_id                = azurerm_lb.lb[count.index].id
  name                           = "fwd-spoke-${var.provide_objects[count.index]["role"]}-port-2222"
  protocol                       = "Tcp"
  frontend_port                  = 2222
  backend_port                   = 22
  frontend_ip_configuration_name = "lb-spoke-${var.provide_objects[count.index]["role"]}-pip"
  depends_on                     = [azurerm_lb.lb, azurerm_lb_backend_address_pool.lb-bend-pool]
}

#Allocate nat rule
resource "azurerm_network_interface_nat_rule_association" "al-p22-vms1" {
  count                 = length(var.provide_objects)
  network_interface_id  = azurerm_network_interface.s-nic-vm[count.index].id
  ip_configuration_name = "internal-vms1"
  nat_rule_id           = azurerm_lb_nat_rule.lb-fwd22[count.index].id
  depends_on            = [azurerm_lb_nat_rule.lb-fwd22, azurerm_network_interface.s-nic-vm]
}

resource "azurerm_network_interface_nat_rule_association" "al-p22-vms2" {
  count                 = length(var.provide_objects)
  network_interface_id  = azurerm_network_interface.s-nic-vm2[count.index].id
  ip_configuration_name = "internal-vms2"
  nat_rule_id           = azurerm_lb_nat_rule.lb-fwd2222[count.index].id
  depends_on            = [azurerm_network_interface.s-nic-vm2, azurerm_lb_nat_rule.lb-fwd2222]
}

#Create probe
resource "azurerm_lb_probe" "lb-probe" {
  count               = length(var.provide_objects)
  resource_group_name = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  loadbalancer_id     = azurerm_lb.lb[count.index].id
  name                = "http-probe"
  port                = 80
}

#Create rule
resource "azurerm_lb_rule" "lb-rule" {
  count                          = length(var.provide_objects)
  resource_group_name            = "tf-spoke-${var.provide_objects[count.index]["role"]}-rg"
  loadbalancer_id                = azurerm_lb.lb[count.index].id
  name                           = "LBRule-80"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "lb-spoke-${var.provide_objects[count.index]["role"]}-pip"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.lb-bend-pool[count.index].id
  probe_id                       = azurerm_lb_probe.lb-probe[count.index].id
  enable_tcp_reset               = true

  depends_on = [azurerm_public_ip.pip, azurerm_lb_backend_address_pool.lb-bend-pool, azurerm_lb_probe.lb-probe]
}

##### 9th [Create a traffic manager to global zone]
# Create Traffic Manager
resource "azurerm_traffic_manager_profile" "tf-mg-global" {
  name                   = "tf-tf-manager"
  resource_group_name    = "tf-global-rg"
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "tf-m-hub-spoke"
    ttl           = 60
  }

  monitor_config {
    protocol                     = "http"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 10
    timeout_in_seconds           = 5
    tolerated_number_of_failures = 3
  }

  depends_on = [azurerm_resource_group.global-rg]

}

# Add End Point
resource "azurerm_traffic_manager_endpoint" "tf-mg-endpoint" {
  count               = length(var.provide_objects)
  name                = "tf-mg-endpoint-${var.provide_objects[count.index]["role"]}"
  resource_group_name = "tf-global-rg"
  profile_name        = "tf-tf-manager"
  target_resource_id  = azurerm_public_ip.pip[count.index].id
  type                = "azureEndpoints"
  priority            = count.index + 1

  depends_on = [azurerm_traffic_manager_profile.tf-mg-global]
}

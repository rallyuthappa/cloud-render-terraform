# Configure the Azure Provider
provider "azurerm" {
    subscription_id = "${var.subscription_id}"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    tenant_id       = "${var.tenant_id}"
    }

# Create the Master Resource Group for  Administration VM and Networking
resource "azurerm_resource_group" "prg" {
  name     = "az-render-primary-rg"
  location = "westus"
}

# Image Resource Group (temp)
resource "azurerm_resource_group" "irg" {
  name     = "az-render-image-rg"
  location = "westus"
}

# Create a Resource Group for the show or project. Scale Sets are created in this RG
resource "azurerm_resource_group" "rg" {
  name     = "az-render-clients-rg"
  location = "${var.location}"
}

# Create Virtual Network and subnets in Primary RG

resource "azurerm_virtual_network" "vnet" {
  name                = "az-render-vnet"
  location            = "westus"
  address_space       = ["10.128.0.0/16"]
  resource_group_name = "${azurerm_resource_group.prg.name}"
}

resource "azurerm_subnet" "render" {
  name                 = "RenderClients"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.prg.name}"
  address_prefix       = "10.128.0.0/20"
  network_security_group_id = "${azurerm_network_security_group.render.id}"
}

resource "azurerm_subnet" "fastcache" {
  name                 = "FastCache"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.prg.name}"
  address_prefix       = "10.128.16.0/24"
  network_security_group_id = "${azurerm_network_security_group.fastcache.id}"
}

resource "azurerm_subnet" "management" {
  name                 = "Management"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.prg.name}"
  address_prefix       = "10.128.17.0/24"
  network_security_group_id = "${azurerm_network_security_group.management.id}"
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.prg.name}"
  address_prefix       = "10.128.18.0/27"
}

# Create Network Security Groups with rules

resource "azurerm_network_security_group" "management" {
  name                = "Management-nsg"
  location            = "${azurerm_resource_group.prg.location}"
  resource_group_name = "${azurerm_resource_group.prg.name}"
  security_rule {
    name                       = "allow_SSH"
    description                = "Allow SSH access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_RDP"
    description                = "Allow RDP access"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "render" {
  name                = "Render-nsg"
  location            = "${azurerm_resource_group.prg.location}"
  resource_group_name = "${azurerm_resource_group.prg.name}"
}

resource "azurerm_network_security_group" "fastcache" {
  name                = "FastCache-nsg"
  location            = "${azurerm_resource_group.prg.location}"
  resource_group_name = "${azurerm_resource_group.prg.name}"
  
}

# Create Render VM Scale Set

data "azurerm_resource_group" "image" {
  name = "${azurerm_resource_group.irg.name}"
}

data "azurerm_image" "image" {
  name                = "ubuntu-image-001"
  resource_group_name = "${data.azurerm_resource_group.image.name}"
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "${var.vmssname}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  upgrade_policy_mode = "Manual"
  single_placement_group = "False"
  overprovision = "True"

  sku {
    name     = "${var.vmsize}"
    tier     = "Standard"
    capacity = "${var.capacity}"
  }

  storage_profile_image_reference {
    id="${data.azurerm_image.image.id}"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }


  os_profile {
    computer_name_prefix = "${var.vmssname}"
    admin_username       = "${var.adminusername}"
    admin_password       = "${var.adminpassword}"
  }

  network_profile {
    name    = "scalesetnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = "${azurerm_subnet.render.id}"
    }
  }

}

# Create Administration / Jump Host

# Create a Public IP for the Virtual Machine
resource "azurerm_public_ip" "pip" {
  name                         = "AdminVM-pip"
  location                     = "${azurerm_resource_group.prg.location}"
  resource_group_name          = "${azurerm_resource_group.prg.name}"
  public_ip_address_allocation = "dynamic"
}

# Create a network interface for VM and attach the PIP
resource "azurerm_network_interface" "nic" {
  name                      = "AdminVM-nic"
  location                  = "${azurerm_resource_group.prg.location}"
  resource_group_name       = "${azurerm_resource_group.prg.name}"
  
  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.management.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.pip.id}"
  }
}

# Create a new Virtual Machine based on the Golden Image
resource "azurerm_virtual_machine" "vm" {
  name                             = "AdminVM"
  location                         = "${azurerm_resource_group.prg.location}"
  resource_group_name              = "${azurerm_resource_group.prg.name}"
  network_interface_ids            = ["${azurerm_network_interface.nic.id}"]
  vm_size                          = "Standard_DS1_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = "${data.azurerm_image.image.id}"
  }

  storage_os_disk {
    name              = "AdminVM-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "40"
  }

  os_profile {
    computer_name  = "AdminVM"
    admin_username = "${var.adminusername}"
    admin_password = "${var.adminpassword}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

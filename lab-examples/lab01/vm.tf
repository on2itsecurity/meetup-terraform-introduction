//Specify the provider
provider "azurerm" {
}

//Get the resourcegroup
data "azurerm_resource_group" "rg" {
    name = var.resource_group_name
}

//Create the resources
//Create a VNET
resource "azurerm_virtual_network" "vnet" {
    name                = var.vnet_name
    address_space       = var.vnet_address_space
    location            = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name
}

//Create a subnet
resource "azurerm_subnet" "subnet-servers" {
    name                 = var.subnet_servers_name
    resource_group_name  = data.azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefix       = var.subnet_servers_cidr
}

//Create a public IP address
resource "azurerm_public_ip" "vm-pip" {
    name                = format("%s%s", var.virtual_machine_name, "-pip")
    location            = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name
    allocation_method   = "Dynamic"

    domain_name_label   = var.domain_name_label
}

//Create a Network Security Group
resource "azurerm_network_security_group" "nsg" {
    name                = format("%s%s", var.virtual_machine_name,"-nsg")
    location            = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1000   
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "188.207.248.162"
        destination_address_prefix = "*"
    }
}

//Create a nic
resource "azurerm_network_interface" "vm-nic" {
  name                      = format("%s%s", var.virtual_machine_name, "-nic")
  location                  = data.azurerm_resource_group.rg.location
  resource_group_name       = data.azurerm_resource_group.rg.name
  network_security_group_id = azurerm_network_security_group.nsg.id

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet-servers.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm-pip.id
  }
}


//Create virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                  = var.virtual_machine_name
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm-nic.id]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = format("%s%s", var.virtual_machine_name, "-disk")
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = var.virtual_machine_name
    admin_username = "labuser"
    admin_password = "P@ssw0rd!123"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

output "public_ip_address" {
    value = azurerm_public_ip.vm-pip.ip_address
}

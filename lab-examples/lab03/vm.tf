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
    count               = var.number_of_vms * 3
    name                = format("%s%s%s", var.virtual_machine_name, count.index, "-pip")
    location            = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name
    allocation_method   = "Dynamic"

    domain_name_label   = format("%s-%s-%s", var.domain_name_label, floor(count.index / 3) + 1, (count.index % 3) +1)
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
  count                     = var.number_of_vms
  name                      = format("%s%s%s", var.virtual_machine_name, count.index, "-nic")
  location                  = data.azurerm_resource_group.rg.location
  resource_group_name       = data.azurerm_resource_group.rg.name
  network_security_group_id = azurerm_network_security_group.nsg.id

  dynamic ip_configuration {
    for_each = [[0,3,6],[1,4,7],[2,5,8]]
    content {
        name                          = format("%s%s","ipconfig", ip_configuration.key + 1)
        primary                       = ip_configuration.key == 0 ? true : false
        subnet_id                     = azurerm_subnet.subnet-servers.id
        
        private_ip_address_allocation = "Static"
        private_ip_address            = format("%s%s", "10.10.1.", ip_configuration.value[count.index] + 4)

        public_ip_address_id          = azurerm_public_ip.vm-pip[ip_configuration.value[count.index]].id
    }
  }
}


//Create virtual machine
resource "azurerm_virtual_machine" "vm" {
  count                 = var.number_of_vms
  name                  = format("%s%s", var.virtual_machine_name, count.index)
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm-nic[count.index].id]
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
    name              = format("%s%s%s", var.virtual_machine_name, count.index, "-disk")
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = format("%s%s", var.virtual_machine_name, count.index)
    admin_username = "labuser"
    admin_password = "P@ssw0rd!123"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine_extension" "vm-extension" {
    count                   = var.number_of_vms
    name                    = format("%s%s%s", var.virtual_machine_name, count.index, "-set-ip-address")
    location                = data.azurerm_resource_group.rg.location
    resource_group_name     = data.azurerm_resource_group.rg.name
    virtual_machine_name    = format("%s%s", var.virtual_machine_name, count.index)
    publisher               = "Microsoft.Azure.Extensions"
    type                    = "CustomScript"
    type_handler_version    = "2.0"
    depends_on              = [azurerm_virtual_machine.vm]

    #azurerm_virtual_machine.vm[count.index].ip_configuration[1].private_ip_address

    settings = <<SETTINGS
    {   
        "commandToExecute": "sudo ip addr add ${azurerm_network_interface.vm-nic[count.index].ip_configuration[0].private_ip_address}/24 dev eth0; sudo ip addr add ${azurerm_network_interface.vm-nic[count.index].ip_configuration[1].private_ip_address}/24 dev eth0; sudo ip addr add ${azurerm_network_interface.vm-nic[count.index].ip_configuration[2].private_ip_address}/24 dev eth0;"
    }
SETTINGS

}

output "public_ip_addresses" {
    value = {
       for pip in azurerm_public_ip.vm-pip: 
       pip.domain_name_label => pip.ip_address
    }
}
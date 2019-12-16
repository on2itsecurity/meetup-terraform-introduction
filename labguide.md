# LAB Guide

## Introduction
This LAB-Guide is intended for use during the ON2IT Terraform Meetup. 
The given exercises are explained for Azure, but you could use AWS as well.

## Prerequisites

* Terraform 0.12.6 (or higher) installed (https://www.terraform.io/downloads.html)
* Some 'cloud' credentials (Azure) - Will be provided during the Meetup
* Code/Text editor - recommended: VS Code (https://code.visualstudio.com/) with the Terraform extension
* Download Azure / AWS CLI Tools.
  * Azure: https://docs.microsoft.com/nl-nl/cli/azure/install-azure-cli?view=azure-cli-latest

## LAB Exercises

### LAB 0 - Preperation 

* Create a folder where you will place your lab files, i.e. Terraform-Labs.
* Login to the cloud-provider with Azure CLI

  ```bash
  az login
  ```

These commands will create a 'credential' file, which Terraform will use for authentication and authorization with the cloud provider. 

*Note: You can also specify the credentials within Terraform in the Provider section*

### LAB 1 - Setting up a VM

During this lab we will set up a VM with a public IP address.

* Create a new file in the working directory, named 'main.tf' and open it.
* Add the provider on top of the file (azurerm), it tells Terraform what resources it could use. The below snippet is sufficient, although you can specify extra parameters, like the version which is recommended for production usage.

```terraform
provider "azurerm" {
}
```

* Save the file and run Terraform init from the working folder. You will see that terraform will download the provider. (it is stored in .terraform)

```bash
terraform init
```
* The next step is to setup our environment;

The resourcegroup is already created and you can use a 'data source' to get the resourcegroup resource.
The resourcegroupname is meetup-lab*XX*.

```terraform
data "azurerm_resource_group" "rg" {
    name = "meetup-lab00"
}
```
Despite the example above it is recommended to use variables!

Now add the following resources;

* Virtual Network (VNET)
* Subnet
* Public IP Address (PIP)
  * Make sure the domain-name-label is set to on2it-meetup-lab*XX*, i.e. on2it-meetup-lab01-1
* Network Security Group (NSG) 
  * Make sure port 22 is allowed from 188.207.248.162 (if you're not on the guest-wifi, add your IP address too)
  * Make sue to connect the NSG to either the subnet or the NIC, otherwise no external traffic will be allowed.
* Network interface (NIC)
* Virtual-machine (VM)
  * Any linux distribution will do, make sure SSH is enabled, i.e.;
    ```
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
    ```
*TIP* Terraform documentation is very good, you can find all about the Azure Provider (and resources) here:
 https://www.terraform.io/docs/providers/azurerm/ 

* Make an output that will show the public IP address (*hint* if the output is empty after a succesful run, run the apply again)
* Try to connect over SSH to this VM, if this work, you probably did everything right :)

### LAB 2 - Repetition

**Extra challenge, make the number of VMs a variable**

* Edit your Terraform template, so that it will deploy 3 VMs, with just specifying the resource(s) once and making use of the 'count' parameter.
* The public DNS domain label should be, on2it-meetup-lab*XX*-1, on2it-meetup-lab*XX*-2, on2it-meetup-lab*XX*-
* Test the SSH to the VMs, to see if everything works.

*TIP* When you perform a 'terraform plan' be sure to carefully check the actions (add, remove and changed) to the configuration, before applying it. It can save a lot of time, destroying a VM can take up to over 10minutes.

### LAB 3 - Add extra IP Addresses to the NIC of the VM

* Add three additional public IP-addresses to the NIC of each VM. Using the for_each argument.
* Make sure to set one of the ip_configurations per NIC to primary.
* Make sure the DNS domain label is set as follows:
  on2it-meetup-lab-*XX*-Y-Z, where XX is the lab-number, Y is the VM number, Z is the Public IP number (i.e.: *on2it-meetup-lab-01-1-1, on2it-meetup-lab-01-1-2, etc.*)
* Test the SSH to the VMs, to see if everything works.

*Note:* You need to set the IP addresses on the OS, before SSH will work. You can do this manually, however it is possible to do this with Terraform !

*TIP* You can use the ternary operator.

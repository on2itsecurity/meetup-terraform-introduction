variable "resource_group_name" {
    //No default, will request if non is specified
}

variable "vnet_name" {
    default = "vnet01"
}

variable "vnet_address_space" {
    default = ["10.10.0.0/16"]
}

variable "subnet_servers_name" {
    default = "sn-servers"
}

variable "subnet_servers_cidr" {
    default = "10.10.1.0/24"
}

variable "domain_name_label" {
    default = "on2it-meetup-lab00"
}
variable "virtual_machine_name" {
    default = "my-first-server"
}


# Configure the Microsoft Azure Provider
provider "azurerm" {
subscription_id = "3eebb955-e46f-4638-b1a9-44f32469fc7e"
tenant_id = "02fb5f33-d1d2-46da-84c0-66aae992e7ca"
client_id = "8994c75a-727e-4d1a-8337-01183ed5f2cc"
client_secret = "rqJzbIl-D3-09Kz5wQ5~hmC86.sJ3kr8dH"
    version = "~>2.0"
    features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "Azuretraining"
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "Azuretraining-vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "subnet_1"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "Azuretraining-nsg"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.myterraformgroup.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.myterraformnic.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.myterraformgroup.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.myterraformgroup.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Availability set
resource "azurerm_availability_set" "example" {
    name                = "Azuretraining-av1"
    location            = "eastus"
    resource_group_name = "Azuretraining"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
# output "tls_private_key" { value = tls_private_key.example_ssh.private_key_pem }

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
    name                  = "Linuxmachine1"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "Linuxmachine1"
    admin_username = "india1"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "india1"
        public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkGfJyQLSacXMYp7RLzQmmq3FFjyPQBy3dnaqEVsKTlLX4wVr9ZD8iQUWN+Nj7AgpkSNsfe7C0wNCnb+Tc+z45/So/mwD3dLtjLx240U2kEGadojQO/oFZSE1Ag9r+fdq59EV/pxhVIY7f8mnCBQ+C/obXzDgZChduTNwqLNsAYgLOH9ciJ7bixuxustUIlmq4CoQSVg8pPKMmAZxoqt2wHBSWt0LPjwQlH8LjHAEXqRPcBU/bUylXpM0g9FXBAOPmwgUGEqGOrHR/WqAXlEnmO2SeVUIJZaTISODGzOk5vo8YxkyLj9gRkew/3i/woUILxV8rG5ait14BNNqgr9bj rsa-key-20210524"
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm1" {
    name                  = "Linuxmachine2"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]
    size                  = "Standard_B2ms"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "Linuxmachine2"
    admin_username = "india2"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "india2"
        public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZqlqpgn8+H0aAdjXgrRMlaubN/Q2MsXec7A8g8T1KI3cKvfvWz8wj6QAPJBwMv7TEhqXwLlAFSD4UwXlT114yYrAK+1gxy6OLQLT12Gqzfi9pRvLweG8pc12Ao6hKHAYqUNSe3I3ni6dRREa4EMx3Vbpxq2HdhDjzsIHdClisuGprGgAhzVMD1fP0xLiA4M3dT3xzxJxjfev8vcZSGQmbLxsNePrYoDmHBzy7BQBPsjdWU39A3NIs93m2yJrhBHyckH8i03lCpJb0QkxiytK54KLjp/6IWK9ezwhPeieX0nqPtWbpmO46C3xLJkXWhlEiQ0pwuwGGhsHHghsSsStJ rsa-key-20210524"
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform Demo"
    }
}
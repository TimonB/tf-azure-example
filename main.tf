# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroup"
    location = "germanywestcentral"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "germanywestcentral"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "germanywestcentral"
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "germanywestcentral"
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
    location                  = "germanywestcentral"
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
    location                    = "germanywestcentral"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = "germanywestcentral"
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

    computer_name  = "myvm"
    admin_username = "azureuser"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "azureuser"
        public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+FkIaSUP3ixaVIV8vdJrzQpdMYpTAT0rBhRa6mZ/lC1r/+mxhvasde5VgJ8tecRyhsP4OBBD8ZfDtm4g1pgM1AqxMgK9t7Xf5nJ7gLsa4RxkSz0vGtyNzD4QXjftuiE/GsZdQy/uybwxi9WYEG26tE7a0bCvv4/8HCb1em3dn6OUSEyNYpsB3YTjUybNn2j8kRznF8shrFI9oYu8TRQFT4WLzEnGPxlzqoYgGGKXqsvxvoXsvRj0eOw0lcLSWpS3j5rdEtQGhpq/HASBJ/0+T4Fbo0HhCfzFFVhWfA/uxKKx0ju5HHpOCys2MDuJTqnPRJVgNdliRzlCHtEnGPQJsuPCMCjIjIwgzleApF1nrvgdbUdR1R14ehcCfFIX+0BKe81Ug51ihhWgWh5dCK9U0ubA/sn9Ye2dPPt35wVkG8wgDSwk6fG72ibft774bux0a33/WYTuHdxbFgsynYC3o6Lj32Dm7xuR+bydaNXuEqFDONU0r+Cmlrdkqi8mLxo7PvlQHxZQTDvlLGdKhJJQQjXofdg4kZULIR5ZLt/ViukcjAH5S+WrgWPocHXke52jr4VUUTEY+1wkJzFYIx4yJ3HdXMRFGiaemlBQkXgCPDIgT007/D9lwBBh/kn6tYBBrx53PG77Lz/IE0oDF13DBp2RNuEEsO0Nf2wgCB1i10Q== tbirk@MacBook-Pro-von-Birk.local"
    }

    tags = {
        environment = "Terraform Demo"
    }
}
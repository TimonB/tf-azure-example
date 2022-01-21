# Configure the Microsoft Azure Provider
terraform {
    
  backend "azurerm" {
    resource_group_name  = "tamopstfstates"
    storage_account_name = "opstf"
    container_name       = "terraformgithubexample"
    key                  = "terraformgithubexample.tfstate"
  }    
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


variable "ssh_public_key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+FkIaSUP3ixaVIV8vdJrzQpdMYpTAT0rBhRa6mZ/lC1r/+mxhvasde5VgJ8tecRyhsP4OBBD8ZfDtm4g1pgM1AqxMgK9t7Xf5nJ7gLsa4RxkSz0vGtyNzD4QXjftuiE/GsZdQy/uybwxi9WYEG26tE7a0bCvv4/8HCb1em3dn6OUSEyNYpsB3YTjUybNn2j8kRznF8shrFI9oYu8TRQFT4WLzEnGPxlzqoYgGGKXqsvxvoXsvRj0eOw0lcLSWpS3j5rdEtQGhpq/HASBJ/0+T4Fbo0HhCfzFFVhWfA/uxKKx0ju5HHpOCys2MDuJTqnPRJVgNdliRzlCHtEnGPQJsuPCMCjIjIwgzleApF1nrvgdbUdR1R14ehcCfFIX+0BKe81Ug51ihhWgWh5dCK9U0ubA/sn9Ye2dPPt35wVkG8wgDSwk6fG72ibft774bux0a33/WYTuHdxbFgsynYC3o6Lj32Dm7xuR+bydaNXuEqFDONU0r+Cmlrdkqi8mLxo7PvlQHxZQTDvlLGdKhJJQQjXofdg4kZULIR5ZLt/ViukcjAH5S+WrgWPocHXke52jr4VUUTEY+1wkJzFYIx4yJ3HdXMRFGiaemlBQkXgCPDIgT007/D9lwBBh/kn6tYBBrx53PG77Lz/IE0oDF13DBp2RNuEEsO0Nf2wgCB1i10Q== tbirk@MacBook-Pro-von-Birk.local"
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

#
# GitHub Enterprise Server
#
#


variable "ghes-version" {
  type    = string
  default = "3.3.2"
}

variable "username" {
    type = string
    default = "ghadmin"
}

# Create public IPs
resource "azurerm_public_ip" "ghespublicip" {
    name                         = "ghesPublicIP"
    location                     = "germanywestcentral"
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_interface" "ghesnic" {
    name                      = "ghesnic"
    location                  = "germanywestcentral"
    resource_group_name       = azurerm_resource_group.myterraformgroup.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.ghespublicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_virtual_machine" "ghes-test" {
  name                  = "ghes-vm"
  location              = "germanywestcentral"
  resource_group_name   = azurerm_resource_group.myterraformgroup.name
  network_interface_ids = [azurerm_network_interface.ghesnic.id]
  vm_size               = "Standard_DS11_v2"

  # az vm image list --all -f GitHub-Enterprise
  storage_image_reference {
    publisher = "GitHub"
    offer     = "GitHub-Enterprise"
    sku       = "GitHub-Enterprise"
    version   = var.ghes-version
  }

  storage_os_disk {
    name              = "ghes-os-storage"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "200"
  }

  os_profile {
    computer_name  = "myghes"
    admin_username = var.username
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.username}/.ssh/authorized_keys"
      key_data = var.ssh_public_key
    }
 }
}

resource "azurerm_managed_disk" "ghes-data" {
  name                 = "ghes-disk1"
  location              = "germanywestcentral"
  resource_group_name   = azurerm_resource_group.myterraformgroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 50
}

resource "azurerm_virtual_machine_data_disk_attachment" "example" {
  managed_disk_id    = azurerm_managed_disk.ghes-data.id
  virtual_machine_id = azurerm_virtual_machine.ghes-test.id
  lun                = "10"
  caching            = "ReadWrite"
}

output "public_ip" {
  value       = azurerm_public_ip.ghespublicip.ip_address
  description = "The IP address of the GitHub Enterprise Server instance"
}


resource "azurerm_kubernetes_cluster" "example" {
  name                = "example-aks1"
  location              = "germanywestcentral"
   resource_group_name   = azurerm_resource_group.myterraformgroup.name
  dns_prefix          = "exampleaks1"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}
#
#output "client_certificate" {
#  value = azurerm_kubernetes_cluster.example.kube_config.0.client_certificate
#}
#
#output "kube_config" {
#  value = azurerm_kubernetes_cluster.example.kube_config_raw
#
#  sensitive = true
#}
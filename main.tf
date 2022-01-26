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
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
}


# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = var.environment
  }
}

# Create DNS Zone
resource "azurerm_dns_zone" "example-public" {
  name                = "azure.birk.cloud"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  tags = {
    environment = var.environment
  }
}

# Create a DNS Record
#resource "azurerm_dns_a_record" "example" {
#  name                = "test"
#  zone_name           = azurerm_dns_zone.example-public.name
#  resource_group_name = azurerm_resource_group.myterraformgroup.name
#  ttl                 = 300
#  records             = ["20.82.11.13"]
#  tags = {
#    environment = var.environment
#  }
#}
#


# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  tags = {
    environment = var.environment
  }
}

# Create Subnet
resource "azurerm_subnet" "myterraformsubnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}



resource "azurerm_subnet" "k8s" {
  name                 = "k8s"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = "k8s"
  address_prefixes     = ["10.0.2.0/24"]
}


#
# VM Creation
#


## Create public IP for VM
#resource "azurerm_public_ip" "myterraformpublicip" {
#  name                = "myPublicIP"
#  location            = var.location
#  resource_group_name = azurerm_resource_group.myterraformgroup.name
#  allocation_method   = "Dynamic"
#
#  tags = {
#    environment = var.environment
#  }
#}
#
# 
## Create DNS Record
#resource "azurerm_dns_a_record" "myvm" {
#  name                = "vm01"
#  zone_name           = azurerm_dns_zone.example-public.name
#  resource_group_name = azurerm_resource_group.myterraformgroup.name
#  ttl                 = 300
#  target_resource_id  = azurerm_public_ip.myterraformpublicip.id
#}
#
#
## Create Network Security Group and rule
#resource "azurerm_network_security_group" "myterraformnsg" {
#  name                = "myNetworkSecurityGroup"
#  location            = var.location
#  resource_group_name = azurerm_resource_group.myterraformgroup.name
#
#  security_rule {
#    name                       = "SSH"
#    priority                   = 1001
#    direction                  = "Inbound"
#    access                     = "Allow"
#    protocol                   = "Tcp"
#    source_port_range          = "*"
#    destination_port_range     = "22"
#    source_address_prefix      = "*"
#    destination_address_prefix = "*"
#  }
#
#  tags = {
#    environment = var.environment
#  }
#}
#
## Create network interface
#resource "azurerm_network_interface" "myterraformnic" {
#  name                = "myNIC"
#  location            = var.location
#  resource_group_name = azurerm_resource_group.myterraformgroup.name
#
#  ip_configuration {
#    name                          = "myNicConfiguration"
#    subnet_id                     = azurerm_subnet.myterraformsubnet.id
#    private_ip_address_allocation = "Dynamic"
#    public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
#  }
#
#  tags = {
#    environment = var.environment
#  }
#}
#
## Connect the security group to the network interface
#resource "azurerm_network_interface_security_group_association" "example" {
#  network_interface_id      = azurerm_network_interface.myterraformnic.id
#  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
#}
#
#
## Create virtual machine
#resource "azurerm_linux_virtual_machine" "myterraformvm" {
#  name                  = "myVM"
#  location              = var.location
#  resource_group_name   = azurerm_resource_group.myterraformgroup.name
#  network_interface_ids = [azurerm_network_interface.myterraformnic.id]
#  size                  = "Standard_D1_v2"
#
#  os_disk {
#    name                 = "myOsDisk"
#    caching              = "ReadWrite"
#    storage_account_type = "Standard_LRS"
#  }
#
#  source_image_reference {
#    publisher = "Canonical"
#    offer     = "UbuntuServer"
#    sku       = "18.04-LTS"
#    version   = "latest"
#  }
#
#  computer_name                   = "myvm"
#  admin_username                  = "azureuser"
#  disable_password_authentication = true
#
#  admin_ssh_key {
#    username   = "azureuser"
#    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+FkIaSUP3ixaVIV8vdJrzQpdMYpTAT0rBhRa6mZ/lC1r/+mxhvasde5VgJ8tecRyhsP4OBBD8ZfDtm4g1pgM1AqxMgK9t7Xf5nJ7gLsa4RxkSz0vGtyNzD4QXjftuiE/GsZdQy/uybwxi9WYEG26tE7a0bCvv4/8HCb1em3dn6OUSEyNYpsB3YTjUybNn2j8kRznF8shrFI9oYu8TRQFT4WLzEnGPxlzqoYgGGKXqsvxvoXsvRj0eOw0lcLSWpS3j5rdEtQGhpq/HASBJ/0+T4Fbo0HhCfzFFVhWfA/uxKKx0ju5HHpOCys2MDuJTqnPRJVgNdliRzlCHtEnGPQJsuPCMCjIjIwgzleApF1nrvgdbUdR1R14ehcCfFIX+0BKe81Ug51ihhWgWh5dCK9U0ubA/sn9Ye2dPPt35wVkG8wgDSwk6fG72ibft774bux0a33/WYTuHdxbFgsynYC3o6Lj32Dm7xuR+bydaNXuEqFDONU0r+Cmlrdkqi8mLxo7PvlQHxZQTDvlLGdKhJJQQjXofdg4kZULIR5ZLt/ViukcjAH5S+WrgWPocHXke52jr4VUUTEY+1wkJzFYIx4yJ3HdXMRFGiaemlBQkXgCPDIgT007/D9lwBBh/kn6tYBBrx53PG77Lz/IE0oDF13DBp2RNuEEsO0Nf2wgCB1i10Q== tbirk@MacBook-Pro-von-Birk.local"
#  }
#
#  tags = {
#    environment = var.environment
#  }
#}
#


#
# AKS Kubernetes
#
#

#
# resource "azurerm_kubernetes_cluster" "example" {
#  name                = "example-aks1"
#  location            = var.location
#  resource_group_name = azurerm_resource_group.myterraformgroup.name
#  dns_prefix          = "exampleaks1"
#
#  default_node_pool {
#    name       = "default"
#    node_count = 1
#    vm_size    = "Standard_D2_v2"
#    node_labels = {
#      "rootuser.net/performancelevel" = "slow"
#    }
#  }
#
#  identity {
#    type = "SystemAssigned"
#  }
#comm
#  tags = {
#    environment = var.environment
#  }
#
#
#
#  addon_profile {
#    aci_connector_linux {
#      enabled = false
#    }
#
#    azure_policy {
#      enabled = false
#    }
#
#    http_application_routing {
#      enabled = false
#    }
#
#    oms_agent {
#      enabled = false
#    }
#  }
#
#}
#resource "azurerm_kubernetes_cluster_node_pool" "example" {
#  name                  = "spot"
#  kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
#  vm_size               = "Standard_D2_v2"
#  node_count            = 1
#  priority              = "Spot"
#  eviction_policy       = "Delete"
#  spot_max_price        = 0.1 # note: this is the "maximum" price
#  node_labels = {
#    "kubernetes.azure.com/scalesetpriority" = "spot"
#  }
#  node_taints = [
#    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
#  ]
#  tags = {
#    environment = var.environment
#  }
#}
#
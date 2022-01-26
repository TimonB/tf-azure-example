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


# Create a resource group 
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


# Create Subnet for k8s nodes
resource "azurerm_subnet" "k8s" {
  name                 = "k8s"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.2.0/24"]
}




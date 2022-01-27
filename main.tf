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


# Create DNS Zone
resource "azurerm_dns_zone" "example-public" {
  name                = "azure.birk.cloud"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  tags = {
    environment = var.environment
  }
}
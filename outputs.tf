output "connection_string_actions" {
  description = "Storage Account Connection String for Actions"
  value       = nonsensitive(azurerm_storage_account.ghesstorageaccountaction.primary_connection_string)
}

output "connection_string_repos" {
  description = "Storage Account Connection String for Repository Storage"
  value       = nonsensitive(azurerm_storage_account.ghesstorageaccountrepo.primary_connection_string)
}

output "public_ip_ghes" {
  value       = azurerm_public_ip.ghespublicip.ip_address
  description = "The ip address of the GitHub Enterprise Server instance"
}
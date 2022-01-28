#
# GitHub Enterprise Server
#
#


variable "ghes-version" {
  type    = string
  default = "3.0.23"
}

variable "username" {
  type    = string
  default = "ghadmin"
}


# Create public IPs
resource "azurerm_public_ip" "ghespublicip" {
  name                = "ghesPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Static"

  tags = {
    version = var.environment
  }
}
# ToDo: add Loadbalancer

# Add security rules
resource "azurerm_network_security_group" "ghessecgroup" {
  name                = "ghes-security-group"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
}

resource "azurerm_network_security_rule" "ghes-secrules" {
  name                        = "ghes-security-rules"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  destination_port_ranges     = ["22", "25", "80", "122", "443", "8080", "8443", "9418"]
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.myterraformgroup.name
  network_security_group_name = azurerm_network_security_group.ghessecgroup.name
}


resource "azurerm_network_interface" "ghesnic" {
  name                = "ghesnic"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ghespublicip.id
  }

  tags = {
    version = var.environment
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "ghes-sec-assoc" {
  network_interface_id      = azurerm_network_interface.ghesnic.id
  network_security_group_id = azurerm_network_security_group.ghessecgroup.id
}




resource "azurerm_virtual_machine" "ghes-test" {
  name                  = "ghes-vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.myterraformgroup.name
  network_interface_ids = [azurerm_network_interface.ghesnic.id]
  vm_size               = "Standard_DS11_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  # Getting the available VM templates
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
  location             = var.location
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
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


#
# Add DNS Record for GHES
#

resource "azurerm_dns_a_record" "ghes-dns" {
  name                = "github"
  zone_name           = azurerm_dns_zone.example-public.name
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.ghespublicip.id
}


#
# Storage for GHES - Repository
# Needed as stroage backend or GitHub Actions: 
# https://docs.github.com/en/enterprise-server@3.3/admin/packages/enabling-github-packages-with-azure-blob-storage
#

resource "azurerm_storage_account" "ghesstorageaccountrepo" {
  name                     = "ghesstorageaccountrepo"
  resource_group_name      = azurerm_resource_group.myterraformgroup.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "ghesrepos" {
  name                  = "ghesrepos"
  storage_account_name  = azurerm_storage_account.ghesstorageaccountrepo.name
  container_access_type = "private"
}


#
# Storage for GHES - GitHub Actions
# Needed as stroage backend or GitHub Actions: 
# https://docs.github.com/en/enterprise-server@3.3/admin/github-actions/enabling-github-actions-for-github-enterprise-server/enabling-github-actions-with-azure-blob-storage
#

resource "azurerm_storage_account" "ghesstorageaccountaction" {
  name                     = "ghesstorageaccountaction"
  resource_group_name      = azurerm_resource_group.myterraformgroup.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "ghesactions" {
  name                  = "ghesactions"
  storage_account_name  = azurerm_storage_account.ghesstorageaccountaction.name
  container_access_type = "private"
}

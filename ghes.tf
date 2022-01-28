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

resource "azurerm_public_ip" "ghes-lb-public" {
  name                = "publicIPForGHESLB"
  location            = var.location
  sku                 = "Standard"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "ghes-lb" {
  name                = "loadBalancer"
  location            = var.location
  sku                 = "Standard"
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  frontend_ip_configuration {
    name                 = "publicIPAddress"
    public_ip_address_id = azurerm_public_ip.ghes-lb-public.id
  }
}

resource "azurerm_lb_backend_address_pool" "ghes-lb-backend" {
  loadbalancer_id = azurerm_lb.ghes-lb.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_rule" "web" {
  resource_group_name            = azurerm_resource_group.myterraformgroup.name
  loadbalancer_id                = azurerm_lb.ghes-lb.id
  name                           = "HTTPS"
  protocol                       = "TCP"
  frontend_port                  = 443
  backend_port                   = 443
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.ghes-lb-backend.id]
  frontend_ip_configuration_name = "publicIPAddress"
}

resource "azurerm_lb_rule" "mgmnt" {
  resource_group_name            = azurerm_resource_group.myterraformgroup.name
  loadbalancer_id                = azurerm_lb.ghes-lb.id
  name                           = "Management"
  protocol                       = "TCP"
  frontend_port                  = 8443
  backend_port                   = 8443
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.ghes-lb-backend.id]
  frontend_ip_configuration_name = "publicIPAddress"
}

resource "azurerm_lb_rule" "ssh-mgmnt" {
  resource_group_name            = azurerm_resource_group.myterraformgroup.name
  loadbalancer_id                = azurerm_lb.ghes-lb.id
  name                           = "SSHManagement"
  protocol                       = "TCP"
  frontend_port                  = 122
  backend_port                   = 122
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.ghes-lb-backend.id]
  frontend_ip_configuration_name = "publicIPAddress"
}


resource "azurerm_lb_probe" "ssh" {
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  loadbalancer_id     = azurerm_lb.ghes-lb.id
  name                = "ssh-running-probe"
  port                = 22
}


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


resource "azurerm_lb_backend_address_pool_address" "ghes-test-member" {
  name                    = "ghes-server1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ghes-lb-backend.id
  virtual_network_id      = azurerm_virtual_network.myterraformnetwork.id
  ip_address              = azurerm_network_interface.ghesnic.private_ip_address
}

#
# Add DNS Record for GHES
#

resource "azurerm_dns_a_record" "ghes-dns" {
  name                = "github"
  zone_name           = azurerm_dns_zone.example-public.name
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.ghes-lb-public.id
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

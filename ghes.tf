#
# GitHub Enterprise Server
#
#



# Create public IPs
resource "azurerm_public_ip" "ghespublicip" {
  name                = "ghesPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Dynamic"

  tags = {
    version = var.ghes-version
  }
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
    version = var.ghes-version
  }
}

resource "azurerm_virtual_machine" "ghes-test" {
  name                  = "ghes-vm"
  location              = var.location
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


output "public_ip" {
  value       = azurerm_public_ip.ghespublicip.ip_address
  description = "The IP address of the GitHub Enterprise Server instance"
}


resource "azurerm_dns_a_record" "ghes-dns" {
  name                = "github"
  zone_name           = azurerm_dns_zone.azurerm_dns_zone.example-public.name
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.ghespublicip.id
}
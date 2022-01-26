# AKS Kubernetes
# Examples see https://github.com/hashicorp/terraform-provider-azurerm/tree/main/examples/kubernetes

resource "azurerm_kubernetes_cluster" "dev-k8s" {
  name                = "dev-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  dns_prefix          = "dev-aks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    node_labels = {
      "rootuser.net/performancelevel" = "slow"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "Standard"
  }

  tags = {
    environment = var.environment
  }
}


resource "azurerm_kubernetes_cluster_node_pool" "windows-nodepool" {
  name                  = "windows-pool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
  vm_size               = "Standard_D2_v2"
  os_type               = Windows
  node_count            = 1
  priority              = "Spot"
  eviction_policy       = "Delete"
  #  spot_max_price        = 0.1 # note: this is the "maximum" price
  node_labels = {
    "kubernetes.azure.com/scalesetpriority" = "spot"
    "rootuser.net/os"                       = "windows"
  }
  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
  ]
  tags = {
    environment = var.environment
  }
}
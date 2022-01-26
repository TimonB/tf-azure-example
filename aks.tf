# AKS Kubernetes
# Examples see https://github.com/hashicorp/terraform-provider-azurerm/tree/main/examples/kubernetes

resource "azurerm_kubernetes_cluster" "dev-k8s" {
  name                = "dev-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  dns_prefix          = "dev-aks"
  # Get available aks versions and possbible upgrade:
  # az aks get-versions --location germanywestcentral  --output table
  kubernetes_version = "1.22.2"
  default_node_pool {
    name                 = "default"
    node_count           = 1
    vm_size              = "Standard_D2_v2"
    vnet_subnet_id       = azurerm_subnet.k8s.id
    orchestrator_version = "1.21.7"
    node_labels = {
      "rootuser.net/performancelevel" = "slow"
      "rootuser.net/os"               = "linux"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    load_balancer_sku  = "Standard"
    service_cidr       = "10.2.0.0/24"
    dns_service_ip     = "10.2.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  tags = {
    environment = var.environment
  }
}


resource "azurerm_kubernetes_cluster_node_pool" "windows-nodepool" {
  name                  = "win"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.dev-k8s.id
  vm_size               = "Standard_D2_v2"
  os_type               = "Windows"
  node_count            = 1
  priority              = "Spot"
  eviction_policy       = "Delete"
  #  spot_max_price        = 0.1 # note: this is the "maximum" price
  node_labels = {
    "kubernetes.azure.com/scalesetpriority" = "spot"
    "rootuser.net/os"                       = "windows"
  }

  orchestrator_version = "1.22.2"
  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
  ]
  vnet_subnet_id = azurerm_subnet.k8s.id
  tags = {
    environment = var.environment
  }
}
# AKS cluster configurations
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.cluster_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
  dns_prefix          = lower(var.cluster_name)
  kubernetes_version  = var.cluster_version
  node_resource_group = "${var.cluster_name}-ng"

  default_node_pool {
    name    = var.node_pool_name
    vm_size = var.vm_type
    node_count = var.node_count
    zones               = var.node_pool_availability_zones
    enable_auto_scaling = true
    max_count           = var.node_group_max_size
    min_count           = var.node_group_min_size
    os_disk_size_gb     = var.node_disk_size
    node_labels         = var.common_tags
    tags                = var.common_tags
  }

  identity {
    type = "SystemAssigned"
  }

}


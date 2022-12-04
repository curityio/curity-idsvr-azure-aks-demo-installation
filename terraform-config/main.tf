provider "azurerm" {
  skip_provider_registration = "true"
  features {}
}

module "aks_cluster" {
  source                       = "./modules/aks-cluster/"
  resource_group_name          = var.resource_group_name
  cluster_name                 = var.cluster_name
  cluster_version              = var.cluster_version
  node_pool_name               = var.node_pool_name
  node_count                   = var.node_count
  vm_type                      = var.vm_type
  node_pool_availability_zones = var.node_pool_availability_zones
  node_disk_size               = var.node_disk_size
  node_group_max_size          = var.node_group_max_size
  node_group_min_size          = var.node_group_min_size
  common_tags                  = var.common_tags

}

module "curity_idsvr" {
  source                 = "./modules/curity-idsvr/"
  idsvr_namespace        = var.idsvr_namespace
  host                   = module.aks_cluster.host
  client_certificate     = base64decode(module.aks_cluster.client_certificate)
  client_key             = base64decode(module.aks_cluster.client_key)
  cluster_ca_certificate = base64decode(module.aks_cluster.cluster_ca_certificate)

}

module "example_api" {
  source                 = "./modules/example-api/"
  api_namespace          = var.api_namespace
  host                   = module.aks_cluster.host
  client_certificate     = base64decode(module.aks_cluster.client_certificate)
  client_key             = base64decode(module.aks_cluster.client_key)
  cluster_ca_certificate = base64decode(module.aks_cluster.cluster_ca_certificate)

}

module "ingress_nginx" {
  source                       = "./modules/ingress-nginx/"
  ingress_controller_namespace = var.ingress_controller_namespace
  host                         = module.aks_cluster.host
  client_certificate           = base64decode(module.aks_cluster.client_certificate)
  client_key                   = base64decode(module.aks_cluster.client_key)
  cluster_ca_certificate       = base64decode(module.aks_cluster.cluster_ca_certificate)
  ingress_nginx_depends_on_1 =  module.curity_idsvr.dependency_provider_curity
  ingress_nginx_depends_on_2 =  module.example_api.dependency_provider_api
  
}

output "name" {
  value       = azurerm_kubernetes_cluster.aks_cluster.name
  description = "Specifies the name of the AKS cluster."
}

output "id" {
  value       = azurerm_kubernetes_cluster.aks_cluster.id
  description = "Specifies the resource id of the AKS cluster."
}


output "kube_config_raw" {
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  description = "Contains the Kubernetes config to be used by kubectl and other compatible tools."
}


output "client_certificate" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate
  description = "Base64 encoded public certificate used by clients to authenticate to the Kubernetes cluster"
}

output "client_key" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key
  description = "Base64 encoded private key used by clients to authenticate to the Kubernetes cluster"
}

output "cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate
  description = "Base64 encoded public CA certificate used as the root of trust for the Kubernetes cluster"
}

output "host" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host
  description = "The Kubernetes cluster server host"
}

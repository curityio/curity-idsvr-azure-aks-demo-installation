# Example API deployment configurations
terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

provider "kubectl" {
  host                   = var.host
  client_certificate     = var.client_certificate
  client_key             = var.client_key
  cluster_ca_certificate = var.cluster_ca_certificate
}

provider "kubernetes" {
  host                   = var.host
  client_certificate     = var.client_certificate
  client_key             = var.client_key
  cluster_ca_certificate = var.cluster_ca_certificate
}

resource "kubernetes_namespace" "api_ns" {
  metadata {
    name = var.api_namespace
  }
}


resource "kubernetes_secret_v1" "api-example-eks-tls" {
  metadata {
    name      = "example-aks-tls"
    namespace = kubernetes_namespace.api_ns.metadata.0.name
  }
  data = {
    "tls.crt" = file("${path.cwd}/../certs/example.aks.ssl.pem")
    "tls.key" = file("${path.cwd}/../certs/example.aks.ssl.key")
  }

  type = "kubernetes.io/tls"
}


resource "kubectl_manifest" "example_api_deployment" {
  yaml_body          = file("${path.cwd}/../example-api-config/example-api-k8s-deployment.yaml")
  override_namespace = kubernetes_namespace.api_ns.metadata.0.name
}


resource "kubectl_manifest" "example_api_ingress_rules_deployment" {
  yaml_body          = file("${path.cwd}/../example-api-config/example-api-ingress-nginx.yaml")
  override_namespace = kubernetes_namespace.api_ns.metadata.0.name
}

resource "kubectl_manifest" "example_api_svc_deployment" {
  yaml_body          = file("${path.cwd}/../example-api-config/example-api-k8s-service.yaml")
  override_namespace = kubernetes_namespace.api_ns.metadata.0.name

}


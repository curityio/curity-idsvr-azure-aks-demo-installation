# NGINX IC Deployment
provider "helm" {
  kubernetes {
    host                   = var.host
    client_certificate     = var.client_certificate
    client_key             = var.client_key
    cluster_ca_certificate = var.cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = var.host
  client_certificate     = var.client_certificate
  client_key             = var.client_key
  cluster_ca_certificate = var.cluster_ca_certificate
}

resource "kubernetes_namespace" "ingress_ns" {
  metadata {
    name = var.ingress_controller_namespace
  }
}


resource "helm_release" "ingress-nginx" {
  name = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_ns.metadata.0.name

  values = [
    file("${path.cwd}/../ingress-nginx-config/helm-values.yaml")
  ]

  depends_on = [
    var.ingress_nginx_depends_on_1,
    var.ingress_nginx_depends_on_2
  ]

}

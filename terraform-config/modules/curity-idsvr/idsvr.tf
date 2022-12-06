# Curity Idsvr deployment configurations
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


resource "kubernetes_namespace" "curity_ns" {
  metadata {
    name = var.idsvr_namespace
  }
}

resource "kubernetes_secret_v1" "idsvr_config" {
  metadata {
    name      = "idsvr-config"
    namespace = kubernetes_namespace.curity_ns.metadata.0.name
  }
  data = {
    "idsvr-cluster-config.xml" = file("${path.cwd}/../idsvr-config/idsvr-cluster-config.xml")
    "license.json"             = file("${path.cwd}/../idsvr-config/license.json")
  }
}


resource "kubernetes_secret_v1" "curity-example-eks-tls" {
  metadata {
    name      = "example-aks-tls"
    namespace = kubernetes_namespace.curity_ns.metadata.0.name
  }
  data = {
    "tls.crt" = file("${path.cwd}/../certs/example.aks.ssl.pem")
    "tls.key" = file("${path.cwd}/../certs/example.aks.ssl.key")
  }

  type = "kubernetes.io/tls"
}


resource "helm_release" "curity_idsvr" {
  name = "curity"

  repository = "https://curityio.github.io/idsvr-helm/"
  chart      = "idsvr"
  namespace  = kubernetes_namespace.curity_ns.metadata.0.name

  values = [
    file("${path.cwd}/../idsvr-config/helm-values.yaml")
  ]

}


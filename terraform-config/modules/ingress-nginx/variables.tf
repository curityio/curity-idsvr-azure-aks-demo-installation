variable "ingress_controller_namespace" {
  description = "Name of the k8s namespace to deploy NGINX Ingress Controller"
  type        = string
}

variable "host" {
  description = "The Kubernetes cluster server host"
  type        = string
}

variable "client_certificate" {
  description = "Base64 encoded public certificate used by clients to authenticate to the Kubernetes cluster"
  type        = string
}

variable "client_key" {
  description = "Base64 encoded private key used by clients to authenticate to the Kubernetes cluster"
  type        = string
  sensitive = true
}

variable "cluster_ca_certificate" {
  description = "Base64 encoded public CA certificate used as the root of trust for the Kubernetes cluster"
  type        = string
}

variable "ingress_nginx_depends_on_1" {
  # The value is not important because we're just using this for creating dependencies
  type    = string
}

variable "ingress_nginx_depends_on_2" {
  # The value is not important because we're just using this for creating dependencies
  type    = string
}
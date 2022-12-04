variable "resource_group_name" {
  description = "Name of the resource group in Azure"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "AKS cluster version number"
  type        = string
}

variable "node_pool_name" {
  description = "Name of the nodepool"
  type        = string
}

variable "node_pool_availability_zones" {
  description = "Specifies the availability zones of the default node pool"
  default     = ["1", "2"]
  type        = list(string)
}
variable "vm_type" {
  description = "Type of VM to be used to create AKS cluster"
  type        = string
}

variable "node_disk_size" {
  description = "Disk size of the AKS node"
  type        = number

}

variable "node_count" {
  description = "Nodes count"
  type        = number
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the nodegroup"
  type        = number

}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the nodegroup"
  type        = number

}

variable "common_tags" {
  description = "tags"
  type        = map(string)
}

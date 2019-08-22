variable "eks_cluster_name" {
  description = "The name of all EKS resources"
  default     = "Staging-eks-cluster"
}

variable "region_name" {
  default = "eu-central-1"
}

variable "key_name" {}

variable "key_value" {}

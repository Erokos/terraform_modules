variable "eks_cluster_name" {
  description = "The name for all cluster resources"
}

variable "eks_private_subnets" {
  description = "List of EKS cluster private subnets"
  type        = "list"
}

variable "eks_public_subnets" {
  description = "List of EKS public subnets"
  type        = "list"
}

variable "vpc_id" {
  description = "The ID of the VPC the cluster is deployed in"
}

variable "source_security_group_id" {
  description = "The ID of the VPC default security group"
}

variable "k8s_node_label" {
  description = "The label on the EKS worker nodes"
}

variable "vpc_security_group_ids" {
  description = "ID of the VPC security group"
}

variable "use_latest_eks_ami" {
  description = "Set to true if you want to use the latest AMI"
  default     = true
}

variable "eks_ami_id" {
  description = "The AMI ID used on the EKS worker nodes"
}



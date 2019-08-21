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

variable "k8s_node_label" {
  description = "The label on the EKS worker nodes"
}

variable "source_security_group_id" {
  description = "The ID of the VPC security group"
}

variable "vpc_security_group_ids" {
  description = "ID of the EKS Instance security group"
  type        = "list"
}

variable "use_latest_eks_ami" {
  description = "Set to true if you want to use the latest AMI"
  default     = true
}

variable "eks_ami_id" {
  description = "The AMI ID used on the EKS worker nodes"
  default     = "ami-091fc251b67b776c3"
}

variable "vpc_zone_identifier" {
  description = "List of subnets in which the Instances will be deployed and scaled"
  type        = "list"
}

variable "max_size" {
  description = "The max size of the cluster"
}

variable "min_size" {
  description = "The minimum size of the cluster"
}

variable "desired_capacity" {
  description = "The desired numbar of Instances for your cluster"
}

variable "on_demand_base_capacity" {
  description = "The number of on demand Instances to start with"
}

variable "on_demand_percentage_above_base_capacity" {
  description = "The percentage of scaled Instances that are on demand"
}

variable "instance_type_pool1" {
  description = "The first instance type pool in which to look for Instances"
}

variable "instance_type_pool2" {
  description = "The second instance type pool in which to look for Instances"
}

variable "instance_type_pool3" {
  description = "The third instance type pool in which to look for Instances"
}

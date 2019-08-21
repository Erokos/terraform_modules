variable "eks_cluster_name" {
  description = "The name for all cluster resources"
}

variable "region_name" {
  description = "The region in which all the resources are deployed"
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

variable "use_latest_eks_ami" {
  description = "Set to true if you want to use the latest AMI"
  default     = true
}

variable "eks_ami_id" {
  description = "The AMI ID used on the EKS worker nodes"
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

variable "key_name" {
  description = "The name of the SSH key used to gain access to the worker and bastion Instances"
}

variable "key_value" {
  description = "The public value of the SSH key used to gain access to the Instances"
}

variable "enable_bastion" {
  description = "If set to true, creates a bastion host and its network resources in a public subnet"
}

variable "allowed_ssh_cidr" {
  description = "A list of CIDR Networks to allow ssh access to."
  default = [
    "0.0.0.0/0",
  ]
}

variable "kubectl_eks_link" {
  description = "Specifies the kubectl version installed on the bastion host. Must be within one minor version difference of your Amazon EKS cluster control plane"
  default     = "https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/kubectl"
}

variable "iam_eks_link" {
  description = "Specifies the aws-iam-authenticator download link"
  default     = "https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/aws-iam-authenticator"
}

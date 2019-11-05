variable "eks_cluster_name" {
  description = "The name for all cluster resources"
  default     = "Testing-cluster"
}

variable "region_name" {
  description = "The region in which all the resources are deployed"
  default     = "eu-west-1"
}

variable "eks_worker_subnets" {
  description = "List of EKS subnets to place the workers in"
  type        = "list"
}

#variable "eks_public_subnets" {
#  description = "List of EKS public subnets"
#  type        = "list"
#}

variable "vpc_id" {
  description = "The ID of the VPC the cluster is deployed in"
}

variable "source_security_group_id" {
  description = "The ID of the VPC security group"
}

variable "vpc_zone_identifier" {
  description = "List of subnets in which the Instances will be deployed and scaled"
  type        = "list"
}
variable "bastion_vpc_zone_identifier" {
  description = "List of subnets in which the bastion Instances will be deployed"
  type        = "list"
}

variable "bastion_max_size" {
  description = "The max number of bastion Instances"
  default     = "2"
}

variable "bastion_min_size" {
  description = "The minimum number of bastion Instances"
  default     = "1"
}

#variable "desired_capacity" {
#  description = "The desired numbar of Instances for your cluster"
#  default     = "1"
#}

variable "bastion_desired_capacity" {
  description = "The desired number of bastion Instances"
  default     = "1"
}

variable "worker_launch_template_mixed_count" {
  description = "The number of maps in the worker_launch_template_lst list"
  default     = "0"
}

variable "worker_launch_template_lst" {
  description = "A list of maps defining worker instance group configurations to be defined using launch templates with mixed instance policy. See worker_lt_defaults in locals.tf for valid keys."
  type        = "list"

  default = [
    {
      "name" = "default"
    },
  ]
}

variable "tags" {
  description = "A map of tags to add to all resources."  
  type        = "map"
  default     = {}
}

variable "worker_security_group_id" {
  description = "If provided, all workers will be attached tothis security group. If not, a sg will be created correctly to work with the cluster"
  default     = ""
}

variable "key_name" {
  description = "The name of the SSH key used to gain access to the worker and bastion Instances"
  default     = ""
}

variable "key_value" {
  description = "The public value of the SSH key used to gain access to the Instances"
  default     = ""
}

variable "enable_bastion" {
  description = "If set to true, creates a bastion host and its network resources in a public subnet"
  default     = true
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
  default     = "https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator"
}

variable "cni_link" {
  description = "Specifies the link to the CNI kubernetes files"
  default     = "https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.5.3/config/v1.5/aws-k8s-cni.yaml"
}

variable "cluster_kubernetes_version" {
  description = "Specifies the version of kubernetes for API plane"
  default     = "1.13"
}

variable "endpoint_private_access" {
  description = "Specifies whether or not the Amazon EKS private API server endpoint is enabled. Default is false."
  default     = false
}

variable "endpoint_public_access" {
  description = "whether or not the Amazon EKS public API server endpoint is enabled. Default is true."
  default     = true
}

variable "bastion_name" {
  description = "The name of the bastion host resource"
  default     = "bastion-test"
}

variable "bastion_instance_type" {
  description = "The Instance type of the bastion host"
  default     ="t2.micro"
}

variable "aws_access_key" {
  description = "The access key for your AWS account"
  default     = ""
}

variable "aws_secret_access_key" {
  description = "The secret access key for your AWS account"
  default     = ""
}

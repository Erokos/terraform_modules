provider "aws" {
  region = var.region_name
}

module "eks_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v1.67.0"

  name = "eks-staging-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  private_subnets = ["10.0.0.0/18", "10.0.64.0/18"]
  public_subnets  = ["10.0.128.0/18", "10.0.192.0/18"]

  enable_nat_gateway = true
  single_nat_gateway = true

  #  reuse_nat_ips        = "${var.eks-reuse-eip}"
  enable_vpn_gateway = false

  #  external_nat_ip_ids  = ["${var.eks-nat-fixed-eip}"]
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = terraform.workspace
    # Required for EKS and Kubernetes to discover and manage networking resources
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  security_group_id = module.eks_vpc.default_security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "eks_vpc_allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  security_group_id = module.eks_vpc.default_security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
}

module "eks" {
  #source                             = "git::ssh://git@gl.sds.rocks/GDNI/terraform-modules.git//eks?ref=v0.0.3"
  source                             = "../../../../terraform-modules//eks?ref=v0.0.3"
  eks_cluster_name                   = "personalization-test-cluster"
  region_name                        = var.region_name
  source_security_group_id           = module.eks_vpc.default_security_group_id
  vpc_id                             = module.eks_vpc.vpc_id
  vpc_zone_identifier                = module.eks_vpc.private_subnets
  worker_launch_template_mixed_count = 2
  cluster_kubernetes_version         = "1.13"
  eks_ami_version                    = "1.13"
  bastion_vpc_zone_identifier        = module.eks_vpc.public_subnets
  bastion_after_workers_lt           = true
  eks_worker_subnets                 = module.eks_vpc.private_subnets
  key_name                           = var.key_name
  key_value                          = var.key_value
  pvt_key                            = "my_pvt_key"

  #kubectl_eks_link                   = "https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/kubectl"
  aws_access_key        = "your_access_key"
  aws_secret_access_key = "your_secret_key"

  worker_launch_template_lst = [
    {
      name                 = "general-purpose"
      instance_type        = "t3.large"
      spot_price           = ""
      asg_max_size         = 3
      asg_desired_capacity = 2
      kubelet_extra_args   = "lifecycle=spot,worker-type=general-purpose"
      enable_monitoring    = false
      key_name             = var.key_name
      key_value            = var.key_value
      ebs_optimized        = false
    },
    {
      name                 = "compute-optimized"
      instance_type        = "c5.large"
      asg_max_size         = 3
      asg_desired_capacity = 2
      kubelet_extra_args   = "lifecycle=spot,worker-type=compute-optimized"
      enable_monitoring    = false
      key_name             = var.key_name
      key_value            = var.key_value
      ebs_optimized        = false
    },
  ]
}


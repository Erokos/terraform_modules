provider "aws" {
  region = "${var.region_name}"
}

module "eks_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version              = "v1.67.0"

  name                 = "eks-staging-vpc"
  cidr                 = "10.0.0.0/16"

  azs                  = ["eu-central-1a", "eu-central-1b"]
  private_subnets      = ["10.0.0.0/18", "10.0.64.0/18"]
  public_subnets       = ["10.0.128.0/18", "10.0.192.0/18"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  
  #  reuse_nat_ips        = "${var.eks-reuse-eip}"
  enable_vpn_gateway   = false

  #  external_nat_ip_ids  = ["${var.eks-nat-fixed-eip}"]
  enable_dns_hostnames = true

  tags = {
    Terraform          = "true"
    Environment        = "${terraform.workspace}"
    # Required for EKS and Kubernetes to discover and manage networking resources
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  security_group_id = "${module.eks_vpc.default_security_group_id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "eks_vpc_allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  security_group_id = "${module.eks_vpc.default_security_group_id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

module "eks_cluster" {
  source = "../../eks"

  eks_cluster_name                         = "${var.eks_cluster_name}"
  region_name                              = "${var.region_name}"
  vpc_zone_identifier                      = "${module.eks_vpc.private_subnets}"
  enable_bastion                           = true
  bastion_name                             = "Staging-eks-bastion"
  bastion_instance_type                    = "t2.micro"
  bastion_vpc_zone_identifier              = "${module.eks_vpc.public_subnets}"
  vpc_id                                   = "${module.eks_vpc.vpc_id}"
  k8s_node_label                           = "lifecycle=spot"
  source_security_group_id                 = "${module.eks_vpc.default_security_group_id}"
  use_latest_eks_ami                       = false
  eks_ami_id                               = "ami-04341c15c2f941589"
  max_size                                 = 3
  min_size                                 = 1
  desired_capacity                         = 2
  on_demand_base_capacity                  = 1
  on_demand_percentage_above_base_capacity = 0
  bastion_max_size                         = 1
  bastion_min_size                         = 1
  bastion_desired_capacity                 = 1
  instance_type_pool1                      = "t2.micro"
  instance_type_pool2                      = "t3.nano"
  instance_type_pool3                      = "t3.micro"
  key_name                                 = "${var.key_name}"
  key_value                                = "${var.key_value}"
}


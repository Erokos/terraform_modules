#
# main EKS terraform resource definition
#
resource "aws_eks_cluster" "eks_cluster" {
  name         = "${var.eks_cluster_name}"

  role_arn     = "${aws_iam_role.eks_cluster.arn}"

  vpc_config {
    subnet_ids = ["${var.eks_private_subnets}"]
  }
}


# EKS service does not currently provide managed resources for running worker nodes
#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EC2 Security Group to allow networking traffic
#  * Data source to fetch latest EKS worker AMI or use a specific hardcoded AMI
#  * AutoScaling Launch Configuration to configure worker instances
#  * AutoScaling Group to launch worker instances
#

# First attach predefined policies but essential to EKS
#  * IAM role and policy to allow the worker nodes to manage or retrieve data from other AWS services
#  * Used by Kubernetes to allow worker nodes to join the cluster
data "aws_iam_policy_document" "eks_node_assume_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "eks_node_role" {
  name               = "${var.eks_cluster_name}-node-role"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.eks_node_assume_policy.json}"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.eks_node_role.name}"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.eks_node_role.name}"
}

resource "aws_iam_role_policy_attachment" "gdni_eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.eks_node_role.name}"
}

# Allow mutating the EKS Route53 hosted zone
data "aws_iam_policy_document" "eks_node_allow_route53" {
  statement {
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${aws_route53_zone.eks_private.zone_id}"
    ]
  }
  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "eks_node_allow_route53" {
  name = "eks_node_allow_route53"
  role = "${aws_iam_role.eks_node_role.id}"
  policy = "${data.aws_iam_policy_document.eks_node_allow_route53.json}"
} 

# Create a security group for worker nodes
#  * Special kubernetes tag is mandatory
resource "aws_security_group" "eks_node_sg" {
  name        = "${var.eks_cluster_name}-node-sg"
  description = "Security group for all nodes in the cluster"

  vpc_id = "${var.vpc_id}"

  tags = "${
    map(
     "Name", "${var.eks_cluster_name}-node-sg",
     "kubernetes.io/cluster/${var.eks_cluster_name}", "owned",
    )
  }"
}

# Allow all outbound traffic
resource "aws_security_group_rule" "allow_outbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.eks_node_sg.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Additional ingress rules
# * allows workers and the control plane to communicate with each other
resource "aws_security_group_rule" "eks_node_ingress_self" {
  description              = "Allow nodes to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.eks_node_sg.id}"
  source_security_group_id = "${aws_security_group.eks_node_sg.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_node_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${var.source_security_group_id}"
  source_security_group_id = "${module.eks_vpc.default_security_group_id}"
  to_port                  = 65535
  type                     = "ingress"
}

# Allow the worker nodes networking access to the EKS master cluster
resource "aws_security_group_rule" "eks_cluster_ingress_node_https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${var.source_security_group_id}"
  source_security_group_id = "${aws_security_group.eks_node_sg.id}"
  to_port                  = 443
  type                     = "ingress"
}

# EKS AMI data source
data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-*"]
  }

  filter {
      name   = "architecture"
      values = ["x86_64"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
data "template_file" "eks_node_userdata" {
  template = "${file("${path.module}/user-data.sh")}"

  vars {
      kubeconfig_cert_auth_data = "${aws_eks_cluster.eks_cluster.certificate_authority.0.data}"
      cluster_endpoint          = "${aws_eks_cluster.eks_cluster.endpoint}"
      cluster_name              = "${var.eks_cluster_name}"
      node_label                = "${var.k8s_node_label}"
  }
}

resource "aws_launch_template" "eks_worker_lt_latest_ami" {
  name                    = "${var.eks_cluster_name}-lt"
  disable_api_termination = false
  iam_instance_profile {
    name = "${aws_iam_instance_profile.gdni_eks_node.name}"
  }
  vpc_security_group_ids               = ["${var.vpc_security_group_ids}"]
  image_id                             = "${data.aws_ami.eks_worker.id}" # Using the latest AMI version
  instance_initiated_shutdown_behavior = "terminate"
  key_name                             = "${aws_key_pair.bastion.key_name}"
  
  user_data = "${base64encode(data.template_file.eks_node_userdata.rendered)}"
}

resource "aws_launch_template" "eks_worker_lt_fixed_ami" {
  name                    = "${var.eks_cluster_name}-lt"
  disable_api_termination = false
  iam_instance_profile {
    name = "${aws_iam_instance_profile.gdni_eks_node.name}"
  }
  vpc_security_group_ids               = ["${var.vpc_security_group_ids}"]
  image_id                             = "${var.eks_ami_id}" # Using a fixed version of kubectl 1.12.7 -> ami-091fc251b67b776c3
  instance_initiated_shutdown_behavior = "terminate"
  key_name                             = "${aws_key_pair.bastion.key_name}"
  
  user_data = "${base64encode(data.template_file.eks_node_userdata.rendered)}"
}

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

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.eks_node_role.name}"
}

resource "aws_iam_instance_profile" "eks_node_profile" {
  count        = "${var.worker_launch_template_mixed_count}"
  name_prefix  = "${var.eks_cluster_name}-node-profile"
  role         = "${aws_iam_role.eks_node_role.name}"
}

# 
# AWS IAM role for EKS service
#
data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = [
        "eks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.eks_cluster_name}-service-role"
  assume_role_policy = "${data.aws_iam_policy_document.eks_assume_role_policy.json}"
  path               = "/"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks_cluster.name}"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks_cluster.name}"
}

# 
# AWS IAM EKS role for Bastion host
#
data "aws_iam_policy_document" "bastion_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }  
}

data "aws_iam_policy_document" "bastion_eks_admin_policy" {
  statement {
    effect = "Allow"

    actions = [
      "eks:*",
      "iam:PutRolePolicy"  # required by kubeflow
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "bastion" {
  name               = "${var.bastion_name}"
  assume_role_policy = "${data.aws_iam_policy_document.bastion_assume_role_policy.json}"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.bastion_name}"
  role = "${aws_iam_role.bastion.name}"
}

resource "aws_iam_policy" "bastion" {
  name        = "${var.bastion_name}-eks-admin-policy"
  description = "Policy for EKS Bastion"
  policy      = "${data.aws_iam_policy_document.bastion_eks_admin_policy.json}"
}

resource "aws_iam_role_policy_attachment" "bastion" {
  policy_arn = "${aws_iam_policy.bastion.arn}"
  role       = "${aws_iam_role.bastion.name}"
}

resource "aws_iam_role_policy_attachment" "bastion_ecr_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.bastion.name}"
}

#
# SSH key for accessing the bastion and worker Instances
#

resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.key_name}"
  public_key = "${var.key_value}"
}

resource "null_resource" "tags_as_a_list_of_maps" {
  count = "${length(keys(var.tags))}"

  triggers = {
    key                 = "${element(keys(var.tags), count.index)}"
    value               = "${element(values(var.tags), count.index)}"
    propagate_at_launch = "true"
  }
}

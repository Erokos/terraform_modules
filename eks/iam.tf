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

resource "aws_iam_instance_profile" "eks_node_profile" {
  name = "${var.eks_cluster_name}-node-profile"
  role = "${aws_iam_role.eks_node_role.name}"
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

resource "aws_key_pair" "ssh_key" {
  key_name	    = "${var.key_name}"
  public_key	= "${var.key_value}"
}
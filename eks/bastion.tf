# Bastion Host Security Group
# Allow in traffic on 22 and out on 22 to the eks workers in the private subnets
resource "aws_security_group" "bastion_eks_sg" {
  count         = "${var.enable_bastion ? 1 : 0}"
  name          = "${var.eks_cluster_name}-bastion-sg"
  vpc_id        = "${var.vpc_id}"

  tags = {
      Name = "${var.eks_cluster_name}-bastion-sg"
  }
}

resource "aws_security_group_rule" "bastion_ingress" {
  description              = "Allow only SSH access from any CIDR"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = "${var.allowed_ssh_cidr}"
  security_group_id        = "${aws_security_group.bastion_eks_sg.0.id}"

  depends_on = [
    "aws_security_group.bastion_eks_sg"
  ]
}

resource "aws_security_group_rule" "bastion_egress" {
  description              = "Allow all outgoing traffic to the outside world"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = "${aws_security_group.bastion_eks_sg.0.id}"

  depends_on = [
    "aws_security_group.bastion_eks_sg"
  ]
}

data "template_file" "eks_bastion_userdata" {
  template = "${file("${path.module}/bastion-user-data.sh")}"

  vars {
      cluster_name              = "${var.eks_cluster_name}"
      region_name               = "${var.region_name}"
      kubectl_eks_link          = "${var.kubectl_eks_link}"
      iam_authenticator_link    = "${var.iam_eks_link}"
      cni_link                  = "${var.cni_link}"
      bastion_role_arn          = "${aws_iam_role.bastion.arn}"
      eks_node_role_arn         = "${aws_iam_role.eks_node_role.arn}"
      bastion_name              = "${var.bastion_name}"
      aws_access_key            = "${var.aws_access_key}"
      aws_secret_access_key     = "${var.aws_secret_access_key}"
  }
}

data "aws_ami" "aws_linux" {
  most_recent = true
  filter {
    name = "name"
    values = ["amzn-ami-hvm-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # aws
}

# Bastion Launch Configuration and ASG
resource "aws_launch_configuration" "bastion_eks_lc" {
  count                = "${var.enable_bastion ? 1 : 0}"
  image_id             = "${data.aws_ami.aws_linux.image_id}"
  instance_type        = "${var.bastion_instance_type}"
  key_name             = "${aws_key_pair.ssh_key.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.bastion.arn}"
  security_groups      = ["${aws_security_group.bastion_eks_sg.0.id}"]
  user_data_base64     = "${base64encode(data.template_file.eks_bastion_userdata.rendered)}"

  lifecycle {
      create_before_destroy = true
  }

  depends_on = [
      "aws_security_group.bastion_eks_sg"
  ]
}

resource "aws_autoscaling_group" "bastion_eks_asg" {
  name                 = "${aws_launch_configuration.bastion_eks_lc.0.name}-eks-asg"
  launch_configuration = "${aws_launch_configuration.bastion_eks_lc.0.name}"
  min_size             = "${var.bastion_min_size}"
  desired_capacity	   = "${var.bastion_desired_capacity}"
  max_size             = "${var.bastion_max_size}"
  vpc_zone_identifier  = ["${var.bastion_vpc_zone_identifier}"]

  lifecycle {
      create_before_destroy = true
  }
  depends_on = [
      "aws_launch_configuration.bastion_eks_lc",
      "aws_eks_cluster.eks_cluster",
      "aws_autoscaling_group.eks_mixed_instances_asg"
  ]
}

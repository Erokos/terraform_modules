# Bastion Host Security Group
# Allow in traffic on 22 and out on 22 to the eks workers in the private subnets
resource "aws_security_group" "bastion_eks_sg" {
    name          = "${var.eks_cluster_name}-bastion-sg"
    vpc_id        = "${module.eks_vpc.vpc_id}"

  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "${var.allowed_ssh_cidr}"
  }
  
  # Allow all outgoing traffic to the outside world
  egress {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["0.0.0.0/0"]
  }

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
  security_group_id        = "${aws_security_group.bastion_eks_sg.id}"
}

resource "aws_security_group_rule" "bastion_egress" {
  description              = "Allow all outgoing traffic to the outside world"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = "${aws.aws_security_group.bastion_eks_sg.id}"
}

data "template_file" "eks_bastion_userdata" {
  template = "${file("${path.module}/bastion-user-data.sh")}"

  vars {
      cluster_name              = "${var.eks_cluster_name}"
      region_name               = "${var.region_name}"
      kubectl_eks_link          = "${var.kubectl_eks_link}"
      iam_authenticator_link    = "${var.iam_eks_link}"
  }
}
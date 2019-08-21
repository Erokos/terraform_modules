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
#  * AutoScaling Launch Template to configure worker instances
#  * AutoScaling Group with a mixed Instances policy to launch worker Instances
#

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
  security_group_id        = "${aws_security_group.eks_node_sg.id}"
  source_security_group_id = "${var.source_security_group_id}"
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
  count = "${var.use_latest_eks_ami}"


  name                    = "${var.eks_cluster_name}-lt"
  disable_api_termination = false
  iam_instance_profile {
    name = "${aws_iam_instance_profile.eks_node_profile.name}"
  }
  vpc_security_group_ids               = ["${var.vpc_security_group_ids}"]
  image_id                             = "${data.aws_ami.eks_worker.id}" # Using the latest AMI version
  instance_initiated_shutdown_behavior = "terminate"
  key_name                             = "${aws_key_pair.bastion.key_name}"
  
  user_data = "${base64encode(data.template_file.eks_node_userdata.rendered)}"
}

resource "aws_launch_template" "eks_worker_lt_fixed_ami" {
  count = "${1 - var.use_latest_eks_ami}"


  name                    = "${var.eks_cluster_name}-lt"
  disable_api_termination = false
  iam_instance_profile {
    name = "${aws_iam_instance_profile.eks_node_profile.name}"
  }
  vpc_security_group_ids               = ["${var.vpc_security_group_ids}"]
  image_id                             = "${var.eks_ami_id}" # Using a fixed version of kubectl 1.12.7 -> ami-091fc251b67b776c3
  instance_initiated_shutdown_behavior = "terminate"
  key_name                             = "${aws_key_pair.bastion.key_name}"
  
  user_data = "${base64encode(data.template_file.eks_node_userdata.rendered)}"
}

resource "aws_autoscaling_group" "eks_mixed_instances_asg" {
  max_size             = "${var.max_size}"
  desired_capacity     = "${var.desired_capacity}"
  min_size             = "${var.min_size}"
  name                 = "${var.eks_cluster_name}-asg"
  vpc_zone_identifier = ["${var.vpc_zone_identifier}"] # private subnets to which a bastion host is connected
  
  # This setting will guarantee 1 "On-Demand" instance at all times and scale using Spot Instances
  # from pools listed below in the order specified
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity = "${var.on_demand_base_capacity}"
      on_demand_percentage_above_base_capacity = "${var.on_demand_percentage_above_base_capacity}"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = "${element(concat(aws_launch_template.eks_worker_lt_fixed_ami.*.id, aws_launch_template.eks_worker_lt_latest_ami.*.id), 0)}"
        version = "$$Latest"
      }

      override {
        instance_type = "${var.instance_type_pool1}"
      }

      override {
        instance_type = "${var.instance_type_pool2}"
      }

      override {
        instance_type = "${var.instance_type_pool3}"
      }
    }
  }

  tag {
    key                 = "${var.eks_cluster_name}-mixed-instances-asg"
    value               = "${var.eks_cluster_name}-worker-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.eks_cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

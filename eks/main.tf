#
# main EKS terraform resource definition
#
resource "aws_eks_cluster" "eks_cluster" {
  name         = "${var.eks_cluster_name}"

  role_arn     = "${aws_iam_role.eks_cluster.arn}"
  version      = "${var.cluster_kubernetes_version}"

  vpc_config {
    subnet_ids = ["${var.vpc_zone_identifier}"]
    endpoint_private_access = "${var.endpoint_private_access}"
    endpoint_public_access  = "${var.endpoint_public_access}"
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
    values = ["amazon-eks-node-${var.cluster_kubernetes_version}-${var.worker_ami_name_filter}"]
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
  count = "${var.worker_launch_template_mixed_count}"
  template = "${file("${path.module}/user-data.sh")}"

  vars {
      kubeconfig_cert_auth_data = "${aws_eks_cluster.eks_cluster.certificate_authority.0.data}"
      cluster_endpoint          = "${aws_eks_cluster.eks_cluster.endpoint}"
      cluster_name              = "${var.eks_cluster_name}"
      node_label                = "${lookup(var.worker_launch_template_lst[count.index], "kubelet_extra_args", local.worker_lt_defaults["kubelet_extra_args"])}"
  }
}

resource "aws_launch_template" "eks_worker_lt_mixed" {
  count = "${var.worker_launch_template_mixed_count}"

  name                    = "${var.eks_cluster_name}-${lookup(var.worker_launch_template_lst[count.index], "name", count.index)}-lt"
  disable_api_termination = "${lookup(var.worker_launch_template_lst[count.index], "disable_api_termination", local.worker_lt_defaults["disable_api_termination"])}"

  iam_instance_profile {
    name = "${element(aws_iam_instance_profile.eks_node_profile.*.name, count.index)}"
  }

  #network_interfaces {
  #  associate_public_ip_address = "${lookup(var.worker_launch_template_lst[count.index], "public_ip", local.worker_lt_defaults["public_ip"])}"
  #  delete_on_termination       = "${lookup(var.worker_launch_template_lst[count.index], "delete_eni", local.worker_lt_defaults["delete_eni"])}"
  #  #security_groups             = ["${local.worker_security_group_id}"]
  #}

  monitoring {
    enabled = "${lookup(var.worker_launch_template_lst[count.index], "enable_monitoring", local.worker_lt_defaults["enable_monitoring"])}"
  }

  placement {
    tenancy = "${lookup(var.worker_launch_template_lst[count.index], "placement_tenancy", local.worker_lt_defaults["placement_tenancy"])}"
  }

  vpc_security_group_ids               = ["${aws_security_group.eks_node_sg.id}"]
  image_id                             = "${lookup(var.worker_launch_template_lst[count.index], "eks_ami_id", local.worker_lt_defaults["eks_ami_id"])}}" # ami-091fc251b67b776c3, for 1.13.11, for 1.14.7: ami-059c6874350e63ca9
  #image_id                             = "ami-0c5d8b180f6256839"
  user_data                            = "${base64encode(element(data.template_file.eks_node_userdata.*.rendered, count.index))}"
  instance_initiated_shutdown_behavior = "${lookup(var.worker_launch_template_lst[count.index], "instance_shutdown_behavior", local.worker_lt_defaults["instance_shutdown_behavior"])}" # defaults to stop
  key_name                             = "${aws_key_pair.ssh_key.key_name}"
  ebs_optimized                        = "${lookup(var.worker_launch_template_lst[count.index], "ebs_optimized", lookup(local.ebs_optimized, lookup(var.worker_launch_template_lst[count.index], "instance_type_pool1", local.worker_lt_defaults["instance_type_pool1"]), false))}"

  block_device_mappings {
    device_name = "${lookup(var.worker_launch_template_lst[count.index], "root_block_device_name", local.worker_lt_defaults["root_block_device_name"])}"

    ebs {
      volume_size           = "${lookup(var.worker_launch_template_lst[count.index], "root_volume_size", local.worker_lt_defaults["root_volume_size"])}"
      volume_type           = "${lookup(var.worker_launch_template_lst[count.index], "root_volume_type", local.worker_lt_defaults["root_volume_type"])}"
      iops                  = "${lookup(var.worker_launch_template_lst[count.index], "root_iops", local.worker_lt_defaults["root_iops"])}"
      encrypted             = "${lookup(var.worker_launch_template_lst[count.index], "root_encrypted", local.worker_lt_defaults["root_encrypted"])}"
      kms_key_id            = "${lookup(var.worker_launch_template_lst[count.index], "root_kms_key_id", local.worker_lt_defaults["root_kms_key_id"])}"
      delete_on_termination = "${lookup(var.worker_launch_template_lst[count.index], "delete_ebs", local.worker_lt_defaults["delete_ebs"])}"
    }
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks_mixed_instances_asg" {
  count                   = "${var.worker_launch_template_mixed_count}"
  name                    = "${var.eks_cluster_name}-${lookup(var.worker_launch_template_lst[count.index], "name", count.index)}-asg"
  max_size                = "${lookup(var.worker_launch_template_lst[count.index], "asg_max_size", local.worker_lt_defaults["asg_max_size"])}"
  desired_capacity        = "${lookup(var.worker_launch_template_lst[count.index], "asg_desired_capacity", local.worker_lt_defaults["asg_desired_capacity"])}"
  min_size                = "${lookup(var.worker_launch_template_lst[count.index], "asg_min_size", local.worker_lt_defaults["asg_min_size"])}"
  force_delete            = "${lookup(var.worker_launch_template_lst[count.index], "asg_force_delete", local.worker_lt_defaults["asg_force_delete"])}"
  vpc_zone_identifier     = ["${split(",", coalesce(lookup(var.worker_launch_template_lst[count.index], "eks_worker_subnets", ""), local.worker_lt_defaults["eks_worker_subnets"]))}"] # private subnets to which a bastion host is connected
  target_group_arns       = ["${compact(split(",", coalesce(lookup(var.worker_launch_template_lst[count.index], "target_group_arns", ""), local.worker_lt_defaults["target_group_arns"])))}"]
  service_linked_role_arn = "${lookup(var.worker_launch_template_lst[count.index], "service_linked_role_arn", local.worker_lt_defaults["service_linked_role_arn"])}"
  protect_from_scale_in   = "${lookup(var.worker_launch_template_lst[count.index], "protect_from_scale_in", local.worker_lt_defaults["protect_from_scale_in"])}"
  suspended_processes     = ["${compact(split(",", coalesce(lookup(var.worker_launch_template_lst[count.index], "suspended_processes", ""), local.worker_lt_defaults["suspended_processes"])))}"]
  enabled_metrics         = ["${compact(split(",", coalesce(lookup(var.worker_launch_template_lst[count.index], "enabled_metrics", ""), local.worker_lt_defaults["enabled_metrics"])))}"]
  placement_group         = "${lookup(var.worker_launch_template_lst[count.index], "placement_group", local.worker_lt_defaults["placement_group"])}"
  termination_policies    = ["${compact(split(",", coalesce(lookup(var.worker_launch_template_lst[count.index], "termination_policies", ""), local.worker_lt_defaults["termination_policies"])))}"]

  # This setting will guarantee 1 "On-Demand" instance at all times and scale using Spot Instances
  # from pools listed below in the order specified
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_allocation_strategy            = "${lookup(var.worker_launch_template_lst[count.index], "on_demand_allocation_strategy", local.worker_lt_defaults["on_demand_allocation_strategy"])}"
      on_demand_base_capacity                  = "${lookup(var.worker_launch_template_lst[count.index], "on_demand_base_capacity", local.worker_lt_defaults["on_demand_base_capacity"])}"
      on_demand_percentage_above_base_capacity = "${lookup(var.worker_launch_template_lst[count.index], "on_demand_percentage_above_base_capacity", local.worker_lt_defaults["on_demand_percentage_above_base_capacity"])}"
      spot_allocation_strategy                 = "${lookup(var.worker_launch_template_lst[count.index], "spot_allocation_strategy", local.worker_lt_defaults["spot_allocation_strategy"])}"
      spot_instance_pools                      = "${lookup(var.worker_launch_template_lst[count.index], "spot_instance_pools", local.worker_lt_defaults["spot_instance_pools"])}"
      spot_max_price                           = "${lookup(var.worker_launch_template_lst[count.index], "spot_max_price", local.worker_lt_defaults["spot_max_price"])}"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = "${element(aws_launch_template.eks_worker_lt_mixed.*.id, count.index)}"
        version            = "${lookup(var.worker_launch_template_lst[count.index], "launch_template_version", local.worker_lt_defaults["launch_template_version"])}"
      }

      override {
        instance_type = "${lookup(var.worker_launch_template_lst[count.index], "instance_type_pool1", local.worker_lt_defaults["instance_type_pool1"])}"
      }

      override {
        instance_type = "${lookup(var.worker_launch_template_lst[count.index], "instance_type_pool2", local.worker_lt_defaults["instance_type_pool2"])}"
      }

      override {
        instance_type = "${lookup(var.worker_launch_template_lst[count.index], "instance_type_pool3", local.worker_lt_defaults["instance_type_pool3"])}"
      }
    }
  }

  lifecycle {
      create_before_destroy = true
  }

  tags = ["${concat(
    list(
      map("key", "Name", "value", "${aws_eks_cluster.eks_cluster.name}-${lookup(var.worker_launch_template_lst[count.index], "name", count.index)}-asg", "propagate_at_launch", true),
      map("key", "kubernetes.io/cluster/${aws_eks_cluster.eks_cluster.name}", "value", "owned", "propagate_at_launch", true),
      map("key", "${aws_eks_cluster.eks_cluster.name}-worker-node-asg", "value", "${lookup(var.worker_launch_template_lst[count.index], "kubelet_extra_args", count.index)}", "propagate_at_launch", true)
    ),
    local.asg_tags
  )}"]
}

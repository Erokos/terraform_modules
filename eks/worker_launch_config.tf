data "template_file" "eks_node_userdata_lc" {
  count    = var.worker_launch_config_count
  template = file("${path.module}/user-data.sh")

  vars = {
    kubeconfig_cert_auth_data = aws_eks_cluster.eks_cluster.certificate_authority[0].data
    cluster_endpoint          = aws_eks_cluster.eks_cluster.endpoint
    cluster_name              = var.eks_cluster_name
    node_label = lookup(
      var.worker_launch_config_lst[count.index],
      "kubelet_extra_args",
      local.worker_lt_defaults["kubelet_extra_args"],
    )
    ami_id = lookup(
      var.worker_launch_config_lst[count.index],
      "eks_ami_id",
      local.worker_lt_defaults["eks_ami_id"],
    )
    instance_type = lookup(
      var.worker_launch_config_lst[count.index],
      "instance_type",
      "",
    )
  }
}

resource "aws_launch_configuration" "eks_worker_lc" {
  count = var.worker_launch_config_count
  name_prefix = "${var.eks_cluster_name}-${lookup(
    var.worker_launch_config_lst[count.index],
    "name",
    count.index,
  )}-lc-"
  security_groups = [aws_security_group.eks_node_sg.id]
  associate_public_ip_address = lookup(
    var.worker_launch_config_lst[count.index],
    "public_ip",
    local.worker_lt_defaults["public_ip"],
  )
  iam_instance_profile = element(
    aws_iam_instance_profile.eks_node_profile_lc.*.name,
    count.index,
  )
  image_id = lookup(
    var.worker_launch_config_lst[count.index],
    "eks_ami_id",
    local.worker_lt_defaults["eks_ami_id"],
  )
  instance_type = lookup(
    var.worker_launch_config_lst[count.index],
    "instance_type",
    local.worker_lt_defaults["instance_type"],
  )
  key_name = aws_key_pair.ssh_key.key_name
  ebs_optimized = lookup(
    var.worker_launch_config_lst[count.index],
    "ebs_optimized",
    lookup(
      local.ebs_optimized,
      lookup(
        var.worker_launch_config_lst[count.index],
        "instance_type",
        local.worker_lt_defaults["instance_type"],
      ),
      false,
    ),
  )
  user_data_base64 = base64encode(
    element(
      data.template_file.eks_node_userdata_lc.*.rendered,
      count.index,
    ),
  )
  enable_monitoring = lookup(
    var.worker_launch_config_lst[count.index],
    "enable_monitoring",
    local.worker_lt_defaults["enable_monitoring"],
  )
  spot_price = lookup(
    var.worker_launch_config_lst[count.index],
    "spot_max_price",
    local.worker_lt_defaults["spot_max_price"],
  )

  #placement_tenancy           = "${lookup(var.worker_launch_config_lst[count.index], "placement_tenancy", local.worker_lt_defaults["placement_tenancy"])}"

  root_block_device {
    volume_size = lookup(
      var.worker_launch_config_lst[count.index],
      "root_volume_size",
      local.worker_lt_defaults["root_volume_size"],
    )
    volume_type = lookup(
      var.worker_launch_config_lst[count.index],
      "root_volume_type",
      local.worker_lt_defaults["root_volume_type"],
    )
    iops = lookup(
      var.worker_launch_config_lst[count.index],
      "root_iops",
      local.worker_lt_defaults["root_iops"],
    )
    delete_on_termination = lookup(
      var.worker_launch_config_lst[count.index],
      "delete_ebs",
      local.worker_lt_defaults["delete_ebs"],
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks_launch_config_worker_asg" {
  count       = var.worker_launch_config_count
  name_prefix = "${var.eks_cluster_name}-${element(aws_launch_configuration.eks_worker_lc.*.name, count.index)}-asg-"
  max_size = lookup(
    var.worker_launch_config_lst[count.index],
    "asg_max_size",
    local.worker_lt_defaults["asg_max_size"],
  )
  desired_capacity = lookup(
    var.worker_launch_config_lst[count.index],
    "asg_desired_capacity",
    local.worker_lt_defaults["asg_desired_capacity"],
  )
  min_size = lookup(
    var.worker_launch_config_lst[count.index],
    "asg_min_size",
    local.worker_lt_defaults["asg_min_size"],
  )
  force_delete = lookup(
    var.worker_launch_config_lst[count.index],
    "asg_force_delete",
    local.worker_lt_defaults["asg_force_delete"],
  )
  vpc_zone_identifier = split(
    ",",
    coalesce(
      lookup(
        var.worker_launch_config_lst[count.index],
        "eks_worker_subnets",
        "",
      ),
      local.worker_lt_defaults["eks_worker_subnets"],
    ),
  ) # private subnets to which a bastion host is connected
  target_group_arns = compact(
    split(
      ",",
      coalesce(
        lookup(
          var.worker_launch_config_lst[count.index],
          "target_group_arns",
          "",
        ),
        local.worker_lt_defaults["target_group_arns"],
      ),
    ),
  )
  service_linked_role_arn = lookup(
    var.worker_launch_config_lst[count.index],
    "service_linked_role_arn",
    local.worker_lt_defaults["service_linked_role_arn"],
  )
  launch_configuration = element(aws_launch_configuration.eks_worker_lc.*.id, count.index)
  protect_from_scale_in = lookup(
    var.worker_launch_config_lst[count.index],
    "protect_from_scale_in",
    local.worker_lt_defaults["protect_from_scale_in"],
  )
  suspended_processes = compact(
    split(
      ",",
      coalesce(
        lookup(
          var.worker_launch_config_lst[count.index],
          "suspended_processes",
          "",
        ),
        local.worker_lt_defaults["suspended_processes"],
      ),
    ),
  )
  enabled_metrics = compact(
    split(
      ",",
      coalesce(
        lookup(
          var.worker_launch_config_lst[count.index],
          "enabled_metrics",
          "",
        ),
        local.worker_lt_defaults["enabled_metrics"],
      ),
    ),
  )
  placement_group = lookup(
    var.worker_launch_config_lst[count.index],
    "placement_group",
    local.worker_lt_defaults["placement_group"],
  )
  termination_policies = compact(
    split(
      ",",
      coalesce(
        lookup(
          var.worker_launch_config_lst[count.index],
          "termination_policies",
          "",
        ),
        local.worker_lt_defaults["termination_policies"],
      ),
    ),
  )

  lifecycle {
    create_before_destroy = true
  }

  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  tags = [
    concat(
      [
        {
          "key" = "Name"
          "value" = "${aws_eks_cluster.eks_cluster.name}-${lookup(
            var.worker_launch_config_lst[count.index],
            "name",
            count.index,
          )}-asg"
          "propagate_at_launch" = true
        },
        {
          "key"                 = "kubernetes.io/cluster/${aws_eks_cluster.eks_cluster.name}"
          "value"               = "owned"
          "propagate_at_launch" = true
        },
        {
          "key" = "${aws_eks_cluster.eks_cluster.name}-worker-node-asg"
          "value" = lookup(
            var.worker_launch_config_lst[count.index],
            "kubelet_extra_args",
            count.index,
          )
          "propagate_at_launch" = true
        },
      ],
      local.asg_tags,
    ),
  ]
}


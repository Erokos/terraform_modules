resource "aws_eks_node_group" "eks_worker_ng" {
  count           = var.worker_node_group_count
  cluster_name    = var.eks_cluster_name
  node_group_name = "${var.eks_cluster_name}-${lookup(var.worker_node_group_lst[count.index], "name", count.index)}"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  #subnet_ids      = ["${split(",", coalesce(lookup(var.worker_node_group_lst[count.index], "eks_worker_subnets", ""), local.worker_lt_defaults["eks_worker_subnets"]))}"] # private subnets to which a bastion host is connected
  subnet_ids = var.eks_worker_subnets
  ami_type = lookup(
    var.worker_node_group_lst[count.index],
    "ng_ami_id",
    local.worker_lt_defaults["ng_ami_id"],
  )
  disk_size = lookup(
    var.worker_node_group_lst[count.index],
    "root_volume_size",
    local.worker_lt_defaults["root_volume_size"],
  )
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  instance_types = [lookup(
    var.worker_node_group_lst[count.index],
    "instance_type",
    local.worker_lt_defaults["instance_type"],
  )]
  labels = var.k8s_ng_labels

  #release_version = "${lookup(var.worker_node_group_lst[count.index], "cluster_kubernetes_version", "1.14")}" # the minimum for node groups is 1.14
  release_version = "1.14.7-20190927" # hard-coded because it's the only very specific version that node groups support

  scaling_config {
    desired_size = lookup(
      var.worker_node_group_lst[count.index],
      "asg_desired_capacity",
      local.worker_lt_defaults["asg_desired_capacity"],
    )
    max_size = lookup(
      var.worker_node_group_lst[count.index],
      "asg_max_size",
      local.worker_lt_defaults["asg_max_size"],
    )
    min_size = lookup(
      var.worker_node_group_lst[count.index],
      "asg_min_size",
      local.worker_lt_defaults["asg_min_size"],
    )
  }

  remote_access {
    ec2_ssh_key               = aws_key_pair.ssh_key.key_name
    source_security_group_ids = [aws_security_group.bastion_eks_sg[0].id]
  }

  tags = merge(
    {
      "key"   = "Name"
      "value" = "${aws_eks_cluster.eks_cluster.name}-${lookup(var.worker_node_group_lst[count.index], "name", count.index)}"
    },
    var.k8s_ng_labels,
  )
}


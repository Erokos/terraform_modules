locals {
  default_iam_worker_role_id = aws_iam_role.eks_node_role.name
  worker_security_group_id = coalesce(
    aws_security_group.eks_node_sg.id,
    var.worker_security_group_id,
  )

  asg_tags = [
    for item in keys(var.tags) :
    map(
        "key", item,
        "value", element(values(var.tags), index(keys(var.tags), item)),
        "propagate_at_launch", "true"
        )
  ]

  worker_lt_defaults = {
    name                                     = "count.index"                     # The name of the worker group.
    eks_ami_id                               = data.aws_ami.eks_worker.id        # The AMI ID for the EKS Instances. By default it will be the latest possible.
    asg_desired_capacity                     = "3"                               # The desired number of deployed worker Instances.
    asg_max_size                             = "4"                               # The maximum number of deployed worker Instances.
    asg_min_size                             = "1"                               # The minimum number of deployed worker Instances.
    asg_force_delete                         = false                             # Enable forced deletion for the autoscaling group.
    instance_type                            = "m5.large"                        # Default instance type when using launch configurations for worker nodes.
    instance_type_pool1                      = "m5.xlarge"                       # Override instance type 1 for mixed instances policy.
    instance_type_pool2                      = "c5.xlarge"                       # Override instance type 2 for mixed instances policy.
    instance_type_pool3                      = "c4.xlarge"                       # Override instance type 3 for mixed instances policy.
    instance_type_pool4                      = "t3.xlarge"                       # Override instance type 4 for mixed instances policy.
    eks_worker_subnets                       = var.eks_worker_subnets            # A comma delimited string of subnets to place the worker instances in. Usually private subnets.
    target_group_arns                        = null                              # A comma delimited list of ALB target group ARNs to be associated to the ASG
    service_linked_role_arn                  = ""                                # Arn of custom service linked role that Auto Scaling group will use. Useful when you have encrypted EBS.
    protect_from_scale_in                    = false                             # The autoscaling group will not select instances with this setting for terminination during scale in events.
    suspended_processes                      = []                   # A list of processes to suspend for the AutoScaling Group. The allowed values are Launch, Terminate, HealthCheck, ReplaceUnhealthy, AZRebalance, AlarmNotification, ScheduledActions, AddToLoadBalancer.
    enabled_metrics                          = []                                # A comma delimited list of metrics to be collected i.e. GroupMinSize,GroupMaxSize,GroupDesiredCapacity...
    termination_policies                     = []                                # A list of policies to decide how the instances in the auto scale group should be terminated. The allowed values are OldestInstance, NewestInstance, OldestLaunchConfiguration...
    spot_max_price                           = ""                                # Maximum price per unit hour that the user is willing to pay for the Spot instances. Default is the on-demand price
    kubelet_extra_args                       = ""                                # String passed directly to kubelet. Useful for adding labels or taints.
    disable_api_termination                  = false                             # Controls whether the instance can be terminated using the console, CLI, or API
    iam_worker_role_id                       = local.default_iam_worker_role_id  # A custom IAM worker role id.
    instance_shutdown_behavior               = "stop"                            # Shutdown behavior for the instance. Can be stop or terminate.
    public_ip                                = false                             # Associate a public ip address with a worker instance.
    delete_eni                               = true                              # Delete the ENI on termination. If false, you'll have to manually delete it before termination.
    enable_monitoring                        = true                              # Enables detailed monitoring of an EC2 instance.
    placement_group                          = ""                                # The name of the placement group into which to launch the instances, if any.
    placement_tenancy                        = "default"                         # The tenancy of the instance. Valid values are "default" or "dedicated".
    on_demand_allocation_strategy            = "prioritized"                     # Strategy to use when launching on-demand instances. Valid values: prioritized. Default: prioritized.
    on_demand_base_capacity                  = "1"                               # Absolute minimum amount of desired capacity that must be fulfilled by on-demand instances. Default: 0.
    on_demand_percentage_above_base_capacity = "0"                               # Percentage split between on-demand and Spot instances above the base on-demand capacity.
    spot_allocation_strategy                 = "lowest-price"                    # The only valid value is lowest-price, which is also the default value. The Auto Scaling group selects the cheapest Spot pools and evenly allocates your Spot capacity across the number of Spot pools that you specify.
    spot_instance_pools                      = "10"                              # Number of Spot pools per availability zone to allocate capacity. EC2 Auto Scaling selects the cheapest Spot pools and evenly allocates Spot capacity across the number of Spot pools that you specify.
    launch_template_version                  = "$Latest"                         # Template version. Can be version number, $Latest, or $Default.
    # Block device settings
    ebs_optimized          = true                                     # If true, the launched EC2 instance will be EBS-optimized.
    root_block_device_name = data.aws_ami.eks_worker.root_device_name # Root device name for the worker instances. If none is provided, the assumption is that the default AMI was used.
    root_volume_size       = "100"                                    # The root volume size of the worker instances.
    root_volume_type       = "gp2"                                    # The root volume type of the worker instances, can be 'standard', 'gp' or 'io1'.
    root_iops              = "0"                                      # The amount of provisioned IOPS. This must be set with a volume type "io1".
    root_encrypted         = false                                    # Whether the volume should be encrypted or not.
    root_kms_key_id        = ""                                       # The KMS key to use when encrypting the root storage device.
    delete_ebs             = true                                     # Whether the volume should be destroyed on instance termination.
    # Bastion settings
    bastion_subnets    = join(",", var.bastion_vpc_zone_identifier) # A comma delimited string of subnets to deploy the bastion host(s) in.
    bastion_spot_price = ""
    # Node Group settings
    k8s_label_key   = ""           # Worker node Kubernetes label key. E.g. for a label "lifecycle=spot", the k8s_label_key is lifecycle
    k8s_kabel_value = ""           # Worker node Kubernetes label value. E.g. for a label "lifecycle=spot", the k8s_label_key is spot
    ng_ami_id       = "AL2_x86_64" # Type of Amazon Machine Image (AMI) associated with the EKS Node Group. Valid values: AL2_x86_64, AL2_x86_64_GPU.
  }

  ebs_optimized = {
    "c1.medium"    = false
    "c1.xlarge"    = true
    "c3.large"     = false
    "c3.xlarge"    = true
    "c3.2xlarge"   = true
    "c3.4xlarge"   = true
    "c3.8xlarge"   = false
    "c4.large"     = true
    "c4.xlarge"    = true
    "c4.2xlarge"   = true
    "c4.4xlarge"   = true
    "c4.8xlarge"   = true
    "c5.large"     = true
    "c5.xlarge"    = true
    "c5.2xlarge"   = true
    "c5.4xlarge"   = true
    "c5.9xlarge"   = true
    "c5.18xlarge"  = true
    "c5d.large"    = true
    "c5d.xlarge"   = true
    "c5d.2xlarge"  = true
    "c5d.4xlarge"  = true
    "c5d.9xlarge"  = true
    "c5d.18xlarge" = true
    "cc2.8xlarge"  = false
    "cr1.8xlarge"  = false
    "d2.xlarge"    = true
    "d2.2xlarge"   = true
    "d2.4xlarge"   = true
    "d2.8xlarge"   = true
    "f1.2xlarge"   = true
    "f1.4xlarge"   = true
    "f1.16xlarge"  = true
    "g2.2xlarge"   = true
    "g2.8xlarge"   = false
    "g3s.xlarge"   = true
    "g3.4xlarge"   = true
    "g3.8xlarge"   = true
    "g3.16xlarge"  = true
    "h1.2xlarge"   = true
    "h1.4xlarge"   = true
    "h1.8xlarge"   = true
    "h1.16xlarge"  = true
    "hs1.8xlarge"  = false
    "i2.xlarge"    = true
    "i2.2xlarge"   = true
    "i2.4xlarge"   = true
    "i2.8xlarge"   = false
    "i3.large"     = true
    "i3.xlarge"    = true
    "i3.2xlarge"   = true
    "i3.4xlarge"   = true
    "i3.8xlarge"   = true
    "i3.16xlarge"  = true
    "i3.metal"     = true
    "m1.small"     = false
    "m1.medium"    = false
    "m1.large"     = true
    "m1.xlarge"    = true
    "m2.xlarge"    = false
    "m2.2xlarge"   = true
    "m2.4xlarge"   = true
    "m3.medium"    = false
    "m3.large"     = false
    "m3.xlarge"    = true
    "m3.2xlarge"   = true
    "m4.large"     = true
    "m4.xlarge"    = true
    "m4.2xlarge"   = true
    "m4.4xlarge"   = true
    "m4.10xlarge"  = true
    "m4.16xlarge"  = true
    "m5.large"     = true
    "m5.xlarge"    = true
    "m5.2xlarge"   = true
    "m5.4xlarge"   = true
    "m5.9xlarge"   = true
    "m5.18xlarge"  = true
    "m5d.large"    = true
    "m5d.xlarge"   = true
    "m5d.2xlarge"  = true
    "m5d.4xlarge"  = true
    "m5d.12xlarge" = true
    "m5d.24xlarge" = true
    "p2.xlarge"    = true
    "p2.8xlarge"   = true
    "p2.16xlarge"  = true
    "p3.2xlarge"   = true
    "p3.8xlarge"   = true
    "p3.16xlarge"  = true
    "r3.large"     = false
    "r3.xlarge"    = true
    "r3.2xlarge"   = true
    "r3.4xlarge"   = true
    "r3.8xlarge"   = false
    "r4.large"     = true
    "r4.xlarge"    = true
    "r4.2xlarge"   = true
    "r4.4xlarge"   = true
    "r4.8xlarge"   = true
    "r4.16xlarge"  = true
    "t1.micro"     = false
    "t2.nano"      = false
    "t2.micro"     = false
    "t2.small"     = false
    "t2.medium"    = false
    "t2.large"     = false
    "t2.xlarge"    = false
    "t2.2xlarge"   = false
    "t3.nano"      = true
    "t3.micro"     = true
    "t3.small"     = true
    "t3.medium"    = true
    "t3.large"     = true
    "t3.xlarge"    = true
    "t3.2xlarge"   = true
    "x1.16xlarge"  = true
    "x1.32xlarge"  = true
    "x1e.xlarge"   = true
    "x1e.2xlarge"  = true
    "x1e.4xlarge"  = true
    "x1e.8xlarge"  = true
    "x1e.16xlarge" = true
    "x1e.32xlarge" = true
  }
}


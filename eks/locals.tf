locals {
  worker_lt_defaults = {
    name                                     = "count.index"                           # The name of the worker group.
    eks_ami_id                               = "${data.aws_ami.eks_worker.id}"         # The AMI ID for the EKS Instances. By default it will be the latest possible.
    asg_desired_capacity                     = "3"                                     # The desired number of deployed worker Instances.
    asg_max_size                             = "4"                                     # The maximum number of deployed worker Instances.
    asg_min_size                             = "1"                                     # The minimum number of deployed worker Instances.
    instance_type_pool1                      = "m5.xlarge"                             # Override instance type 1 for mixed instances policy.
    instance_type_pool2                      = "c5.xlarge"                             # Override instance type 2 for mixed instances policy.
    instance_type_pool3                      = "c4.xlarge"                             # Override instance type 3 for mixed instances policy.
    instance_type_pool4                      = "t3.xlarge"                             # Override instance type 4 for mixed instances policy.
    placement_tenancy                        = ""                                      # Tenancy of the instance, can be "default" or "dedicated".
    eks_worker_subnets                       = "${join(",", var.vpc_zone_identifier)}" # A comma delimited string of subnets to deploy the workers in.
    spot_max_price                           = ""                                      # Maximum price per unit hour that the user is willing to pay for the Spot instances. Default is the on-demand price
    on_demand_base_capacity                  = "1"                                     # Minimum number of on-demand Instances per ASG.
    on_demand_percentage_above_base_capacity = "0"                                     # Percentage of on-demand Instances deployed when scaling over the base capacity.



    # Bastion settings
    bastion_subnets         = "${join(",", var.bastion_vpc_zone_identifier)}" # A comma delimited string of subnets to deploy the bastion host(s) in.
  }
}

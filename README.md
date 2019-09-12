# terraform-modules
A repository containing infrastructure components described as terraform modules. 

## eks
A terraform module used to create a managed Kubernetes cluster on AWS EKS. 
Read the [AWS docs on EKS to get connected to the k8s dashboard](https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html)

### Assumptions
* You've created a Virtual Private Cloud and subnets where you intend to put the EKS resources
* You want the solution of an admin bastion host in a public subnet while the EKS Instances are in private
* You want the option of a less secure solution without a bastion host and the EKS Instances in public subnets
* You want zero-downtime deployment for any change to the bastion on EKS worker Instances

### Prerequisites
* [terraform](https://www.terraform.io/downloads.html) command line
tool used for provisioning infrastructure resources.
Version 0.11 and above but below 0.12 for now.

#### Layers
The repository is composed of module directories, such as `eks` and a `staging` directory
that demonstrates the directory and filestructure in which the modules should be used in another repository.

### Usage example
A full example of leveraging other community modules is contained in the `staging` directory.
Here

```hcl
module "eks_cluster" {
  source = "git::ssh://git@gl.sds.rocks/GDNI/terraform-modules.git//eks?ref=v0.0.2"

  eks_cluster_name                         = "${var.eks_cluster_name}"
  region_name                              = "${var.region_name}"
  vpc_zone_identifier                      = "${your_vpc.private_subnets}"
  enable_bastion                           = true
  bastion_name                             = "Staging-eks-bastion"
  bastion_instance_type                    = "t2.micro"
  bastion_vpc_zone_identifier              = "${your_vpc.public_subnets}"
  vpc_id                                   = "${your_vpc.vpc_id}"
  k8s_node_label                           = "lifecycle=spot"
  source_security_group_id                 = "${your_vpc.security_group_id}"
  use_latest_eks_ami                       = false # by default is true
  eks_ami_id                               = "<specific_ami_id_for_region>"
  max_size                                 = 3
  min_size                                 = 1
  desired_capacity                         = 2
  on_demand_base_capacity                  = 1
  on_demand_percentage_above_base_capacity = 0
  bastion_max_size                         = 1
  bastion_min_size                         = 1
  bastion_desired_capacity                 = 1
  instance_type_pool1                      = "t2.micro"
  instance_type_pool2                      = "t3.nano"
  instance_type_pool3                      = "t3.micro"
  key_name                                 = "${var.key_name}"
  key_value                                = "${var.key_value}"
}
```

The modules described here will use semantic versioning, i.e. a versioning scheme of the format `MAJOR.MINOR.PATCH`.

* `MAJOR` version when an incompatible API change is made
* `MINOR` version when functionality is added in abacward-compatible manner
* `PATCH` version when bacward-comaptible bug fixes are made

After updating your Terraform code to use a new version, you need to run

```
terraform get -update
```

### Doc generation
Code formatting and documentation for variables and outputs is generated using [terraform-docs](https://github.com/segmentio/terraform-docs)

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allowed\_ssh\_cidr | A list of CIDR Networks to allow ssh access to. | list | `<list>` | no |
| aws\_access\_key | The access key for your AWS account | string | n/a | yes |
| aws\_secret\_access\_key | The secret access key for your AWS account | string | n/a | yes |
| bastion\_desired\_capacity | The desired number of bastion Instances | string | n/a | yes |
| bastion\_instance\_type | The Instance type of the bastion host | string | n/a | yes |
| bastion\_max\_size | The max number of bastion Instances | string | n/a | yes |
| bastion\_min\_size | The minimum number of bastion Instances | string | n/a | yes |
| bastion\_name | The name of the bastion host resource | string | n/a | yes |
| bastion\_vpc\_zone\_identifier | List of subnets in which the bastion Instances will be deployed | list | n/a | yes |
| desired\_capacity | The desired numbar of Instances for your cluster | string | n/a | yes |
| eks\_ami\_id | The AMI ID used on the EKS worker nodes | string | `""` | no |
| eks\_cluster\_name | The name for all cluster resources | string | n/a | yes |
| enable\_bastion | If set to true, creates a bastion host and its network resources in a public subnet | string | n/a | yes |
| iam\_eks\_link | Specifies the aws-iam-authenticator download link | string | `"https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/aws-iam-authenticator"` | no |
| instance\_type\_pool1 | The first instance type pool in which to look for Instances | string | n/a | yes |
| instance\_type\_pool2 | The second instance type pool in which to look for Instances | string | n/a | yes |
| instance\_type\_pool3 | The third instance type pool in which to look for Instances | string | n/a | yes |
| k8s\_node\_label | The label on the EKS worker nodes | string | n/a | yes |
| key\_name | The name of the SSH key used to gain access to the worker and bastion Instances | string | n/a | yes |
| key\_value | The public value of the SSH key used to gain access to the Instances | string | n/a | yes |
| kubectl\_eks\_link | Specifies the kubectl version installed on the bastion host. Must be within one minor version difference of your Amazon EKS cluster control plane | string | `"https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/kubectl"` | no |
| max\_size | The max size of the cluster | string | n/a | yes |
| min\_size | The minimum size of the cluster | string | n/a | yes |
| on\_demand\_base\_capacity | The number of on demand Instances to start with | string | n/a | yes |
| on\_demand\_percentage\_above\_base\_capacity | The percentage of scaled Instances that are on demand | string | n/a | yes |
| region\_name | The region in which all the resources are deployed | string | n/a | yes |
| source\_security\_group\_id | The ID of the VPC security group | string | n/a | yes |
| use\_latest\_eks\_ami | Set to true if you want to use the latest AMI | string | `"true"` | no |
| vpc\_id | The ID of the VPC the cluster is deployed in | string | n/a | yes |
| vpc\_zone\_identifier | List of subnets in which the Instances will be deployed and scaled | list | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| ami\_id | The AMI ID used for your EKS worker Instances |
| cluster\_id | Name of the whole EKS cluster and its resources |
| eks\_cluster\_endpoint | The endpoint for your EKS Kubernetes API |
| kubeconfig\_certificate\_authority\_data | The attribute containing certificate-authority-data for your cluster. This is the base64 encoded certificate data required to communicate with your cluster. |

### Known Issues

Upon instantiating an EKS cluster, sometimes the nodes will be in "Not Ready" status. This happens because of an outdated version of the [Amazon CNI plugin](https://docs.aws.amazon.com/eks/latest/userguide/cni-upgrades.html), that needs to be updated manually.

## Future plans
In the future all modules contained in this repository will be written for terraform 0.12 version as well, on a separate branch.
Tests will also be written for each of the modules and the modules will be optimised to become more configurable.

## EKS
This folder describes a terraform module used to create a managed Kubernetes 
cluster on AWS EKS.
Read the [AWS docs on EKS to get connected to the k8s dashboard](https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html)

### Assumptions
* You've created a Virtual Private Cloud and subnets where you intend to put the
EKS resources
* You want the solution of an admin bastion host in a public subnet while the 
EKS Instances are in private
* You want the option of a less secure solution without a bastion host and the 
EKS Instances in public subnets
* You want zero-downtime deployment for any change to the bastion or the EKS 
cluster

### Prerequisites
* [terraform](https://www.terraform.io/downloads.html) command line
tool used for provisioning infrastructure resources.
Version 0.11 and above but below 0.12 if using the code on `terraform0.11` branch.

#### Layers
The repository is composed of module directories, such as `eks` and an 
`examples` directory that demonstrates the directory and filestructure through
which the modules should be used in another repository.

### Usage example
A full example of leveraging other community modules is contained in the 
`examples` directory. Here is an example of using the module while leveraging
launch configurations:

```hcl
module "eks" {
  source                             = "git::ssh://git@gl.sds.rocks/GDNI/terraform-modules.git//eks?ref=v0.0.11"
  eks_cluster_name                   = "${var.eks_cluster_name}"
  region_name                        = "eu-central-1"
  source_security_group_id           = "${module.eks_vpc.default_security_group_id}"
  vpc_id                             = "${module.eks_vpc.vpc_id}"
  vpc_zone_identifier                = "${module.eks_vpc.private_subnets}"
  worker_launch_config_count         = 2
  cluster_kubernetes_version         = "1.13"
  eks_ami_version                    = "1.13"
  bastion_vpc_zone_identifier        = "${module.eks_vpc.public_subnets}"
  enable_bastion                     = true
  bastion_name                       = "personalization-bastion"
  eks_worker_subnets                 = "${module.eks_vpc.private_subnets}"
  key_name                           = "${var.key_name}"
  key_value                          = "${var.key_value}"
  pvt_key                            = "${var.pvt_key}"
  kubectl_eks_link                   = "https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/kubectl"
  cni_link                           = "https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.5/config/v1.5/aws-k8s-cni.yaml"
  aws_access_key                     = "${var.aws_access_key}"
  aws_secret_access_key              = "${var.aws_secret_access_key}"

  worker_launch_config_lst = [
    {
      name                       = "general-purpose"
      instance_type              = "t3.large"
      spot_max_price             = "0.096"
      asg_max_size               = 3
      asg_desired_capacity       = 2
      kubelet_extra_args         = "lifecycle=spot,worker-type=general-purpose"
      enable_monitoring          = false
      key_name                   = "${var.key_name}"
      key_value                  = "${var.key_value}"
      ebs_optimized              = false
    },

    {
      name                       = "compute-optimized"
      instance_type              = "c5.xlarge"
      spot_max_price             = "0.194"
      asg_max_size               = 3
      asg_desired_capacity       = 2
      kubelet_extra_args         = "lifecycle=spot,worker-type=compute-optimized"
      enable_monitoring          = false
      key_name                   = "${var.key_name}"
      key_value                  = "${var.key_value}"
      ebs_optimized              = false
    }
  ]
}
```

### Zero-downtime deployment
When the worker node user data, AMI id, or instance type is changed, the module
will automatically create new worker nodes with the change applied. As a next 
step, Terraform usually just terminates the old nodes all at once which causes a
short downtime. By itself Terraform doesn't support a rolling update of an auto 
scaling group of nodes so we used a custom bash script that is executed by a 
null resource. This null resource is triggered whenever a launch configuration
is changed, i.e. whenever any of its parameters like `user data, ami id or 
instance type` are changed. The `prepare_nodes.sh` script will get triggered
which will automate node draining. It will know exactly which nodes to drain.


### Inputs
For a full list of configurable variables and their defaults, check the 
locals.tf file.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allowed\_ssh\_cidr | A list of CIDR Networks to allow ssh access to. | list | `<list>` | no |
| aws\_access\_key | The access key for your AWS account | string | `""` | no |
| aws\_secret\_access\_key | The secret access key for your AWS account | string | `""` | no |
| bastion\_after\_workers\_lc | If set to true, the bastion host will be created via an asg after the workers described by launch configurations. | string | `"false"` | no |
| bastion\_after\_workers\_lt | If set to true, the bastion host will be created via an asg after the workers described by launch templates. | string | `"false"` | no |
| bastion\_after\_workers\_ng | If set to true, the bastion host will be created via an asg after the workers described by node groups. | string | `"false"` | no |
| bastion\_desired\_capacity | The desired number of bastion Instances | string | `"1"` | no |
| bastion\_instance\_type | The Instance type of the bastion host | string | `"t2.micro"` | no |
| bastion\_max\_size | The max number of bastion Instances | string | `"2"` | no |
| bastion\_min\_size | The minimum number of bastion Instances | string | `"1"` | no |
| bastion\_name | The name of the bastion host resource | string | `"bastion-host"` | no |
| bastion\_spot\_price | The amount willing to pay for the bastion spot instance | string | `""` | no |
| bastion\_vpc\_zone\_identifier | List of subnets in which the bastion Instances will be deployed | list | n/a | yes |
| cluster\_kubernetes\_version | Specifies the version of kubernetes for API plane | string | `"1.13"` | no |
| cni\_link | Specifies the link to the CNI kubernetes files | string | `"https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.5.3/config/v1.5/aws-k8s-cni.yaml"` | no |
| eks\_cluster\_name | The name for all cluster resources | string | `"Testing-cluster"` | no |
| eks\_worker\_subnets | List of EKS subnets to place the workers in | list | n/a | yes |
| enable\_bastion | If set to true, creates a bastion host and its network resources in a public subnet | string | `"true"` | no |
| enable\_bastion\_asg | If set to true, creates a bastion host auto scaling group and its network resources in a public subnet | string | `"false"` | no |
| endpoint\_private\_access | Specifies whether or not the Amazon EKS private API server endpoint is enabled. Default is false. | string | `"false"` | no |
| endpoint\_public\_access | whether or not the Amazon EKS public API server endpoint is enabled. Default is true. | string | `"true"` | no |
| iam\_eks\_link | Specifies the aws-iam-authenticator download link | string | `"https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator"` | no |
| k8s\_ng\_labels | A map of k8s worker node labels. | map | `<map>` | no |
| key\_name | The name of the SSH key used to gain access to the worker and bastion Instances | string | `""` | no |
| key\_value | The public value of the SSH key used to gain access to the Instances | string | `""` | no |
| kubectl\_eks\_link | Specifies the kubectl version installed on the bastion host. Must be within one minor version difference of your Amazon EKS cluster control plane | string | `"https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/kubectl"` | no |
| private\_subnets\_cidrs | The cidr blocks of the VPC private subnets used in node group creation | list | `<list>` | no |
| pvt\_key | The path to the private SSH key used for remote-exec to gain access to the worker and bastion Instances | string | n/a | yes |
| region\_name | The region in which all the resources are deployed | string | `"eu-west-1"` | no |
| source\_security\_group\_id | The ID of the VPC security group | string | n/a | yes |
| tags | A map of tags to add to all resources. | map | `<map>` | no |
| vpc\_cidr\_block | The VPC cidr block used with node group creation | string | `""` | no |
| vpc\_id | The ID of the VPC the cluster is deployed in | string | n/a | yes |
| vpc\_zone\_identifier | List of subnets in which the Instances will be deployed and scaled | list | n/a | yes |
| worker\_ami\_name\_filter | Additional name filter for AWS EKS worker AMI. Default behaviour will get latest for the cluster\_version but could be set to a release from amazon-eks-ami, e.g. "v20190220" | string | `"v*"` | no |
| worker\_launch\_config\_count | The number of maps in the worker\_launch\_config\_lst list | string | `"0"` | no |
| worker\_launch\_config\_lst | A list of maps defininig worker instance group configurations to be defined using launch configurations. See worker\_lt\_defaults in locals.tf for valid keys. | list | `<list>` | no |
| worker\_launch\_template\_lst | A list of maps defining worker instance group configurations to be defined using launch templates with mixed instance policy. See worker\_lt\_defaults in locals.tf for valid keys. | list | `<list>` | no |
| worker\_launch\_template\_mixed\_count | The number of maps in the worker\_launch\_template\_lst list | string | `"0"` | no |
| worker\_node\_group\_count | The number of maps in the worker\_node\_group\_lst list | string | `"0"` | no |
| worker\_node\_group\_lst | A list of maps defininig worker instance group configurations to be defined using node groups. See worker\_lt\_defaults in locals.tf for valid keys. | list | `<list>` | no |
| worker\_security\_group\_id | If provided, all workers will be attached to this security group. If not, a sg will be created correctly to work with the cluster | string | `""` | no |

### Outputs

| Name | Description |
|------|-------------|
| authentication\_warning | To authenticate the bastion and nodes with the Kubernetes control plane |
| cluster\_arn | The Amazon Resource Name \(ARN\) of the cluster |
| cluster\_id | Name of the whole EKS cluster and its resources |
| cluster\_version | The Kubernetes server version for the EKS cluster |
| cni\_warning | To enable networking between the bastion and the workers |
| credentials\_warning |  |
| eks\_cluster\_endpoint | The endpoint for your EKS Kubernetes API |
| kubeconfig\_certificate\_authority\_data | The attribute containing certificate-authority-data for your cluster. This is the base64 encoded certificate data required to communicate with your cluster. |
| warning | When updating the cluster kubernetes version specify the right kubectl link for the bastion host |
| worker\_security\_group\_id | The ID of the security group for EKS workers |

### Future plans
In the future the module contained in this repository will be written for terraform 0.12 version as well, on the master branch.
Tests will also be written for each of the module and it will be optimised to become more configurable.

### Known Issues
When using launch templates as in the case of this module, zero-downtime deployment is not possible.
The reason for this is described here: https://github.com/terraform-providers/terraform-provider-aws/issues/4655
in which any change to the launch template doesn't get picked up by the auto scaling group.
Until this issue is resolved, launch configurations should be used instead.

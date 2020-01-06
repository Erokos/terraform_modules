# terraform-modules
A repository containing infrastructure components described as terraform modules.
Each folder represents an infrastructure component containing module files.

## eks
A terraform module used to create a managed Kubernetes cluster on AWS EKS. 
Read the [AWS docs on EKS to get connected to the k8s dashboard](https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html)

### Assumptions
* You've created a Virtual Private Cloud and subnets where you intend to put the
EKS resources
* You want the solution of an admin bastion host in a public subnet while the
EKS Instances are in private
* You want the option of a less secure solution without a bastion host and the
EKS Instances in public subnets
* You want zero-downtime deployment for any change to the bastion on EKS worker Instances

### Prerequisites
* [terraform](https://www.terraform.io/downloads.html) command line
tool used for provisioning infrastructure resources.
Version 0.11 and above but below 0.12 for now.

#### Layers
The repository is composed of module directories, such as `eks` and within it an
examples folder that demonstrates the directory and filestructure in which the
modules should be used in another repository.

The modules described here will use semantic versioning, i.e. a versioning
scheme of the format `MAJOR.MINOR.PATCH`.

* `MAJOR` version when an incompatible API change is made
* `MINOR` version when functionality is added in abacward-compatible manner
* `PATCH` version when bacward-comaptible bug fixes are made

After updating your Terraform code to use a new version, you need to run

```
terraform get -update
```
or

```
terraform init
```

### Doc generation
Code formatting and documentation for variables and outputs is generated using [terraform-docs](https://github.com/segmentio/terraform-docs)

## Future plans
In the future all modules contained in this repository will be written for 
terraform 0.12 version as well, on a separate branch. Tests will also be written
for each of the modules and the modules will be optimised to become more configurable.

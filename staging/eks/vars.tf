variable "eks_cluster_name" {
  description = "The name of all EKS resources"
  default     = "Staging-eks-cluster"
}

variable "region_name" {
  default = "eu-central-1"
}

variable "eks_ami_id" {
  default = "ami-023b82bb04ff20c6d"
}


variable "key_name" {
  default = "module.pub"
}

variable "key_value" {
  default ="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKBgkCO0PTNeqQPYWzzWK68gP/ibfF4jhOHkyfm0HA47Ay/m8EAIaUcn9uIpuGQI8nRgT2nXXVPHhxLqid0lKvAmi1EWLANfuYS3DM0e+jqy7vye5mBBVzj0JHbmmOTIMUKxtu4nKOdFWjyDNINA3y+FW7Y1s+JVFFA+I35+XmXNFreL6bz6n3qhcAOeB3tuUd77jHZeAk402EMN/4gN4iALXjBlnFaADVRAFHBVCEyGzJkdK9qvWkIfS674YaIaeS6QgJAoAfiACPOIuyGuDkZOO8SoLph9JCEksOod4DsHpyBW8FIoKLwjYYAHhN93l57/Rx7aNc05Kp9IaxRoxohQsVVDTNyadskpsTJclNKfayc6q+LB39ekHBmt4PNSUaO1g6eoCMiS+uUhi2Acp6jFvYAGdiMQWh2qQS+Yb1/KQIB2k+lUiQbNvYKy4bU8kj4dSEkG1jyQSLH2YXFOxt7av9v7U7xG8CQtSIVN5Um8EsGlBdIet+SDrbvhaQmYVIb1UZKgqEyCBvnAK7qwKbapplmUjSNyp9YCw2DekYCTK1N7uY/jDf4dPc4SyAdUJxQqkiHxIP2BX7f0e3p2gdkdgmwEBMBSLOcJ/A6JACxC5+tHCztey+tEyKuAHLqOVFjDG9wdiqHq8N4ZCK5739DyrP/ytGAHKU3iGYGWe+Gw== roman.kosanovic@styria.hr"
}

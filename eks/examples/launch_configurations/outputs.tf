output "cluster_id" {
  description = "Name of the whole EKS cluster and its resources"
  value       = "${module.eks.cluster_id}"
}

output "eks_cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API"
  value       = "${module.eks.eks_cluster_endpoint}"
}

output "kubeconfig_certificate_authority_data" {
  description = "The attribute containing certificate-authority-data for your cluster. This is the base64 encoded certificate data required to communicate with your cluster."
  value       = "${module.eks.kubeconfig_certificate_authority_data}"
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value = "${module.eks.cluster_arn}"
}

output "cluster_version" {
  description = "The Kubernetes server version for the EKS cluster"
  value = "${module.eks.cluster_version}"
}

output "warning" {
  description = "A reminder to keep the bastion host configuration in sync with the kubernetes version update"
  value       = "${module.eks.warning}"
}

output "credentials_warning" {
  description = "A reminder to specify the AWS credentials to fully automate EKS creation"
  value       = "${module.eks.credentials_warning}"
}

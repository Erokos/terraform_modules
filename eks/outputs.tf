output "cluster_id" {
  description = "Name of the whole EKS cluster and its resources"
  value       = aws_eks_cluster.eks_cluster.id
}

output "eks_node_role_id" {
  description = "The ID of the EKS worker role"
  value       = aws_iam_role.eks_node_role.id
}

output "eks_node_role_name" {
  description = "The name of the EKS worker role"
  value       = aws_iam_role.eks_node_role.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "kubeconfig_certificate_authority_data" {
  description = "The attribute containing certificate-authority-data for your cluster. This is the base64 encoded certificate data required to communicate with your cluster."
  value       = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.eks_cluster.arn
}

output "cluster_version" {
  description = "The Kubernetes server version for the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.version
}

output "warning" {
  value = "When updating the cluster kubernetes version specify the right kubectl link for the bastion host!"
}

output "credentials_warning" {
  value = "Specify your AWS credentials as Terraform variables in order to fully automate cluster creation!"
}

output "worker_security_group_id" {
  description = "The ID of the security group for EKS workers"
  value       = aws_security_group.eks_node_sg.id
}

output "authentication_warning" {
  description = "To authenticate the bastion and nodes with the Kubernetes control plane"
  value       = "When creating the cluster for the first time and if the bastion is created via a bastion asg, execute on the bastion: kubectl apply -f aws-auth-cm.yaml"
}

output "cni_warning" {
  description = "To enable networking between the bastion and the workers"
  value       = "When creating the cluster for the first time and if the bastion is created via a bastion asg, execute on the bastion: kubectl apply -f ${var.cni_link}"
}


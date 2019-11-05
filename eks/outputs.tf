output "cluster_id" {
  description = "Name of the whole EKS cluster and its resources"
  value       = "${aws_eks_cluster.eks_cluster.id}"
}

output "eks_cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API"
  value       = "${aws_eks_cluster.eks_cluster.endpoint}"
}

output "kubeconfig_certificate_authority_data" {
  description = "The attribute containing certificate-authority-data for your cluster. This is the base64 encoded certificate data required to communicate with your cluster."
  value       = "${aws_eks_cluster.eks_cluster.certificate_authority.0.data}"
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value = "${aws_eks_cluster.eks_cluster.arn}"
}

output "cluster_version" {
  description = "The Kubernetes server version for the EKS cluster"
  value = "${aws_eks_cluster.eks_cluster.version}"
}

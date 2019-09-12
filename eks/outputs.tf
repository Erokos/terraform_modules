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

output "ami_id" {
  description = "The AMI ID used for your EKS worker Instances"
  value = "${var.eks_ami_id == "" ? format("%s", data.aws_ami.eks_worker.id) : var.eks_ami_id}"
}

output "cluster_id" {
  value = "${aws_eks_cluster.eks_cluster.id}"
}

output "eks_cluster_endpoint" {
  value = "${aws_eks_cluster.eks_cluster.endpoint}"
}

output "kubeconfig_certificate_authority_data" {
  value = "${aws_eks_cluster.eks_cluster.certificate_authority.0.data}"
}

output "ami_id" {
  value = "${var.eks_ami_id == "" ? format("%s", data.aws_ami.bastion.id) : var.eks_ami_id}"
}

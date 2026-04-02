output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = module.eks_cluster.cluster_endpoint
}

output "configure_kubectl" {
  description = "Command to update local kubeconfig."
  value       = try(aws_iam_role.root_assumable_cluster_admin[0].arn, "") != "" ? "aws eks update-kubeconfig --name ${module.eks_cluster.cluster_name} --region ${var.aws_region} --role-arn ${aws_iam_role.root_assumable_cluster_admin[0].arn}" : "aws eks update-kubeconfig --name ${module.eks_cluster.cluster_name} --region ${var.aws_region}"
}

output "root_assumable_cluster_admin_role_arn" {
  description = "IAM role ARN that the current AWS account root can assume for EKS cluster administration."
  value       = try(aws_iam_role.root_assumable_cluster_admin[0].arn, null)
}

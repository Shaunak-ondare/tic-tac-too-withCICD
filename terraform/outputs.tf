output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Command to update local kubeconfig."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "frontend_service_name" {
  description = "Public frontend Kubernetes service name."
  value       = kubernetes_service_v1.frontend.metadata[0].name
}

output "backend_service_name" {
  description = "Internal backend Kubernetes service name."
  value       = kubernetes_service_v1.backend.metadata[0].name
}

variable "aws_region" {
  description = "AWS region for the EKS environment."
  type        = string
}

variable "project_name" {
  description = "Project name used in naming."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "kubernetes_version" {
  description = "EKS control plane version."
  type        = string
  default     = "1.30"
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired node count."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum node count."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum node count."
  type        = number
  default     = 4
}

variable "application_namespace" {
  description = "Kubernetes namespace for the application."
  type        = string
  default     = "app"
}

variable "frontend_image" {
  description = "Container image for the frontend application."
  type        = string
}

variable "backend_image" {
  description = "Container image for the backend application."
  type        = string
}

variable "frontend_replicas" {
  description = "Number of frontend pods."
  type        = number
  default     = 2
}

variable "backend_replicas" {
  description = "Number of backend pods."
  type        = number
  default     = 2
}

variable "frontend_container_port" {
  description = "Frontend container port."
  type        = number
  default     = 80
}

variable "backend_container_port" {
  description = "Backend container port."
  type        = number
  default     = 5678
}

variable "frontend_service_port" {
  description = "Frontend service port."
  type        = number
  default     = 80
}

variable "backend_service_port" {
  description = "Backend service port."
  type        = number
  default     = 8080
}

variable "tags" {
  description = "Tags applied to AWS resources."
  type        = map(string)
  default     = {}
}


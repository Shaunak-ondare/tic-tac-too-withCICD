data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  cluster_name = "${var.project_name}-${var.environment}"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = [for index, az in local.azs : cidrsubnet(var.vpc_cidr, 4, index)]
  public_subnets  = [for index, az in local.azs : cidrsubnet(var.vpc_cidr, 4, index + 8)]
  oidc_enabled = alltrue([
    trimspace(var.oidc_issuer_url) != "",
    trimspace(var.oidc_client_id) != "",
    trimspace(var.oidc_redirect_uri) != ""
  ])
  root_assumable_cluster_admin_role_arn = try(aws_iam_role.root_assumable_cluster_admin[0].arn, "")
  cluster_admin_principal_arn           = trimspace(var.cluster_admin_user_arn) != "" ? var.cluster_admin_user_arn : local.root_assumable_cluster_admin_role_arn

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

resource "aws_iam_role" "root_assumable_cluster_admin" {
  count = var.create_root_assumable_cluster_admin_role && trimspace(var.cluster_admin_user_arn) == "" ? 1 : 0

  name = var.root_assumable_cluster_admin_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "root_assumable_cluster_admin_eks_access" {
  count = var.create_root_assumable_cluster_admin_role && trimspace(var.cluster_admin_user_arn) == "" ? 1 : 0

  name = "${local.cluster_name}-eks-access"
  role = aws_iam_role.root_assumable_cluster_admin[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = [
          module.eks.cluster_arn
        ]
      }
    ]
  })
}

module "main_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.cluster_name
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.common_tags
}

module "eks_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name        = local.cluster_name
  cluster_version     = var.kubernetes_version
  authentication_mode = "API_AND_CONFIG_MAP"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.main_vpc.vpc_id
  subnet_ids = module.main_vpc.private_subnets

  eks_managed_node_groups = {
    default_nodes = {
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size

      labels = {
        workload = "general"
      }
    }
  }

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  access_entries = {
    # 1. Pipeline/Admin IAM User
    cluster_admin = {
      principal_arn = local.cluster_admin_principal_arn != "" ? local.cluster_admin_principal_arn : data.aws_caller_identity.current.arn

      policy_associations = {
        admin = {
          policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    # 2. AWS Account Root User (Explicitly specified for account 823963318980)
    root_access = {
      principal_arn = "arn:aws:iam::823963318980:root"

      policy_associations = {
        admin = {
          policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = local.common_tags
}

# (Kubernetes resources removed: managed via k8s/ manifests in CI/CD pipeline)

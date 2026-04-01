data "aws_availability_zones" "available" {
  state = "available"
}

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

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

module "vpc" {
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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
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

  tags = local.common_tags
}

module "eks_aws_auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.0"

  manage_aws_auth_configmap = true

  aws_auth_users = var.cluster_admin_user_arn == "" ? [] : [
    {
      userarn  = var.cluster_admin_user_arn
      username = "admin"
      groups   = ["system:masters"]
    }
  ]

  depends_on = [module.eks]
}

resource "kubernetes_namespace" "application" {
  metadata {
    name = var.application_namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = var.project_name
    }
  }

  depends_on = [module.eks, module.eks_aws_auth]
}

resource "kubernetes_config_map_v1" "frontend_config" {
  metadata {
    name      = "frontend-config"
    namespace = kubernetes_namespace.application.metadata[0].name
  }

  data = {
    BACKEND_URL       = "http://backend.${var.application_namespace}.svc.cluster.local:${var.backend_service_port}"
    OIDC_ENABLED      = tostring(local.oidc_enabled)
    OIDC_ISSUER_URL   = var.oidc_issuer_url
    OIDC_CLIENT_ID    = var.oidc_client_id
    OIDC_REDIRECT_URI = var.oidc_redirect_uri
    "app-config.js" = <<-EOT
      window.__APP_CONFIG__ = ${jsonencode({
    backendUrl      = "http://backend.${var.application_namespace}.svc.cluster.local:${var.backend_service_port}"
    oidcEnabled     = local.oidc_enabled
    oidcIssuerUrl   = var.oidc_issuer_url
    oidcClientId    = var.oidc_client_id
    oidcRedirectUri = var.oidc_redirect_uri
})};
    EOT
}
}

resource "kubernetes_deployment_v1" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.application.metadata[0].name
    labels = {
      app = "backend"
    }
  }

  spec {
    replicas = var.backend_replicas

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }
      }

      spec {
        container {
          name  = "backend"
          image = var.backend_image

          port {
            container_port = var.backend_container_port
          }
        }
      }
    }
  }

  depends_on = [module.eks, module.eks_aws_auth]
}

resource "kubernetes_service_v1" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.application.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment_v1.backend.metadata[0].labels.app
    }

    port {
      port        = var.backend_service_port
      target_port = var.backend_container_port
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment_v1" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.application.metadata[0].name
    labels = {
      app = "frontend"
    }
  }

  spec {
    replicas = var.frontend_replicas

    selector {
      match_labels = {
        app = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }

      spec {
        container {
          name  = "frontend"
          image = var.frontend_image

          volume_mount {
            name       = "frontend-runtime-config"
            mount_path = "/usr/share/nginx/html/app-config.js"
            sub_path   = "app-config.js"
          }

          port {
            container_port = var.frontend_container_port
          }
        }

        volume {
          name = "frontend-runtime-config"

          config_map {
            name = kubernetes_config_map_v1.frontend_config.metadata[0].name

            items {
              key  = "app-config.js"
              path = "app-config.js"
            }
          }
        }
      }
    }
  }

  depends_on = [module.eks, module.eks_aws_auth]
}

resource "kubernetes_service_v1" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.application.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment_v1.frontend.metadata[0].labels.app
    }

    port {
      port        = var.frontend_service_port
      target_port = var.frontend_container_port
    }

    type = "LoadBalancer"
  }
}

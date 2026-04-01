aws_region         = "ap-south-1"
project_name       = "shaunak-eks"
environment        = "dev"
vpc_cidr           = "10.20.0.0/16"
kubernetes_version = "1.30"

node_instance_types = ["t3.medium"]
node_desired_size   = 1
node_min_size       = 1
node_max_size       = 2

application_namespace   = "tic-tac-toe"
frontend_image          = "961641296773.dkr.ecr.ap-south-1.amazonaws.com/shaunak/tictactoe-frontend:11ada3c22b29b0e2c5da091eb6705fbc4c332b7b"
backend_image           = "961641296773.dkr.ecr.ap-south-1.amazonaws.com/shaunak/tictactoe-backend:11ada3c22b29b0e2c5da091eb6705fbc4c332b7b"
frontend_replicas       = 1
backend_replicas        = 1
frontend_container_port = 80
backend_container_port  = 3001
frontend_service_port   = 80
backend_service_port    = 3001

oidc_issuer_url        = "https://cognito-idp.ap-south-1.amazonaws.com/ap-south-1_reHUe50iP"
oidc_client_id         = "17megb85iapt3kbfgd8q0g1gj"
oidc_client_secret     = ""
oidc_redirect_uri      = "http://a330d1a46c1224c07acca4b6d6bed1e0-1281062264.ap-south-1.elb.amazonaws.com/callback"
cluster_admin_user_arn = "arn:aws:iam::961641296773:root"

tags = {
  Owner = "shaunak-ondare"
}

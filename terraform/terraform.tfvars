aws_region         = "ap-south-1"
project_name       = "shaunak-eks"
environment        = "dev"
vpc_cidr           = "10.20.0.0/16"
kubernetes_version = "1.30"

node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 2
node_max_size       = 4

application_namespace   = "tictakto"
frontend_image          = "shaunakondare/tic-tac-toe-frontend:latest"
backend_image           = "shaunakondare/tic-tac-toe-backend:latest"
frontend_replicas       = 2
backend_replicas        = 2
frontend_container_port = 80
backend_container_port  = 3001
frontend_service_port   = 80
backend_service_port    = 3001


tags = {
  Owner = "shaunak-ondare"
}


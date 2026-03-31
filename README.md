# Tic-Tac-Toe Multiplayer on AWS EKS

This project is a real-time multiplayer Tic-Tac-Toe game built with a React frontend, a Node.js/Socket.io backend, and fully orchestrated on Amazon Web Services (AWS) using Terraform and GitHub Actions.

## 🏗️ Architecture Flow

The entire application runs entirely inside an Amazon Elastic Kubernetes Service (EKS) cluster:

1. **Frontend**: A React application statically built using Vite and served by an Nginx server (`node:22-alpine` builder). 
2. **Backend**: A Node.js backend handling real-time WebSocket connections via Socket.io.
3. **Internal Proxying**: The backend Node.js server sits securely behind the Kubernetes firewall on an internal `ClusterIP`. The frontend Nginx server natively acts as a **Reverse Proxy**. Instead of exposing the backend to the public internet, Nginx dynamically intercepts any web traffic hitting `/socket.io/` and routes it directly to the protected backend pods over the internal AWS network.
4. **Load Balancer**: A single AWS Elastic Load Balancer (ELB) receives public internet traffic and maps it to the frontend pods.

## 🚀 CI/CD Pipeline Workflow

Deployment is completely automated. Whenever code is pushed to the `main` branch, the `.github/workflows/deploy.yml` triggers the following lifecycle:

1. **Build & Push**: The pipeline triggers Docker to build the latest `frontend` and `backend` images. It instantly tags them with the precise Git Commit SHA and pushes them securely to Amazon Elastic Container Registry (ECR).
2. **Infrastructure Initialization**: The pipeline securely authenticates into your AWS account and invokes `terraform init`, linking to an S3 bucket to retrieve the existing infrastructure state.
3. **Automated Provisioning**: Terraform evaluates the cloud environment via `terraform apply` and automatically creates an AWS VPC, Subnets, and an EKS Control Plane (if they do not already exist).
4. **Dynamic Deployment**: Finally, Terraform takes the freshly built Docker images from Step 1, logs into the EKS cluster, creates the `tictakto` Namespace, and natively deploys the Kubernetes Pods and Services.

## ⚙️ Setup & Configuration

To let the deployment pipeline take over, ensure the following GitHub Repository Secrets are configured in your repository (`Settings` > `Secrets and variables` > `Actions`):

- `AWS_ACCESS_KEY_ID`: Your AWS IAM programmatic access key.
- `AWS_SECRET_ACCESS_KEY`: Your AWS IAM secret access key.
- `AWS_REGION`: The target deployment region (e.g., `ap-south-1`).
- `ECR_REGISTRY`: The URL of your remote Amazon ECR registry (e.g., `123456789012.dkr.ecr.ap-south-1.amazonaws.com`).

**Note on Terraform State**: 
This pipeline stores state remotely in AWS. Ensure that the S3 Bucket `aws-tf-backend-shaunak-21` and the DynamoDB Table `tfstate-lock` are manually created in your AWS account *before* the very first pipeline run, otherwise `terraform init` will fail to find its backend!

## 🗑️ Tearing Down the Cluster

Because cost management is important, you can obliterate the entire EKS architecture locally from your computer using Terraform at any time.

1. Ensure AWS CLI credentials are set up on your local machine.
2. Navigate to the `terraform` folder:
   ```bash
   cd terraform
   terraform init
   terraform destroy -auto-approve
   ```
This will securely delete the Load Balancers, the Node Groups, the EKS Control Plane, and the VPC to ensure zero leftover charges.

# Tic-Tac-Toe Multiplayer on AWS EKS

This project is a real-time multiplayer Tic-Tac-Toe game built with a React frontend, a Node.js/Socket.io backend, and fully orchestrated on Amazon Web Services (AWS) using Terraform and GitHub Actions.

## Architecture Flow

The entire application runs inside an Amazon Elastic Kubernetes Service (EKS) cluster:

1. **Frontend**: A React application statically built using Vite and served by an Nginx server (`node:22-alpine` builder).
2. **Backend**: A Node.js backend handling real-time WebSocket connections via Socket.io.
3. **Internal Proxying**: The backend Node.js server sits behind the Kubernetes firewall on an internal `ClusterIP`. The frontend Nginx server acts as a reverse proxy and routes `/socket.io/` traffic directly to the protected backend pods over the internal AWS network.
4. **Load Balancer**: A single AWS Elastic Load Balancer (ELB) receives public internet traffic and maps it to the frontend pods.

## CI/CD Pipeline Workflow

Deployment is automated. Whenever code is pushed to the `main` branch, `.github/workflows/deploy.yml` triggers the following lifecycle:

1. **Build and Push**: Docker builds the latest `frontend` and `backend` images, tags them with the Git commit SHA, and pushes them to Amazon Elastic Container Registry (ECR).
2. **Infrastructure Initialization**: The pipeline authenticates to AWS and runs `terraform init`, connecting to the S3 backend that stores Terraform state.
3. **Automated Provisioning**: Terraform creates or updates the AWS VPC, subnets, EKS control plane, and related infrastructure.
4. **Dynamic Deployment**: Terraform deploys the latest application images into the Kubernetes namespace and updates the Kubernetes services.

## Accessing The App

After `terraform apply`, use the frontend service load balancer output for browser access:

```bash
terraform output frontend_url
```

`cluster_endpoint` is the Kubernetes API server endpoint for `kubectl` and AWS authentication. If you open it directly in a browser, Kubernetes responds with `403 Forbidden` for `system:anonymous`, which is expected.

## Setup and Configuration

To let the deployment pipeline take over, ensure the following GitHub repository secrets are configured under `Settings > Secrets and variables > Actions`:

- `AWS_ACCESS_KEY_ID`: Your AWS IAM programmatic access key.
- `AWS_SECRET_ACCESS_KEY`: Your AWS IAM secret access key.
- `AWS_REGION`: The target deployment region, for example `ap-south-1`.
- `ECR_REGISTRY`: The URL of your Amazon ECR registry, for example `123456789012.dkr.ecr.ap-south-1.amazonaws.com`.

**Note on Terraform State**:
This pipeline stores state remotely in AWS. Ensure that the S3 bucket `aws-tf-backend-shaunak-21` and the DynamoDB table `tfstate-lock` are created in your AWS account before the first pipeline run, otherwise `terraform init` will fail.

## Tearing Down The Cluster

Because cost management matters, you can remove the entire EKS architecture locally at any time with Terraform.

1. Ensure AWS CLI credentials are configured on your local machine.
2. Navigate to the `terraform` folder:
   ```bash
   cd terraform
   terraform init
   terraform destroy -auto-approve
   ```

This deletes the load balancers, node groups, EKS control plane, and VPC so you do not leave billable infrastructure running.

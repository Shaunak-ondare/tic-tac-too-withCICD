terraform {
  backend "s3" {
    bucket         = "aws-tf-backend-shaunak-221"
    key            = "state/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "tfstate-lock"
    encrypt        = true
  }
}

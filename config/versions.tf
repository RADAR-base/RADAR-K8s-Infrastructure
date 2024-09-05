terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
  }

  # Uncomment the following backend block to enable remote TF state persistance.
  # Replace placeholder values with actual output values from the "backend" workspace.
  # backend "s3" {
  #   bucket         = "[backend_bucket_name]"
  #   key            = "config/terraform.tfstate"
  #   region         = "[backend_aws_region]"
  #   dynamodb_table = "[backend_state_locking]"
  # }

  required_version = ">= 1.7.0"
}

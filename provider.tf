terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.19.0"
    }
  }
  required_version = "~> 1.0"
}

provider "aws" {
  region     = var.region
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
  token      = var.AWS_SESSION_TOKEN
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.36.0"
    }
  }
  required_version = ">= 1.5.7, < 2.0.0"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

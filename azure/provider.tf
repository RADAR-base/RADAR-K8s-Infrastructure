terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.40.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.36.0"
    }
  }
  required_version = ">= 1.9.0"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

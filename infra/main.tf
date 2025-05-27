terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  # cloud {
  #   organization = "CHANGE-ME"
  #   workspaces {
  #     name = "CHANGE-ME"
  #   }
  # }
}

provider "aws" {
  region = local.var.region
}

provider "cloudflare" {}
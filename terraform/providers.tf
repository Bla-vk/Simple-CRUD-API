terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Backend blocks cannot use variables, so these values are written out.
  # Same bucket as the dev-environment project, but a different key.
  backend "s3" {
    bucket       = "precious-terraformstate-dev-2026"
    key          = "simple-crud-api/terraform.tfstate"
    region       = "eu-west-2"
    profile      = "vscode"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}

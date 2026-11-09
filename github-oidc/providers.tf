terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Same state bucket as the other projects, but its own key. This stack is kept
  # separate from ../terraform so that destroying the ECS stack never removes the
  # role that GitHub Actions uses.
  backend "s3" {
    bucket       = "precious-terraformstate-dev-2026"
    key          = "github-oidc/terraform.tfstate"
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

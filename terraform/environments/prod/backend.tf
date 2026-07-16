terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "cicd-pipeline-tfstate-093468663320"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cicd-pipeline-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project    = "terraform-cicd-pipeline"
      ManagedBy  = "terraform"
      Repository = "terraform-cicd-pipeline"
    }
  }
}

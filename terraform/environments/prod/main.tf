# Prod — largest instance sizes, private endpoints only, high availability
module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  cidr_block           = "10.2.0.0/16"
  environment          = "prod"
  public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  private_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]

  tags = {
    Environment = "prod"
    Project     = var.project_name
    ManagedBy   = "terraform"
    Criticality = "high"
  }
}

module "s3" {
  source = "../../modules/s3"

  project_name = var.project_name
  environment  = "prod"

  tags = {
    Environment = "prod"
    Project     = var.project_name
    ManagedBy   = "terraform"
    Criticality = "high"
  }
}

module "eks" {
  source = "../../modules/eks"

  project_name    = var.project_name
  environment     = "prod"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  cluster_version = "1.31"

  tags = {
    Environment = "prod"
    Project     = var.project_name
    ManagedBy   = "terraform"
    Criticality = "high"
  }
}

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = "prod"

  tags = {
    Environment = "prod"
    Project     = var.project_name
    ManagedBy   = "terraform"
    Criticality = "high"
  }
}

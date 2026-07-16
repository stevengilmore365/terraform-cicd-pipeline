# Dev environment — small, cost-effective, public endpoints allowed
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  cidr_block   = "10.0.0.0/16"
  environment  = "dev"
  azs          = ["us-east-1a", "us-east-1b"]

  tags = {
    Environment = "dev"
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

module "s3" {
  source = "../../modules/s3"

  project_name = var.project_name
  environment  = "dev"

  tags = {
    Environment = "dev"
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

module "eks" {
  source = "../../modules/eks"

  project_name    = var.project_name
  environment     = "dev"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  cluster_version = "1.31"

  tags = {
    Environment = "dev"
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = "dev"

  tags = {
    Environment = "dev"
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

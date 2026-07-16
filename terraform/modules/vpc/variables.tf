variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = null
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = null
}

variable "environment" {
  description = "Environment name for resource naming"
  type        = string
  default     = "dev"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN for CloudWatch log group encryption"
  type        = string
  default     = null
}

locals {
  public_subnet_cidrs  = var.public_subnet_cidrs != null ? var.public_subnet_cidrs : [for i in range(length(var.azs)) : cidrsubnet(var.cidr_block, 8, i + 1)]
  private_subnet_cidrs = var.private_subnet_cidrs != null ? var.private_subnet_cidrs : [for i in range(length(var.azs)) : cidrsubnet(var.cidr_block, 8, i + 10)]
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "s3_bucket_id" {
  description = "S3 bucket ID"
  value       = module.s3.bucket_id
}

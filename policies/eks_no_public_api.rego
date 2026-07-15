# Deny EKS clusters with public API endpoint in prod
package terraform.eks_no_public_api

deny[msg] {
  resource := input.resource.aws_eks_cluster[name]
  resource.vpc_config.endpoint_public_access == true
  msg := sprintf("EKS cluster '%s' must not have public API endpoint enabled", [name])
}

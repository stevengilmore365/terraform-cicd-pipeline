# Require mandatory tags on all resources
package terraform.required_tags

required_tags := {"Project", "Environment", "ManagedBy"}

deny[msg] {
  resource := input.resource.aws_s3_bucket[name]
  tags := object.get(resource, "tags", {})
  missing := required_tags - {key | tags[key]}
  count(missing) > 0
  msg := sprintf("S3 bucket '%s' is missing required tags: %v", [name, missing])
}

deny[msg] {
  resource := input.resource.aws_vpc[name]
  tags := object.get(resource, "tags", {})
  missing := required_tags - {key | tags[key]}
  count(missing) > 0
  msg := sprintf("VPC '%s' is missing required tags: %v", [name, missing])
}

deny[msg] {
  resource := input.resource.aws_eks_cluster[name]
  tags := object.get(resource, "tags", {})
  missing := required_tags - {key | tags[key]}
  count(missing) > 0
  msg := sprintf("EKS cluster '%s' is missing required tags: %v", [name, missing])
}

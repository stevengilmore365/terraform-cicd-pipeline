# Deny S3 buckets with public access
package terraform.s3

deny[msg] {
  resource := input.resource.aws_s3_bucket[name]
  input.resource.aws_s3_bucket_public_access_block[name].block_public_acls != true
  msg := sprintf("S3 bucket '%s' must have block_public_acls enabled", [name])
}

deny[msg] {
  resource := input.resource.aws_s3_bucket[name]
  input.resource.aws_s3_bucket_public_access_block[name].block_public_policy != true
  msg := sprintf("S3 bucket '%s' must have block_public_policy enabled", [name])
}

deny[msg] {
  resource := input.resource.aws_s3_bucket[name]
  input.resource.aws_s3_bucket_public_access_block[name].restrict_public_buckets != true
  msg := sprintf("S3 bucket '%s' must have restrict_public_buckets enabled", [name])
}

deny[msg] {
  resource := input.resource.aws_s3_bucket[name]
  not input.resource.aws_s3_bucket_server_side_encryption_configuration[name]
  msg := sprintf("S3 bucket '%s' must have server-side encryption configured", [name])
}

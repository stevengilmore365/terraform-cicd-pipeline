# Deny S3 buckets without encryption
package terraform.s3_encryption

deny[msg] {
  resource := input.resource.aws_s3_bucket[name]
  not input.resource.aws_s3_bucket_server_side_encryption_configuration[name]
  msg := sprintf("S3 bucket '%s' must have server-side encryption configured", [name])
}

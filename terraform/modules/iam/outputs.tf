output "admin_user_arn" {
  description = "ARN of the admin IAM user"
  value       = aws_iam_user.admin.arn
}

output "team_group_name" {
  description = "Name of the IAM team group"
  value       = aws_iam_group.team.name
}

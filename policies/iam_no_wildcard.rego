# Deny wildcard IAM policies
package terraform.iam_no_wildcard

deny[msg] {
  resource := input.resource.aws_iam_user_policy[name]
  policy := json.parse(resource.policy)
  statement := policy.Statement[_]
  statement.Action == "*"
  statement.Effect == "Allow"
  msg := sprintf("IAM user policy '%s' must not use wildcard Action", [name])
}

deny[msg] {
  resource := input.resource.aws_iam_user_policy[name]
  policy := json.parse(resource.policy)
  statement := policy.Statement[_]
  statement.Resource == "*"
  statement.Effect == "Allow"
  msg := sprintf("IAM user policy '%s' must not use wildcard Resource", [name])
}

deny[msg] {
  resource := input.resource.aws_iam_role_policy[name]
  policy := json.parse(resource.policy)
  statement := policy.Statement[_]
  statement.Action == "*"
  statement.Effect == "Allow"
  msg := sprintf("IAM role policy '%s' must not use wildcard Action", [name])
}

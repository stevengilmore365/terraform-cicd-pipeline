# Require VPC flow logs on all VPCs
package terraform.vpc_flow_logs

deny[msg] {
  resource := input.resource.aws_vpc[name]
  flow_logs := {key | input.resource.aws_flow_log[key].vpc_id == resource.id}
  count(flow_logs) == 0
  msg := sprintf("VPC '%s' must have flow logs enabled", [name])
}

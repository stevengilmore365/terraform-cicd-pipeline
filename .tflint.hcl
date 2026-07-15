plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
}

## Not enabled: this is a root config split into topic-named files (storage_box.tf,
## terraform.tf, outputs.tf), not a module with main.tf/variables.tf.
# rule "terraform_standard_module_structure" {
#   enabled = false
# }

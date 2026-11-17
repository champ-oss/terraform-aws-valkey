locals {
  tags = {
    git       = var.git
    cost      = "shared"
    creator   = "terraform"
    component = "valkey"
  }

  name    = coalesce(var.name, lower(var.git))
  user_id = coalesce(var.user_id, local.name) # same rules as the cache name, so the full name is unique and valid

  # ElastiCache stores cache names and user IDs in lowercase and allows up to 40 characters,
  # starting with a letter, with no consecutive or trailing hyphens. Checked by preconditions in
  # valkey.tf so a bad name fails at plan rather than at apply, or replaces the cache every plan.
  id_pattern = "^[a-z][a-z0-9-]{0,39}$"

  access_string = join(" ", concat(
    ["on"],
    [for pattern in var.key_patterns : "~${pattern}"],
    ["&*"], # ElastiCache adds this when no channel permission is given; set it to avoid drift
    var.acl_rules,
  ))
}

data "aws_region" "this" {}

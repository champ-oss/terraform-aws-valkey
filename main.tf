locals {
  tags = {
    git       = var.git
    cost      = "shared"
    creator   = "terraform"
    component = "valkey"
  }

  name    = coalesce(var.name, var.git)
  user_id = coalesce(var.user_id, trim(substr(local.name, 0, 39), "-"))

  access_string = join(" ", concat(
    ["on"],
    [for pattern in var.key_patterns : "~${pattern}"],
    ["&*"], # ElastiCache adds this when no channel permission is given; set it to avoid drift
    var.acl_rules,
  ))
}

data "aws_region" "this" {}

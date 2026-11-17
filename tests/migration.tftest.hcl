# Pins the exact names and access string that dmv-global-clients/terraform/elasticache.tf
# created before it moved to this module. If any of these change, moving that
# stack's state into the module would replace the cache instead of adopting it.

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      region = "us-east-2"
    }
  }

  mock_resource "aws_elasticache_serverless_cache" {
    defaults = {
      arn = "arn:aws:elasticache:us-east-2:111122223333:serverlesscache:mock"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::111122223333:policy/mock"
    }
  }
}

variables {
  git                       = "env-dmv-global"
  vpc_id                    = "vpc-0123456789abcdef0"
  private_subnet_ids        = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  source_security_group_ids = ["sg-0123456789abcdef0", "sg-0123456789abcdef1"]
  role_names                = ["env-dmv-global-ecs-execution"]
  user_id                   = "env-dmv-global-bff"
  iam_policy_name           = "env-dmv-global-global-client-bff-valkey-connect"
  key_patterns              = ["session:*"]
  acl_rules                 = ["+@all", "-@dangerous", "-scan", "-randomkey"]
}

run "dmv_global_clients" {
  assert {
    condition     = aws_elasticache_serverless_cache.this[0].name == "env-dmv-global"
    error_message = "cache name must stay var.git"
  }

  assert {
    condition     = aws_elasticache_user.this[0].access_string == "on ~session:* &* +@all -@dangerous -scan -randomkey"
    error_message = "access string must match the existing user: ${aws_elasticache_user.this[0].access_string}"
  }

  assert {
    condition     = aws_elasticache_user.this[0].user_id == "env-dmv-global-bff" && aws_elasticache_user_group.this[0].user_group_id == "env-dmv-global-bff"
    error_message = "user and user group IDs must be preserved"
  }

  assert {
    condition     = aws_iam_policy.this[0].name == "env-dmv-global-global-client-bff-valkey-connect"
    error_message = "IAM policy name must be preserved"
  }

  assert {
    condition     = aws_security_group.this[0].name_prefix == "env-dmv-global-valkey-"
    error_message = "security group name_prefix must be preserved"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.this[1].description == "Valkey primary and reader endpoints"
    error_message = "ingress rule description must be preserved"
  }
}

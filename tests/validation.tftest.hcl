# Fully mocked. Covers input validation, name preconditions, and the optional inputs.
# Run with: terraform test

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
  vpc_id             = "vpc-0123456789abcdef0"
  private_subnet_ids = ["subnet-0123456789abcdef0"]
  key_patterns       = ["session:*"]
}

run "optional_inputs" {
  variables {
    description              = "sessions"
    cidr_blocks              = ["10.0.0.0/16", "10.1.0.0/16"]
    security_group_ids       = ["sg-0123456789abcdef9"]
    snapshot_retention_limit = 7
    daily_snapshot_time      = "09:00"
    snapshot_arns_to_restore = ["arn:aws:elasticache:us-east-2:111122223333:serverlesscachesnapshot:mock"]
    kms_key_id               = "arn:aws:kms:us-east-2:111122223333:key/mock"
  }

  assert {
    condition     = aws_elasticache_serverless_cache.this[0].description == "sessions"
    error_message = "description not applied"
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.cidr) == 2 && aws_vpc_security_group_ingress_rule.cidr[1].cidr_ipv4 == "10.1.0.0/16" && aws_vpc_security_group_ingress_rule.cidr[0].from_port == 6379 && aws_vpc_security_group_ingress_rule.cidr[0].to_port == 6380
    error_message = "one ingress rule for 6379-6380 per CIDR block"
  }

  assert {
    condition     = length(aws_elasticache_serverless_cache.this[0].security_group_ids) == 2 && contains(aws_elasticache_serverless_cache.this[0].security_group_ids, "sg-0123456789abcdef9")
    error_message = "extra security groups should be attached alongside the module's own"
  }

  assert {
    condition     = aws_elasticache_serverless_cache.this[0].snapshot_retention_limit == 7 && aws_elasticache_serverless_cache.this[0].daily_snapshot_time == "09:00"
    error_message = "snapshot settings not applied"
  }

  assert {
    condition     = aws_elasticache_serverless_cache.this[0].snapshot_arns_to_restore[0] == "arn:aws:elasticache:us-east-2:111122223333:serverlesscachesnapshot:mock"
    error_message = "snapshot restore ARNs not applied"
  }

  assert {
    condition     = output.iam_policy_name == "terraform-aws-valkey-valkey-connect" && jsondecode(output.iam_policy_json).Statement[0].Action == "elasticache:Connect"
    error_message = "policy outputs"
  }
}

run "uppercase_git_is_lowercased" {
  command = plan

  variables {
    git = "My-App"
  }

  assert {
    condition     = aws_elasticache_serverless_cache.this[0].name == "my-app" && aws_elasticache_user.this[0].user_id == "my-app"
    error_message = "names derived from git should be lowercase"
  }

  assert {
    condition     = aws_elasticache_serverless_cache.this[0].tags["git"] == "My-App"
    error_message = "the git tag should keep its case"
  }
}

run "uppercase_name_rejected" {
  command = plan

  variables {
    name = "My-Cache"
  }

  expect_failures = [aws_elasticache_user.this]
}

run "long_git_rejected" {
  command = plan

  variables {
    git     = "env-dmv-global-clients-with-a-very-long-name"
    user_id = "my-cache" # keep the user valid so the cache name check is the one that fails
  }

  expect_failures = [aws_elasticache_serverless_cache.this]
}

run "double_hyphen_name_rejected" {
  command = plan

  variables {
    name    = "my--cache"
    user_id = "my-cache"
  }

  expect_failures = [aws_elasticache_serverless_cache.this]
}

run "digit_first_user_id_rejected" {
  command = plan

  variables {
    user_id = "1user"
  }

  expect_failures = [aws_elasticache_user.this]
}

run "empty_key_patterns_rejected" {
  command = plan

  variables {
    key_patterns = []
  }

  expect_failures = [var.key_patterns]
}

run "tilde_key_pattern_rejected" {
  command = plan

  variables {
    key_patterns = ["~session:*"]
  }

  expect_failures = [var.key_patterns]
}

run "unprefixed_acl_rule_rejected" {
  command = plan

  variables {
    acl_rules = ["-@all", "get"]
  }

  expect_failures = [var.acl_rules]
}

run "empty_acl_rules_rejected" {
  command = plan

  variables {
    acl_rules = []
  }

  expect_failures = [var.acl_rules]
}

run "retention_out_of_range_rejected" {
  command = plan

  variables {
    snapshot_retention_limit = 36
  }

  expect_failures = [var.snapshot_retention_limit]
}

run "snapshot_time_format_rejected" {
  command = plan

  variables {
    daily_snapshot_time = "9:00"
  }

  expect_failures = [var.daily_snapshot_time]
}

run "kms_key_id_not_arn_rejected" {
  command = plan

  variables {
    kms_key_id = "1234abcd-12ab-34cd-56ef-1234567890ab"
  }

  expect_failures = [var.kms_key_id]
}

run "decimal_engine_version_rejected" {
  command = plan

  variables {
    major_engine_version = "8.0"
  }

  expect_failures = [var.major_engine_version]
}

run "invalid_cidr_rejected" {
  command = plan

  variables {
    cidr_blocks = ["10.0.0.0"]
  }

  expect_failures = [var.cidr_blocks]
}

run "ipv6_cidr_rejected" {
  command = plan

  variables {
    cidr_blocks = ["10.0.0.0/16", "2001:db8::/64"]
  }

  expect_failures = [var.cidr_blocks]
}

run "zero_storage_limit_rejected" {
  command = plan

  variables {
    max_data_storage_gb = 0
  }

  expect_failures = [var.max_data_storage_gb]
}

run "empty_subnets_rejected" {
  command = plan

  variables {
    private_subnet_ids = []
  }

  expect_failures = [var.private_subnet_ids]
}

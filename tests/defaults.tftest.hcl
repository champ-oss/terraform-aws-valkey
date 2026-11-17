# Fully mocked. No AWS credentials, no resources, no cost.
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
  vpc_id                    = "vpc-0123456789abcdef0"
  private_subnet_ids        = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  source_security_group_ids = ["sg-0123456789abcdef0"]
  key_patterns              = ["session:*"]
}

run "defaults" {
  assert {
    condition     = aws_elasticache_serverless_cache.this[0].name == "terraform-aws-valkey"
    error_message = "cache name should default to var.git"
  }

  assert {
    condition     = aws_elasticache_serverless_cache.this[0].engine == "valkey"
    error_message = "engine must be valkey"
  }

  assert {
    condition     = aws_elasticache_serverless_cache.this[0].snapshot_retention_limit == 0
    error_message = "snapshots should be off by default"
  }

  assert {
    condition     = length(aws_elasticache_serverless_cache.this[0].cache_usage_limits) == 0
    error_message = "no usage limits should be set by default"
  }

  assert {
    condition     = aws_elasticache_user.this[0].access_string == "on ~session:* &* +@all -@dangerous"
    error_message = "unexpected default access string: ${aws_elasticache_user.this[0].access_string}"
  }

  assert {
    condition     = aws_elasticache_user.this[0].user_id == aws_elasticache_user.this[0].user_name
    error_message = "IAM auth requires user_id == user_name"
  }

  assert {
    condition     = aws_elasticache_user.this[0].authentication_mode[0].type == "iam"
    error_message = "user must use IAM authentication"
  }

  assert {
    condition     = aws_iam_policy.this[0].name == "terraform-aws-valkey-valkey-connect"
    error_message = "unexpected default policy name"
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.this) == 0
    error_message = "no role attachments without role_names"
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 1 && aws_vpc_security_group_ingress_rule.this[0].from_port == 6379 && aws_vpc_security_group_ingress_rule.this[0].to_port == 6380
    error_message = "one ingress rule for 6379-6380 per client security group"
  }

  assert {
    condition     = output.region == "us-east-2"
    error_message = "region output should come from the provider"
  }
}

run "limits" {
  variables {
    name                = "mdg-bff"
    max_data_storage_gb = 10
    max_ecpu_per_second = 1000
    role_names          = ["task-role"]
    key_patterns        = ["mdg:bff:session:*", "mdg:bff:oauth-state:*"]
    acl_rules           = ["-@all", "+get", "+set", "+cluster|nodes"]
  }

  assert {
    condition     = aws_elasticache_serverless_cache.this[0].name == "mdg-bff"
    error_message = "name should override var.git"
  }

  assert {
    condition     = aws_elasticache_serverless_cache.this[0].cache_usage_limits[0].data_storage[0].maximum == 10
    error_message = "storage limit not applied"
  }

  assert {
    condition     = aws_elasticache_serverless_cache.this[0].cache_usage_limits[0].ecpu_per_second[0].maximum == 1000
    error_message = "ECPU limit not applied"
  }

  assert {
    condition     = aws_elasticache_user.this[0].access_string == "on ~mdg:bff:session:* ~mdg:bff:oauth-state:* &* -@all +get +set +cluster|nodes"
    error_message = "unexpected access string: ${aws_elasticache_user.this[0].access_string}"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.this[0].role == "task-role"
    error_message = "policy should attach to the given role"
  }
}

run "disabled" {
  variables {
    enabled = false
  }

  assert {
    condition     = length(aws_elasticache_serverless_cache.this) == 0 && length(aws_security_group.this) == 0 && length(aws_iam_policy.this) == 0
    error_message = "disabled module must create nothing"
  }

  assert {
    condition     = output.endpoint == "" && output.iam_policy_arn == ""
    error_message = "outputs should be empty when disabled"
  }
}

run "long_name_user_id" {
  variables {
    name = "a-very-long-cache-name-that-is-forty-chr"
  }

  assert {
    condition     = length(aws_elasticache_user.this[0].user_id) <= 39 && !endswith(aws_elasticache_user.this[0].user_id, "-")
    error_message = "default user_id must be at most 39 characters and not end with a hyphen"
  }
}

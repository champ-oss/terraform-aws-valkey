# Calls the module the way dmv-global-clients/terraform will once it replaces its own
# elasticache.tf with this module, and checks the BFF still gets everything it reads:
# VALKEY_HOST, VALKEY_PORT, VALKEY_USERNAME, VALKEY_CACHE_NAME and VALKEY_REGION.
# It keeps the names its user, user group and IAM policy already have, so moving them into the
# module updates them in place rather than replacing them.

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      region = "us-east-2"
    }
  }

  mock_resource "aws_elasticache_serverless_cache" {
    defaults = {
      arn = "arn:aws:elasticache:us-east-2:111122223333:serverlesscache:mock"
      endpoint = [{
        address = "env-dmv-global-mock.serverless.use2.cache.amazonaws.com"
        port    = 6379
      }]
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::111122223333:policy/mock"
    }
  }
}

# dmv-global-clients' variables, passed straight through.
variables {
  git                       = "env-dmv-global"
  vpc_id                    = "vpc-0123456789abcdef0"
  private_subnet_ids        = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  source_security_group_ids = ["sg-0123456789abcdef0", "sg-0123456789abcdef1"]
  role_names                = ["env-dmv-global-ecs-execution"] # terraform-aws-app runs the task as its execution role, so this is the role that signs the IAM token
  key_patterns              = ["session:*"]
  acl_rules                 = ["+@all", "-@dangerous", "-scan", "-randomkey"]
  user_id                   = "env-dmv-global-bff"
  iam_policy_name           = "env-dmv-global-global-client-bff-valkey-connect"
  tags = {
    cost    = "shared"
    creator = "terraform"
  }
}

run "dmv_global_clients" {
  assert {
    condition     = aws_elasticache_user.this[0].user_id == "env-dmv-global-bff" && output.user_group_id == "env-dmv-global-bff"
    error_message = "the user and user group should keep their names, since a new name replaces them"
  }

  assert {
    condition     = output.iam_policy_name == "env-dmv-global-global-client-bff-valkey-connect"
    error_message = "the connect policy should keep its name, since a new name replaces it"
  }

  assert {
    condition     = aws_elasticache_user.this[0].access_string == "on ~session:* &* +@all -@dangerous -scan -randomkey"
    error_message = "the BFF's user should keep its current permissions: ${aws_elasticache_user.this[0].access_string}"
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 2
    error_message = "each ECS task security group should get an ingress rule"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.this[0].role == "env-dmv-global-ecs-execution"
    error_message = "the connect policy should attach to the ECS execution role, which terraform-aws-app also uses as the task role"
  }

  assert {
    condition     = output.endpoint == "env-dmv-global-mock.serverless.use2.cache.amazonaws.com" && output.port == 6379
    error_message = "VALKEY_HOST and VALKEY_PORT come from endpoint and port"
  }

  assert {
    condition     = output.user_name == "env-dmv-global-bff" && output.cache_name == "env-dmv-global" && output.region == "us-east-2"
    error_message = "VALKEY_USERNAME, VALKEY_CACHE_NAME and VALKEY_REGION come from user_name, cache_name and region"
  }
}

# dmv-global-clients falls back to "" and 6379 when disabled; the outputs do the same,
# so its container environment doesn't need try() around them.
run "dmv_global_clients_disabled" {
  variables {
    enabled = false
  }

  assert {
    condition     = output.endpoint == "" && output.port == 6379 && output.user_name == "" && output.cache_name == ""
    error_message = "disabled outputs should match dmv-global-clients' current fallbacks"
  }
}


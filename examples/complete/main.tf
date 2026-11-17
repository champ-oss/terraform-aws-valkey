data "aws_vpcs" "this" {
  tags = {
    purpose = "vega"
  }
}

data "aws_subnets" "this" {
  tags = {
    purpose = "vega"
    Type    = "Private"
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpcs.this.ids[0]]
  }
}

resource "random_id" "this" {
  byte_length = 2
}

locals {
  git = "terraform-aws-valkey-${random_id.this.hex}"
}

# Stands in for the ECS task security group of the application using the cache.
resource "aws_security_group" "this" {
  name_prefix = "${local.git}-client-"
  vpc_id      = data.aws_vpcs.this.ids[0]
}

# Stands in for the ECS task role that signs IAM auth tokens.
resource "aws_iam_role" "this" {
  name_prefix = "valkey-client-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

module "this" {
  source                    = "../../"
  git                       = local.git
  vpc_id                    = data.aws_vpcs.this.ids[0]
  private_subnet_ids        = data.aws_subnets.this.ids
  source_security_group_ids = [aws_security_group.this.id]
  role_names                = [aws_iam_role.this.name]
  key_patterns              = ["app:session:*", "app:oauth-state:*"]
  acl_rules                 = ["-@all", "+get", "+set", "+del", "+getdel", "+ping", "+hello", "+info", "+cluster|nodes", "+client|setinfo"]
  max_data_storage_gb       = 1
  max_ecpu_per_second       = 1000
}

output "enabled" {
  description = "Whether the module created resources"
  value       = module.this.enabled
}

output "cache_name" {
  description = "Serverless cache name"
  value       = module.this.cache_name
}

output "user_name" {
  description = "IAM-authenticated Valkey user name"
  value       = module.this.user_name
}

output "iam_policy_arn" {
  description = "elasticache:Connect policy ARN"
  value       = module.this.iam_policy_arn
}

output "role_name" {
  description = "Client role the policy is attached to"
  value       = aws_iam_role.this.name
}

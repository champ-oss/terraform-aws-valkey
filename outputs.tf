output "enabled" {
  description = "Whether the module created resources"
  value       = var.enabled
}

output "endpoint" {
  description = "Primary endpoint hostname (reads and writes)"
  value       = try(aws_elasticache_serverless_cache.this[0].endpoint[0].address, "")
}

output "port" {
  description = "Primary endpoint port"
  value       = try(aws_elasticache_serverless_cache.this[0].endpoint[0].port, 6379)
}

output "reader_endpoint" {
  description = "Reader endpoint hostname (eventually consistent reads)"
  value       = try(aws_elasticache_serverless_cache.this[0].reader_endpoint[0].address, "")
}

output "reader_port" {
  description = "Reader endpoint port"
  value       = try(aws_elasticache_serverless_cache.this[0].reader_endpoint[0].port, 6380)
}

output "cache_name" {
  description = "Serverless cache name. Clients need it to sign IAM auth tokens."
  value       = try(aws_elasticache_serverless_cache.this[0].name, "")
}

output "cache_arn" {
  description = "Serverless cache ARN"
  value       = try(aws_elasticache_serverless_cache.this[0].arn, "")
}

output "user_name" {
  description = "IAM-authenticated Valkey user name"
  value       = try(aws_elasticache_user.this[0].user_name, "")
}

output "user_arn" {
  description = "IAM-authenticated Valkey user ARN"
  value       = try(aws_elasticache_user.this[0].arn, "")
}

output "user_group_id" {
  description = "Valkey user group ID"
  value       = try(aws_elasticache_user_group.this[0].user_group_id, "")
}

output "security_group_id" {
  description = "Security group attached to the cache"
  value       = try(aws_security_group.this[0].id, "")
}

output "iam_policy_arn" {
  description = "Policy granting elasticache:Connect to this cache and user. Attach to any role that connects."
  value       = try(aws_iam_policy.this[0].arn, "")
}

output "iam_policy_name" {
  description = "Name of the elasticache:Connect policy"
  value       = try(aws_iam_policy.this[0].name, "")
}

output "iam_policy_json" {
  description = "The elasticache:Connect policy document, for roles that use inline policies instead of attachments"
  value       = try(aws_iam_policy.this[0].policy, "")
}

output "user_group_arn" {
  description = "Valkey user group ARN"
  value       = try(aws_elasticache_user_group.this[0].arn, "")
}

output "major_engine_version" {
  description = "Major Valkey version of the cache"
  value       = try(aws_elasticache_serverless_cache.this[0].major_engine_version, "")
}

output "full_engine_version" {
  description = "Full Valkey version the cache is running"
  value       = try(aws_elasticache_serverless_cache.this[0].full_engine_version, "")
}

output "region" {
  description = "Region of the cache. Clients need it to sign IAM auth tokens."
  value       = data.aws_region.this.region
}

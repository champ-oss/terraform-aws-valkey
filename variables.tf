variable "git" {
  description = "Name of the Git repo or environment. Used for tagging and as the default resource name."
  type        = string
  default     = "terraform-aws-valkey"
}

variable "name" {
  description = "Serverless cache name. Defaults to var.git. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#name"
  type        = string
  default     = null
}

variable "enabled" {
  description = "Create the resources in this module"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC for the cache security group. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group#vpc_id"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the cache endpoints. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#subnet_ids"
  type        = list(string)
}

variable "source_security_group_ids" {
  description = "Client security groups allowed to reach the cache on 6379 (primary) and 6380 (reader)"
  type        = list(string)
  default     = []
}

variable "major_engine_version" {
  description = "https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#major_engine_version"
  type        = string
  default     = "8"
}

variable "kms_key_id" {
  description = "Customer managed KMS key ARN for encryption at rest. Null uses the AWS owned key. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#kms_key_id"
  type        = string
  default     = null
}

variable "snapshot_retention_limit" {
  description = "Days to keep automatic snapshots. 0 disables them. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#snapshot_retention_limit"
  type        = number
  default     = 0
}

variable "daily_snapshot_time" {
  description = "Daily UTC snapshot start time (HH:MM). Only used when snapshot_retention_limit > 0. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#daily_snapshot_time"
  type        = string
  default     = null
}

variable "max_data_storage_gb" {
  description = "Upper limit on stored data in GB. Null means no limit."
  type        = number
  default     = null
}

variable "max_ecpu_per_second" {
  description = "Upper limit on ElastiCache Processing Units per second. Null means no limit."
  type        = number
  default     = null
}

variable "user_id" {
  description = "IAM-authenticated Valkey user ID and user name. Defaults to the cache name, truncated to 39 characters."
  type        = string
  default     = null
}

variable "key_patterns" {
  description = "Key glob patterns the user may access, without the ACL '~' prefix, for example [\"session:*\"]"
  type        = list(string)
}

variable "acl_rules" {
  description = "Ordered ACL command rules, each starting with + or -, for example [\"-@all\", \"+get\", \"+set\"]. Rendered after the key patterns in the access string."
  type        = list(string)
  default     = ["+@all", "-@dangerous"]
}

variable "role_names" {
  description = "IAM role names that receive the elasticache:Connect policy. Leave empty and attach iam_policy_arn yourself if preferred."
  type        = list(string)
  default     = []
}

variable "iam_policy_name" {
  description = "Name of the elasticache:Connect IAM policy. Defaults to <name>-valkey-connect."
  type        = string
  default     = null
}


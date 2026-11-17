variable "git" {
  description = "Name of the Git repo or environment. Used for tagging and, lowercased, as the default resource name."
  type        = string
  default     = "terraform-aws-valkey"

  validation {
    condition     = length(trimspace(var.git)) > 0
    error_message = "git must not be blank."
  }
}

variable "name" {
  description = "Serverless cache name: up to 40 lowercase letters, digits and hyphens, starting with a letter. Defaults to var.git, lowercased. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#name"
  type        = string
  default     = null
}

variable "enabled" {
  description = "Create the resources in this module"
  type        = bool
  default     = true
  nullable    = false
}

variable "tags" {
  description = "Tags to assign to resources"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "vpc_id" {
  description = "VPC for the cache security group. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group#vpc_id"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the cache endpoints. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#subnet_ids"
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.private_subnet_ids) > 0
    error_message = "private_subnet_ids must list at least one subnet."
  }
}

variable "source_security_group_ids" {
  description = "Client security groups allowed to reach the cache on 6379 (primary) and 6380 (reader)"
  type        = list(string)
  default     = []
  nullable    = false
}

variable "cidr_blocks" {
  description = "IPv4 CIDR blocks allowed to reach the cache on 6379 (primary) and 6380 (reader)"
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for cidr in var.cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "cidr_blocks must contain only IPv4 CIDR blocks, such as 10.0.0.0/16."
  }
}

variable "security_group_ids" {
  description = "Existing security groups to attach to the cache, in addition to the one this module creates"
  type        = list(string)
  default     = []
  nullable    = false
}

variable "description" {
  description = "Description of the serverless cache, up to 255 characters. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#description"
  type        = string
  default     = null

  validation {
    condition     = var.description == null || try(length(var.description) <= 255, false)
    error_message = "description must be 255 characters or fewer."
  }
}

variable "major_engine_version" {
  description = "https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#major_engine_version"
  type        = string
  default     = "8"
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]+$", var.major_engine_version))
    error_message = "major_engine_version must be a whole major version, such as \"8\", not \"8.0\"."
  }
}

variable "kms_key_id" {
  description = "Customer managed KMS key ARN for encryption at rest. Null uses the AWS owned key. Changing it replaces the cache. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#kms_key_id"
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null || can(regex("^arn:aws[a-z-]*:kms:", var.kms_key_id))
    error_message = "kms_key_id must be a KMS key ARN, such as arn:aws:kms:us-east-2:111122223333:key/<id>."
  }
}

variable "snapshot_retention_limit" {
  description = "Days to keep automatic snapshots, from 0 to 35. 0 disables them. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#snapshot_retention_limit"
  type        = number
  default     = 0
  nullable    = false

  validation {
    condition     = var.snapshot_retention_limit >= 0 && var.snapshot_retention_limit <= 35 && floor(var.snapshot_retention_limit) == var.snapshot_retention_limit
    error_message = "snapshot_retention_limit must be a whole number from 0 to 35."
  }
}

variable "daily_snapshot_time" {
  description = "Daily UTC snapshot start time (HH:MM). Only used when snapshot_retention_limit > 0. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#daily_snapshot_time"
  type        = string
  default     = null

  validation {
    condition     = var.daily_snapshot_time == null || can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", var.daily_snapshot_time))
    error_message = "daily_snapshot_time must be a 24-hour UTC time as HH:MM, such as 09:00."
  }
}

variable "snapshot_arns_to_restore" {
  description = "Snapshot ARNs to create the cache from. Changing it replaces the cache. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#snapshot_arns_to_restore"
  type        = list(string)
  default     = null
}

variable "max_data_storage_gb" {
  description = "Upper limit on stored data in GB. Null means no limit."
  type        = number
  default     = null

  validation {
    condition     = var.max_data_storage_gb == null || try(var.max_data_storage_gb > 0 && floor(var.max_data_storage_gb) == var.max_data_storage_gb, false)
    error_message = "max_data_storage_gb must be a whole number of GB above 0."
  }
}

variable "max_ecpu_per_second" {
  description = "Upper limit on ElastiCache Processing Units per second. Null means no limit."
  type        = number
  default     = null

  validation {
    condition     = var.max_ecpu_per_second == null || try(var.max_ecpu_per_second > 0 && floor(var.max_ecpu_per_second) == var.max_ecpu_per_second, false)
    error_message = "max_ecpu_per_second must be a whole number above 0."
  }
}

variable "user_id" {
  description = "IAM-authenticated Valkey user ID and user name: up to 40 lowercase letters, digits and hyphens, starting with a letter. Defaults to the cache name, truncated to 39 characters."
  type        = string
  default     = null
}

variable "key_patterns" {
  description = "Key glob patterns the user may access, without the ACL '~' prefix, for example [\"session:*\"]"
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.key_patterns) > 0
    error_message = "key_patterns must list at least one pattern, such as \"session:*\". Use \"*\" for every key."
  }

  validation {
    condition     = alltrue([for pattern in var.key_patterns : can(regex("^[^~\\s]\\S*$", pattern))])
    error_message = "Each key_patterns entry must be a non-empty pattern without spaces or the leading '~', which the module adds."
  }
}

variable "acl_rules" {
  description = "Ordered ACL command rules, each starting with + or -, for example [\"-@all\", \"+get\", \"+set\"]. Rendered after the key patterns in the access string."
  type        = list(string)
  default     = ["+@all", "-@dangerous"]
  nullable    = false

  validation {
    condition     = length(var.acl_rules) > 0 && alltrue([for rule in var.acl_rules : can(regex("^[+-]\\S+$", rule))])
    error_message = "acl_rules must list at least one rule, and each must start with + or - and contain no spaces, such as \"+get\" or \"-@dangerous\"."
  }
}

variable "role_names" {
  description = "IAM role names that receive the elasticache:Connect policy. Leave empty and attach iam_policy_arn yourself if preferred."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "iam_policy_name" {
  description = "Name of the elasticache:Connect IAM policy. Defaults to <name>-valkey-connect."
  type        = string
  default     = null
}

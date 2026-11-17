resource "aws_elasticache_serverless_cache" "this" {
  count                    = var.enabled ? 1 : 0
  engine                   = "valkey"
  name                     = local.name
  description              = var.description
  major_engine_version     = var.major_engine_version
  kms_key_id               = var.kms_key_id
  snapshot_retention_limit = var.snapshot_retention_limit
  daily_snapshot_time      = var.snapshot_retention_limit > 0 ? var.daily_snapshot_time : null
  snapshot_arns_to_restore = var.snapshot_arns_to_restore
  security_group_ids       = concat([aws_security_group.this[0].id], var.security_group_ids)
  subnet_ids               = var.private_subnet_ids
  user_group_id            = aws_elasticache_user_group.this[0].user_group_id
  tags                     = merge(local.tags, var.tags)

  dynamic "cache_usage_limits" {
    for_each = var.max_data_storage_gb != null || var.max_ecpu_per_second != null ? [1] : []
    content {
      dynamic "data_storage" {
        for_each = var.max_data_storage_gb != null ? [var.max_data_storage_gb] : []
        content {
          maximum = data_storage.value
          unit    = "GB"
        }
      }

      dynamic "ecpu_per_second" {
        for_each = var.max_ecpu_per_second != null ? [var.max_ecpu_per_second] : []
        content {
          maximum = ecpu_per_second.value
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = can(regex(local.id_pattern, local.name)) && !strcontains(local.name, "--") && !endswith(local.name, "-")
      error_message = "Cache name \"${local.name}\" must be 1-40 lowercase letters, digits and hyphens, start with a letter, and have no consecutive or trailing hyphens. Set name, or change git."
    }
  }
}

# IAM authentication: clients sign a short-lived token with their role instead of
# using a password, so nothing secret is stored in SSM or state.
resource "aws_elasticache_user" "this" {
  count         = var.enabled ? 1 : 0
  user_id       = local.user_id
  user_name     = local.user_id # must equal user_id for IAM authentication
  access_string = local.access_string
  engine        = "valkey"
  tags          = merge(local.tags, var.tags)

  authentication_mode {
    type = "iam"
  }

  lifecycle {
    precondition {
      condition     = can(regex(local.id_pattern, local.user_id)) && !strcontains(local.user_id, "--") && !endswith(local.user_id, "-")
      error_message = "User ID \"${local.user_id}\" must be 1-40 lowercase letters, digits and hyphens, start with a letter, and have no consecutive or trailing hyphens. Set user_id, or change name or git."
    }
  }
}

resource "aws_elasticache_user_group" "this" {
  count         = var.enabled ? 1 : 0
  engine        = "valkey"
  user_group_id = local.user_id
  user_ids      = [aws_elasticache_user.this[0].user_id]
  tags          = merge(local.tags, var.tags)
}

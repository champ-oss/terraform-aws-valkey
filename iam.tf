resource "aws_iam_policy" "this" {
  count = var.enabled ? 1 : 0
  name  = coalesce(var.iam_policy_name, "${local.name}-valkey-connect")
  # Built inline rather than with a data source, which would be deferred to apply
  # (and show the policy as changing) whenever the cache or user has pending changes.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "elasticache:Connect"
      Resource = [
        aws_elasticache_serverless_cache.this[0].arn,
        aws_elasticache_user.this[0].arn,
      ]
    }]
  })
  tags = merge(local.tags, var.tags)
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = var.enabled ? length(var.role_names) : 0
  role       = var.role_names[count.index]
  policy_arn = aws_iam_policy.this[0].arn
}

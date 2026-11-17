data "aws_iam_policy_document" "this" {
  count = var.enabled ? 1 : 0

  statement {
    actions = ["elasticache:Connect"]
    resources = [
      aws_elasticache_serverless_cache.this[0].arn,
      aws_elasticache_user.this[0].arn,
    ]
  }
}

resource "aws_iam_policy" "this" {
  count  = var.enabled ? 1 : 0
  name   = coalesce(var.iam_policy_name, "${local.name}-valkey-connect")
  policy = data.aws_iam_policy_document.this[0].json
  tags   = merge(local.tags, var.tags)
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = var.enabled ? length(var.role_names) : 0
  role       = var.role_names[count.index]
  policy_arn = aws_iam_policy.this[0].arn
}

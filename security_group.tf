resource "aws_security_group" "this" {
  count       = var.enabled ? 1 : 0
  name_prefix = "${local.name}-valkey-"
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, var.tags)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  count                        = var.enabled ? length(var.source_security_group_ids) : 0
  security_group_id            = aws_security_group.this[0].id
  referenced_security_group_id = var.source_security_group_ids[count.index]
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6380
  description                  = "Valkey primary and reader endpoints"
  tags                         = merge(local.tags, var.tags)
}

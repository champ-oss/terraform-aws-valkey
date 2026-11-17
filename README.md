# terraform-aws-valkey

Serverless Amazon ElastiCache for Valkey with IAM authentication.

- **Serverless:** no nodes to size or patch. Optional caps on storage and ECPU.
- **IAM authentication:** clients sign a short-lived token with their IAM role. There is no password in SSM or Terraform state.
- **Least privilege:** the Valkey user only gets the key patterns and ACL command rules you pass.
- **Private:** the cache sits in private subnets, and only the client security groups you list can reach ports 6379 (primary) and 6380 (reader).

## Usage

```hcl
module "valkey" {
  source                    = "github.com/champ-oss/terraform-aws-valkey.git?ref=<version>"
  git                       = local.name
  name                      = "${local.name}-bff"
  vpc_id                    = local.vpc_id
  private_subnet_ids        = local.private_subnet_ids
  source_security_group_ids = [module.core.ecs_app_security_group]
  role_names                = [module.core.execution_ecs_role_name]

  key_patterns = ["session:*"]
  acl_rules    = ["-@all", "+get", "+set", "+del", "+ping", "+hello", "+info", "+cluster|nodes", "+client|setinfo"]

  max_data_storage_gb = 10
  max_ecpu_per_second = 1000
}
```

The client needs `endpoint`, `port`, `user_name`, `cache_name` and `region` to connect. It must use TLS, a cluster-mode client, and an IAM auth token generated with SigV4 for `cache_name` and `user_name`.

## Access string

The user's access string is built as `on ~<key_patterns...> <acl_rules...>`. The defaults give `on ~<pattern> +@all -@dangerous`. For a stricter user, start `acl_rules` with `-@all` and list the commands the client needs. Cluster-mode clients usually need `hello`, `info`, `cluster|nodes` and `client|setinfo` as well as the data commands.

## Testing

- `terraform test` runs a fully mocked suite with no AWS credentials.
- `examples/complete` is applied against AWS by the `module` workflow, then `test.sh` checks the cache, the user and the policy attachment.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

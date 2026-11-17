# terraform-aws-valkey

Serverless Amazon ElastiCache for Valkey with IAM authentication.

- **Serverless:** no nodes to size or patch. Optional caps on storage and ECPU.
- **IAM authentication:** clients sign a short-lived token with their IAM role. There is no password in SSM or Terraform state.
- **Least privilege:** the Valkey user only gets the key patterns and ACL command rules you pass.
- **Private:** the cache sits in private subnets, and only the client security groups and CIDR blocks you list can reach ports 6379 (primary) and 6380 (reader).
- **No fallback login:** the cache's user group holds only the IAM user, so there is no default or password user to connect as.

## Usage

```hcl
module "valkey" {
  source                    = "github.com/champ-oss/terraform-aws-valkey.git?ref=<version>"
  git                       = local.name
  name                      = "${local.name}-bff"
  vpc_id                    = local.vpc_id
  private_subnet_ids        = local.private_subnet_ids
  source_security_group_ids = [module.core.ecs_app_security_group]
  role_names                = [module.core.execution_ecs_role_name] # the role the app runs as: terraform-aws-app also uses the execution role as the task role

  key_patterns = ["session:*"]
  acl_rules    = ["-@all", "+get", "+set", "+del", "+ping", "+hello", "+info", "+cluster|nodes", "+client|setinfo"]

  max_data_storage_gb = 10
  max_ecpu_per_second = 1000
}
```

The client needs `endpoint`, `port`, `user_name`, `cache_name` and `region` to connect. It must use TLS, a cluster-mode client, and an IAM auth token generated with SigV4 for `cache_name` and `user_name`.

## Naming

The cache is named `name`, or `git` lowercased when `name` is not set. The user ID, which is also the user name and user group ID, defaults to the cache name, and `user_id` overrides it. ElastiCache stores both in lowercase and allows up to 40 characters, so they must be lowercase letters, digits and hyphens, start with a letter, and not contain `--` or end in `-`. The plan fails if they don't. Each cache in an account and region needs its own name.

Changing the cache name replaces the cache. Changing the user ID only replaces the user and user group: the new ones are created and the cache is switched to them before the old ones are deleted, since ElastiCache won't delete a user group that a cache still uses.

## Access string

The user's access string is built as `on ~<key_patterns...> &* <acl_rules...>`. The defaults give `on ~<pattern> &* +@all -@dangerous -scan -randomkey`. Key patterns only restrict commands that name keys, so `scan` and `randomkey`, which aren't in `@dangerous`, are blocked by default because they would list key names outside `key_patterns`. If the client needs `scan`, pass your own `acl_rules` without `-scan`. `&*` (all pub/sub channels) is what ElastiCache adds when no channel permission is given, so it is set explicitly to avoid drift. For a stricter user, start `acl_rules` with `-@all` and list the commands the client needs. Cluster-mode clients usually need `hello`, `info`, `cluster|nodes` and `client|setinfo` as well as the data commands.

## Testing

- `terraform test` runs a fully mocked suite with no AWS credentials.
- `examples/complete` is applied against AWS by the `module` workflow, then `test.sh` checks the cache, that its user group holds only the IAM user, and the policy attachment.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.73.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_elasticache_serverless_cache.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache) | resource |
| [aws_elasticache_user.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_user) | resource |
| [aws_elasticache_user_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_user_group) | resource |
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_ingress_rule.cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acl_rules"></a> [acl\_rules](#input\_acl\_rules) | Ordered ACL command rules, each starting with + or -, for example ["-@all", "+get", "+set"]. Rendered after the key patterns in the access string. The default blocks @dangerous plus scan and randomkey, which list key names regardless of key\_patterns. | `list(string)` | <pre>[<br>  "+@all",<br>  "-@dangerous",<br>  "-scan",<br>  "-randomkey"<br>]</pre> | no |
| <a name="input_cidr_blocks"></a> [cidr\_blocks](#input\_cidr\_blocks) | IPv4 CIDR blocks allowed to reach the cache on 6379 (primary) and 6380 (reader) | `list(string)` | `[]` | no |
| <a name="input_daily_snapshot_time"></a> [daily\_snapshot\_time](#input\_daily\_snapshot\_time) | Daily UTC snapshot start time (HH:MM). Only used when snapshot\_retention\_limit > 0. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#daily_snapshot_time | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the serverless cache, up to 255 characters. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#description | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Create the resources in this module | `bool` | `true` | no |
| <a name="input_git"></a> [git](#input\_git) | Name of the Git repo or environment. Used for tagging and, lowercased, as the default resource name. | `string` | `"terraform-aws-valkey"` | no |
| <a name="input_iam_policy_name"></a> [iam\_policy\_name](#input\_iam\_policy\_name) | Name of the elasticache:Connect IAM policy. Defaults to <name>-valkey-connect. | `string` | `null` | no |
| <a name="input_key_patterns"></a> [key\_patterns](#input\_key\_patterns) | Key glob patterns the user may access, without the ACL '~' prefix, for example ["session:*"] | `list(string)` | n/a | yes |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Customer managed KMS key ARN for encryption at rest. Null uses the AWS owned key. Changing it replaces the cache. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#kms_key_id | `string` | `null` | no |
| <a name="input_major_engine_version"></a> [major\_engine\_version](#input\_major\_engine\_version) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#major_engine_version | `string` | `"8"` | no |
| <a name="input_max_data_storage_gb"></a> [max\_data\_storage\_gb](#input\_max\_data\_storage\_gb) | Upper limit on stored data in GB. Null means no limit. | `number` | `null` | no |
| <a name="input_max_ecpu_per_second"></a> [max\_ecpu\_per\_second](#input\_max\_ecpu\_per\_second) | Upper limit on ElastiCache Processing Units per second. Null means no limit. | `number` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Serverless cache name: up to 40 lowercase letters, digits and hyphens, starting with a letter. Defaults to var.git, lowercased. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#name | `string` | `null` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private subnets for the cache endpoints. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#subnet_ids | `list(string)` | n/a | yes |
| <a name="input_role_names"></a> [role\_names](#input\_role\_names) | IAM role names that receive the elasticache:Connect policy. Use the role the client runs as (the ECS task role, not only the execution role); terraform-aws-app uses one role for both. Leave empty and attach iam\_policy\_arn yourself if preferred. | `list(string)` | `[]` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Existing security groups to attach to the cache, in addition to the one this module creates | `list(string)` | `[]` | no |
| <a name="input_snapshot_arns_to_restore"></a> [snapshot\_arns\_to\_restore](#input\_snapshot\_arns\_to\_restore) | Snapshot ARNs to create the cache from. Changing it replaces the cache. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#snapshot_arns_to_restore | `list(string)` | `null` | no |
| <a name="input_snapshot_retention_limit"></a> [snapshot\_retention\_limit](#input\_snapshot\_retention\_limit) | Days to keep automatic snapshots, from 0 to 35. 0 disables them. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache#snapshot_retention_limit | `number` | `0` | no |
| <a name="input_source_security_group_ids"></a> [source\_security\_group\_ids](#input\_source\_security\_group\_ids) | Client security groups allowed to reach the cache on 6379 (primary) and 6380 (reader) | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to assign to resources | `map(string)` | `{}` | no |
| <a name="input_user_id"></a> [user\_id](#input\_user\_id) | IAM-authenticated Valkey user ID and user name: up to 40 lowercase letters, digits and hyphens, starting with a letter. Defaults to the cache name. | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC for the cache security group. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group#vpc_id | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cache_arn"></a> [cache\_arn](#output\_cache\_arn) | Serverless cache ARN |
| <a name="output_cache_name"></a> [cache\_name](#output\_cache\_name) | Serverless cache name. Clients need it to sign IAM auth tokens. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether the module created resources |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Primary endpoint hostname (reads and writes) |
| <a name="output_full_engine_version"></a> [full\_engine\_version](#output\_full\_engine\_version) | Full Valkey version the cache is running |
| <a name="output_iam_policy_arn"></a> [iam\_policy\_arn](#output\_iam\_policy\_arn) | Policy granting elasticache:Connect to this cache and user. Attach to any role that connects. |
| <a name="output_iam_policy_json"></a> [iam\_policy\_json](#output\_iam\_policy\_json) | The elasticache:Connect policy document, for roles that use inline policies instead of attachments |
| <a name="output_iam_policy_name"></a> [iam\_policy\_name](#output\_iam\_policy\_name) | Name of the elasticache:Connect policy |
| <a name="output_major_engine_version"></a> [major\_engine\_version](#output\_major\_engine\_version) | Major Valkey version of the cache |
| <a name="output_port"></a> [port](#output\_port) | Primary endpoint port |
| <a name="output_reader_endpoint"></a> [reader\_endpoint](#output\_reader\_endpoint) | Reader endpoint hostname (eventually consistent reads) |
| <a name="output_reader_port"></a> [reader\_port](#output\_reader\_port) | Reader endpoint port |
| <a name="output_region"></a> [region](#output\_region) | Region of the cache. Clients need it to sign IAM auth tokens. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security group attached to the cache |
| <a name="output_user_arn"></a> [user\_arn](#output\_user\_arn) | IAM-authenticated Valkey user ARN |
| <a name="output_user_group_arn"></a> [user\_group\_arn](#output\_user\_group\_arn) | Valkey user group ARN |
| <a name="output_user_group_id"></a> [user\_group\_id](#output\_user\_group\_id) | Valkey user group ID |
| <a name="output_user_name"></a> [user\_name](#output\_user\_name) | IAM-authenticated Valkey user name |
<!-- END_TF_DOCS -->

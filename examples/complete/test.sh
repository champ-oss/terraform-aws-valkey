set -e

if [ "$ENABLED" != "true" ]; then
  echo "module is disabled, no resources created for this test"
  exit 0
fi

# The runner is outside the VPC, so this checks the control plane rather than
# opening a connection: the cache is up, IAM is the only way in, the IAM user is
# active, and the connect policy is attached to the client role.

STATUS=$(aws elasticache describe-serverless-caches \
  --serverless-cache-name "$CACHE_NAME" \
  --query 'ServerlessCaches[0].Status' --output text)
echo "cache status=$STATUS"
[ "$STATUS" = "available" ]

ENGINE=$(aws elasticache describe-serverless-caches \
  --serverless-cache-name "$CACHE_NAME" \
  --query 'ServerlessCaches[0].Engine' --output text)
echo "engine=$ENGINE"
[ "$ENGINE" = "valkey" ]

# Without a user group the cache would accept the passwordless default user.
CACHE_USER_GROUP=$(aws elasticache describe-serverless-caches \
  --serverless-cache-name "$CACHE_NAME" \
  --query 'ServerlessCaches[0].UserGroupId' --output text)
echo "cache user group=$CACHE_USER_GROUP"
[ "$CACHE_USER_GROUP" = "$USER_GROUP_ID" ]

# The group must hold only the IAM user: no default or password user to fall back on.
GROUP_USERS=$(aws elasticache describe-user-groups \
  --user-group-id "$USER_GROUP_ID" \
  --query 'UserGroups[0].UserIds' --output text)
echo "user group members=$GROUP_USERS"
[ "$GROUP_USERS" = "$USER_NAME" ]

AUTH=$(aws elasticache describe-users \
  --user-id "$USER_NAME" \
  --query 'Users[0].Authentication.Type' --output text)
echo "user authentication=$AUTH"
[ "$AUTH" = "iam" ]

USER_STATUS=$(aws elasticache describe-users \
  --user-id "$USER_NAME" \
  --query 'Users[0].Status' --output text)
echo "user status=$USER_STATUS"
[ "$USER_STATUS" = "active" ]

ATTACHED=$(aws iam list-attached-role-policies \
  --role-name "$ROLE_NAME" \
  --query "length(AttachedPolicies[?PolicyArn=='$IAM_POLICY_ARN'])" --output text)
echo "policy attached=$ATTACHED"
[ "$ATTACHED" = "1" ]

echo "all checks passed"

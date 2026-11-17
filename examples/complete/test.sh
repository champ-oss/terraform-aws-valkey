set -e

if [ "$ENABLED" != "true" ]; then
  echo "module is disabled, no resources created for this test"
  exit 0
fi

# The runner is outside the VPC, so this checks the control plane rather than
# opening a connection: the cache is up, the IAM user is active and wired to it,
# and the connect policy is attached to the client role.

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

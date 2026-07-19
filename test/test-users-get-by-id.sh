#!/usr/bin/env bash
#
# test-users-get-by-id.sh — GET /api/users/{id} (admin only)
#
# Usage:
#   ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=... ./test-users-get-by-id.sh

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

echo "=========================================="
echo " GET /api/users/{id}"
echo " Target: ${BASE_URL}"
echo "=========================================="

STAMP=$(date +%s)
TARGET_EMAIL="target.${STAMP}@example.com"
OTHER_EMAIL="requester.${STAMP}@example.com"
PASSWORD="Str0ngPassw0rd!"

info "Seeding a target user (the one being looked up) and a non-admin requester"
TARGET_CREATE=$(curl -s -X POST "${BASE_URL}/api/auth/register" \
  --data-urlencode "name=Target User" \
  --data-urlencode "email=${TARGET_EMAIL}" \
  --data-urlencode "password=${PASSWORD}")
TARGET_ID=$(extract_json_field "$TARGET_CREATE" "id")

register_user "Requester" "$OTHER_EMAIL" "$PASSWORD" > /dev/null
OTHER_RESULT=$(login_user "$OTHER_EMAIL" "$PASSWORD")
OTHER_TOKEN="${OTHER_RESULT##*|}"

if [ -z "$TARGET_ID" ] || [ -z "$OTHER_TOKEN" ]; then
  fail "Could not seed target user or requester token — aborting"
  print_summary
fi

# 1. Unauthenticated -> 401/403
info "GET without a token"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/users/${TARGET_ID}")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
  pass "Unauthenticated request rejected (got ${STATUS})"
else
  fail "Unauthenticated request expected 401/403, got ${STATUS}"
fi

# 2. Non-admin user -> should be denied
info "GET as a non-admin user"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/users/${TARGET_ID}" \
  -H "Authorization: Bearer ${OTHER_TOKEN}")
assert_denied "$STATUS" "Non-admin user rejected"

ADMIN_TOKEN=$(get_admin_token)
if [ -n "$ADMIN_TOKEN" ]; then
  # 3. Admin, valid id -> 200
  info "GET as admin, valid id"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/users/${TARGET_ID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")
  assert_status "200" "$STATUS" "Admin request succeeds"

  # 4. Response matches the target user, no password leak
  info "Response body matches target and excludes password"
  RESPONSE=$(curl -s "${BASE_URL}/api/users/${TARGET_ID}" -H "Authorization: Bearer ${ADMIN_TOKEN}")
  EMAIL_FIELD=$(extract_json_field "$RESPONSE" "email")
  if [ "$EMAIL_FIELD" = "$TARGET_EMAIL" ]; then
    pass "Returned user matches the requested id"
  else
    fail "Returned user did not match (got: ${EMAIL_FIELD:-empty})"
  fi
  if echo "$RESPONSE" | grep -q '"password"'; then
    fail "Password field present in response"
  else
    pass "Password field excluded from response"
  fi

  # 5. Admin, nonexistent id -> 404
  info "GET as admin, nonexistent id"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/users/000000000000000000000000" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")
  assert_status "404" "$STATUS" "Nonexistent user id returns 404"
else
  info "ADMIN_EMAIL/ADMIN_PASSWORD not set (or login failed) — admin-path checks skipped"
fi

print_summary

#!/usr/bin/env bash
#
# test-users-update.sh — PUT /api/users/{id} (admin only)
#
# Usage:
#   ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=... ./test-users-update.sh

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

echo "=========================================="
echo " PUT /api/users/{id}"
echo " Target: ${BASE_URL}"
echo "=========================================="

STAMP=$(date +%s)
TARGET_EMAIL="puttarget.${STAMP}@example.com"
OTHER_EMAIL="putrequester.${STAMP}@example.com"
PASSWORD="Str0ngPassw0rd!"

info "Seeding a target user and a non-admin requester"
TARGET_CREATE=$(curl -s -X POST "${BASE_URL}/api/auth/register" \
  --data-urlencode "name=Put Target" \
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
info "PUT without a token"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/users/${TARGET_ID}" \
  --data-urlencode "name=No Token" \
  --data-urlencode "email=notoken.${STAMP}@example.com")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
  pass "Unauthenticated request rejected (got ${STATUS})"
else
  fail "Unauthenticated request expected 401/403, got ${STATUS}"
fi

# 2. Non-admin -> should be denied
info "PUT as a non-admin user"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/users/${TARGET_ID}" \
  -H "Authorization: Bearer ${OTHER_TOKEN}" \
  --data-urlencode "name=Hijacked Name" \
  --data-urlencode "email=hijacked.${STAMP}@example.com")
assert_denied "$STATUS" "Non-admin user rejected"

ADMIN_TOKEN=$(get_admin_token)
if [ -n "$ADMIN_TOKEN" ]; then
  # 3. Admin, valid update -> 200
  info "PUT as admin, valid data"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/users/${TARGET_ID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    --data-urlencode "name=Admin Updated Name" \
    --data-urlencode "email=updated.${STAMP}@example.com")
  assert_status "200" "$STATUS" "Admin update succeeds"

  # 4. Update actually persisted
  info "Update was actually persisted"
  RESPONSE=$(curl -s "${BASE_URL}/api/users/${TARGET_ID}" -H "Authorization: Bearer ${ADMIN_TOKEN}")
  NAME=$(extract_json_field "$RESPONSE" "name")
  if [ "$NAME" = "Admin Updated Name" ]; then
    pass "User name reflects the update"
  else
    fail "User name did not reflect the update (got: ${NAME:-empty})"
  fi

  # 5. Missing name -> 400
  info "Missing name"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/users/${TARGET_ID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    --data-urlencode "email=stillvalid.${STAMP}@example.com")
  assert_status "400" "$STATUS" "Missing name rejected"

  # 6. Malformed email -> 400
  info "Malformed email"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/users/${TARGET_ID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    --data-urlencode "name=Still Valid Name" \
    --data-urlencode "email=not-an-email")
  assert_status "400" "$STATUS" "Malformed email rejected"

  # 7. Nonexistent id -> 404
  info "PUT on a nonexistent user id"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/users/000000000000000000000000" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    --data-urlencode "name=Ghost User" \
    --data-urlencode "email=ghost.${STAMP}@example.com")
  assert_status "404" "$STATUS" "Nonexistent user id returns 404"

  # 8. Response never leaks password
  info "Response does not leak password"
  RESPONSE=$(curl -s -X PUT "${BASE_URL}/api/users/${TARGET_ID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    --data-urlencode "name=Final Name" \
    --data-urlencode "email=final.${STAMP}@example.com")
  if echo "$RESPONSE" | grep -q '"password"'; then
    fail "Password field present in response"
  else
    pass "Password field excluded from response"
  fi
else
  info "ADMIN_EMAIL/ADMIN_PASSWORD not set (or login failed) — admin-path checks skipped"
fi

print_summary

#!/usr/bin/env bash
#
# test-users-delete.sh — DELETE /api/users/{id} (admin only)
#
# Usage:
#   ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=... ./test-users-delete.sh

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

echo "=========================================="
echo " DELETE /api/users/{id}"
echo " Target: ${BASE_URL}"
echo "=========================================="

STAMP=$(date +%s)
OTHER_EMAIL="delrequester.${STAMP}@example.com"
PASSWORD="Str0ngPassw0rd!"

info "Seeding a non-admin requester"
register_user "Requester" "$OTHER_EMAIL" "$PASSWORD" > /dev/null
OTHER_RESULT=$(login_user "$OTHER_EMAIL" "$PASSWORD")
OTHER_TOKEN="${OTHER_RESULT##*|}"

if [ -z "$OTHER_TOKEN" ]; then
  fail "Could not obtain requester token — aborting"
  print_summary
fi

create_target_user() {
  local email="deltarget.$1.${STAMP}@example.com"
  local response
  response=$(curl -s -X POST "${BASE_URL}/api/auth/register" \
    --data-urlencode "name=Delete Target $1" \
    --data-urlencode "email=${email}" \
    --data-urlencode "password=${PASSWORD}")
  extract_json_field "$response" "id"
}

# --- Target #1: unauthenticated / non-admin / admin delete flow ---
info "Seeding a target user to delete"
TARGET_ID=$(create_target_user "a")
if [ -z "$TARGET_ID" ]; then
  fail "Could not seed a target user — aborting"
  print_summary
fi

# 1. Unauthenticated -> 401/403
info "DELETE without a token"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/users/${TARGET_ID}")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
  pass "Unauthenticated request rejected (got ${STATUS})"
else
  fail "Unauthenticated request expected 401/403, got ${STATUS}"
fi

# 2. Non-admin -> should be denied
info "DELETE as a non-admin user"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/users/${TARGET_ID}" \
  -H "Authorization: Bearer ${OTHER_TOKEN}")
assert_denied "$STATUS" "Non-admin user rejected"

ADMIN_TOKEN=$(get_admin_token)
if [ -n "$ADMIN_TOKEN" ]; then
  # 3. Admin, valid id -> 200
  info "DELETE as admin"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/users/${TARGET_ID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")
  assert_status "200" "$STATUS" "Admin delete succeeds"

  # 4. Deleted user no longer resolves
  info "Deleted user no longer resolves via GET"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/users/${TARGET_ID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")
  assert_status "404" "$STATUS" "User no longer exists after delete"

  # 5. Delete again -> 404
  info "DELETE an already-deleted user"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/users/${TARGET_ID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")
  assert_status "404" "$STATUS" "Deleting a missing user returns 404"

  # 6. Delete a never-existed id -> 404
  info "DELETE on a never-existed user id"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/users/000000000000000000000000" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")
  assert_status "404" "$STATUS" "Never-existed user id returns 404"
else
  info "ADMIN_EMAIL/ADMIN_PASSWORD not set (or login failed) — admin-path checks skipped"
fi

print_summary

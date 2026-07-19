#!/usr/bin/env bash
#
# test-users-get-all.sh — GET /api/users (admin only)
#
# Usage:
#   ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=... ./test-users-get-all.sh
#
# Registration always assigns role=USER except for the very first user ever
# created against an empty database (bootstrapped as ADMIN) — point
# ADMIN_EMAIL/ADMIN_PASSWORD at that account. Without it, admin-path checks
# are skipped and only the access-denial checks run.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

echo "=========================================="
echo " GET /api/users"
echo " Target: ${BASE_URL}"
echo "=========================================="

STAMP=$(date +%s)
USER_EMAIL="regularuser.${STAMP}@example.com"
PASSWORD="Str0ngPassw0rd!"

info "Seeding a regular (non-admin) user"
register_user "Regular User" "$USER_EMAIL" "$PASSWORD" > /dev/null
USER_RESULT=$(login_user "$USER_EMAIL" "$PASSWORD")
USER_TOKEN="${USER_RESULT##*|}"

if [ -z "$USER_TOKEN" ]; then
  fail "Could not obtain a regular user token — aborting"
  print_summary
fi

# 1. Unauthenticated -> 401/403
info "GET without a token"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/users")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
  pass "Unauthenticated request rejected (got ${STATUS})"
else
  fail "Unauthenticated request expected 401/403, got ${STATUS}"
fi

# 2. Regular user (non-admin) -> should be denied
info "GET as a regular (non-admin) user"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/users" \
  -H "Authorization: Bearer ${USER_TOKEN}")
assert_denied "$STATUS" "Non-admin user rejected"

# 3. Admin -> 200
ADMIN_TOKEN=$(get_admin_token)
if [ -n "$ADMIN_TOKEN" ]; then
  info "GET as admin"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/users" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")
  assert_status "200" "$STATUS" "Admin request succeeds"

  info "Response contains a data field"
  RESPONSE=$(curl -s "${BASE_URL}/api/users" -H "Authorization: Bearer ${ADMIN_TOKEN}")
  if echo "$RESPONSE" | grep -q '"data"'; then
    pass "Response wrapped in ResponseDTO with a data field"
  else
    fail "Response missing expected data field"
  fi

  info "No password field leaks in the user list"
  if echo "$RESPONSE" | grep -q '"password"'; then
    fail "Password field present in admin user list response"
  else
    pass "Password field excluded from admin user list response"
  fi
else
  info "ADMIN_EMAIL/ADMIN_PASSWORD not set (or login failed) — admin-path checks skipped"
fi

print_summary

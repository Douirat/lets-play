#!/usr/bin/env bash
#
# test-login.sh — POST /api/auth/login
#
# Usage:
#   ./test-login.sh
#   BASE_URL=http://localhost:8080 ./test-login.sh
#
# Saves the last successful token to .last-login.txt in this directory so
# test-products-*.sh can reuse it without re-registering a user.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

echo "=========================================="
echo " POST /api/auth/login"
echo " Target: ${BASE_URL}"
echo "=========================================="

STAMP=$(date +%s)
EMAIL="login.valid.${STAMP}@example.com"
PASSWORD="Str0ngPassw0rd!"

info "Seeding a user to log in with"
SEED_STATUS=$(register_user "Login Test" "$EMAIL" "$PASSWORD")
if [ "$SEED_STATUS" != "201" ]; then
  fail "Could not seed test user (got ${SEED_STATUS}) — remaining checks skipped"
  print_summary
fi

# 1. Valid login -> 200 + token
info "Valid login"
RESULT=$(login_user "$EMAIL" "$PASSWORD")
STATUS="${RESULT%%|*}"
TOKEN="${RESULT##*|}"
assert_status "200" "$STATUS" "Valid login"
if [ -n "$TOKEN" ]; then
  pass "Token present in login response"
else
  fail "Token missing from login response"
fi

# 2. Wrong password -> 401
info "Wrong password"
RESULT=$(login_user "$EMAIL" "wrong-password")
STATUS="${RESULT%%|*}"
assert_status "401" "$STATUS" "Wrong password rejected"

# 3. Nonexistent email -> 401
info "Nonexistent email"
RESULT=$(login_user "nobody.${STAMP}@example.com" "whatever")
STATUS="${RESULT%%|*}"
assert_status "401" "$STATUS" "Nonexistent email rejected"

# 4. Missing password field -> 400
info "Missing password field"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/auth/login" \
  --data-urlencode "identifier=${EMAIL}")
assert_status "400" "$STATUS" "Missing password field rejected"

# 5. Missing identifier field -> 400
info "Missing identifier field"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/auth/login" \
  --data-urlencode "password=${PASSWORD}")
assert_status "400" "$STATUS" "Missing identifier field rejected"

# 6. Identifier accepts a plain username, not just an email — this is by
# design (UserLoginRequest.identifier only has @NotBlank, no @Email), so a
# non-email-shaped identifier is valid input; it just won't match any user.
info "Username-style identifier (not an email) still reaches auth, fails on no match"
RESULT=$(login_user "not-an-email" "${PASSWORD}")
STATUS="${RESULT%%|*}"
assert_status "401" "$STATUS" "Non-email identifier rejected for no matching user, not for format"

# 7. Empty request body -> 400
info "Empty body"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/auth/login")
assert_status "400" "$STATUS" "Empty body rejected"

# Persist the valid token for downstream scripts
if [ -n "$TOKEN" ]; then
  {
    echo "EMAIL=${EMAIL}"
    echo "PASSWORD=${PASSWORD}"
    echo "TOKEN=${TOKEN}"
    echo "SAVED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  } > "${SCRIPT_DIR}/.last-login.txt"
  info "Token saved to .last-login.txt for reuse by other test scripts"
fi

print_summary

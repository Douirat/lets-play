#!/usr/bin/env bash
#
# test-register.sh — POST /api/auth/register
#
# Usage:
#   ./test-register.sh
#   BASE_URL=http://localhost:8080 ./test-register.sh

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

echo "=========================================="
echo " POST /api/auth/register — Registration"
echo " Target: ${BASE_URL}"
echo "=========================================="

STAMP=$(date +%s)

# 1. Valid registration -> 201
EMAIL="reg.valid.${STAMP}@example.com"
info "Valid registration"
STATUS=$(register_user "Valid User" "$EMAIL" "Str0ngPassw0rd!")
assert_status "201" "$STATUS" "Valid registration"

# 2. Duplicate email -> 409
info "Duplicate email"
STATUS=$(register_user "Valid User" "$EMAIL" "Str0ngPassw0rd!")
assert_status "409" "$STATUS" "Duplicate email rejected"

# 3. Invalid email format -> 400
info "Invalid email format"
STATUS=$(register_user "Bad Email" "not-an-email" "Str0ngPassw0rd!")
assert_status "400" "$STATUS" "Invalid email format rejected"

# 4. Missing name -> 400
info "Missing name field"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/auth/register" \
  --data-urlencode "email=reg.noname.${STAMP}@example.com" \
  --data-urlencode "password=Str0ngPassw0rd!")
assert_status "400" "$STATUS" "Missing name rejected"

# 5. Missing password -> 400
info "Missing password field"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/auth/register" \
  --data-urlencode "name=No Password" \
  --data-urlencode "email=reg.nopass.${STAMP}@example.com")
assert_status "400" "$STATUS" "Missing password rejected"

# 6. Missing email -> 400
info "Missing email field"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/auth/register" \
  --data-urlencode "name=No Email" \
  --data-urlencode "password=Str0ngPassw0rd!")
assert_status "400" "$STATUS" "Missing email rejected"

# 7. Password too short -> 400
info "Password below minimum length"
STATUS=$(register_user "Short Pw" "reg.shortpw.${STAMP}@example.com" "abc")
assert_status "400" "$STATUS" "Short password rejected"

# 8. Empty request body -> 400
info "Empty body"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/auth/register")
assert_status "400" "$STATUS" "Empty body rejected"

# 9. Response never leaks the password field
info "Response body does not leak password"
RESPONSE=$(curl -s -X POST "${BASE_URL}/api/auth/register" \
  --data-urlencode "name=Leak Check" \
  --data-urlencode "email=reg.leak.${STAMP}@example.com" \
  --data-urlencode "password=Str0ngPassw0rd!")
if echo "$RESPONSE" | grep -q '"password"'; then
  fail "Password field present in response"
else
  pass "Password field excluded from response"
fi

# 10. Client-supplied role is ignored — always created as USER
info "Client-supplied role is ignored (server always assigns USER)"
RESPONSE=$(curl -s -X POST "${BASE_URL}/api/auth/register" \
  --data-urlencode "name=Role Spoof" \
  --data-urlencode "email=reg.rolespoof.${STAMP}@example.com" \
  --data-urlencode "password=Str0ngPassw0rd!" \
  --data-urlencode "role=ADMIN")
ROLE=$(extract_json_field "$RESPONSE" "role")
if [ "$ROLE" = "ADMIN" ]; then
  fail "Client was able to self-assign ADMIN role — privilege escalation bug"
else
  pass "Client-supplied role ignored (got: ${ROLE:-none returned})"
fi

print_summary

#!/usr/bin/env bash
#
# test-products-create.sh — POST /api/products
#
# Usage:
#   ./test-products-create.sh
#   BASE_URL=http://localhost:8080 ./test-products-create.sh

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

echo "=========================================="
echo " POST /api/products"
echo " Target: ${BASE_URL}"
echo "=========================================="

STAMP=$(date +%s)
EMAIL="prodcreate.${STAMP}@example.com"
PASSWORD="Str0ngPassw0rd!"

info "Seeding a user + token for these tests"
register_user "Product Creator" "$EMAIL" "$PASSWORD" > /dev/null
RESULT=$(login_user "$EMAIL" "$PASSWORD")
TOKEN="${RESULT##*|}"

if [ -z "$TOKEN" ]; then
  fail "Could not obtain a token — remaining checks skipped"
  print_summary
fi

# 1. No Authorization header -> 401/403
info "Create without a token"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/products" \
  --data-urlencode "name=Unauthed Product" \
  --data-urlencode "description=should be rejected" \
  --data-urlencode "price=9.99")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
  pass "Unauthenticated create rejected (got ${STATUS})"
else
  fail "Unauthenticated create expected 401/403, got ${STATUS}"
fi

# 2. Valid token, valid body -> 201
info "Create with a valid token"
CREATE_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/products" \
  -H "Authorization: Bearer ${TOKEN}" \
  --data-urlencode "name=Valid Product" \
  --data-urlencode "description=a fine product" \
  --data-urlencode "price=19.99")
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/products" \
  -H "Authorization: Bearer ${TOKEN}" \
  --data-urlencode "name=Valid Product 2" \
  --data-urlencode "description=a fine product" \
  --data-urlencode "price=19.99")
assert_status "201" "$STATUS" "Authenticated create succeeds"

# 3. userId in response matches the authenticated user, not something client-supplied
info "Product ownership is set by the server, not the client"
SPOOF_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/products" \
  -H "Authorization: Bearer ${TOKEN}" \
  --data-urlencode "name=Spoofed Owner Product" \
  --data-urlencode "price=9.99" \
  --data-urlencode "userId=000000000000000000000000")
SPOOFED_USER_ID=$(extract_json_field "$SPOOF_RESPONSE" "userId")
if [ "$SPOOFED_USER_ID" = "000000000000000000000000" ]; then
  fail "Client-supplied userId was accepted — ownership spoofing possible"
else
  pass "Client-supplied userId ignored (server assigned the real owner)"
fi

# 4. Missing name -> 400
info "Missing name"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/products" \
  -H "Authorization: Bearer ${TOKEN}" \
  --data-urlencode "description=no name here" \
  --data-urlencode "price=9.99")
assert_status "400" "$STATUS" "Missing name rejected"

# 5. Missing price -> 400
info "Missing price"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/products" \
  -H "Authorization: Bearer ${TOKEN}" \
  --data-urlencode "name=No Price Product")
assert_status "400" "$STATUS" "Missing price rejected"

# 6. Negative price -> 400
info "Negative price"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/products" \
  -H "Authorization: Bearer ${TOKEN}" \
  --data-urlencode "name=Negative Price Product" \
  --data-urlencode "price=-5")
assert_status "400" "$STATUS" "Negative price rejected"

# 7. Zero price -> 400 (constraint is @Positive, zero is not positive)
info "Zero price"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/products" \
  -H "Authorization: Bearer ${TOKEN}" \
  --data-urlencode "name=Zero Price Product" \
  --data-urlencode "price=0")
assert_status "400" "$STATUS" "Zero price rejected"

# 8. Non-numeric price -> 400
info "Non-numeric price"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/products" \
  -H "Authorization: Bearer ${TOKEN}" \
  --data-urlencode "name=Bad Price Product" \
  --data-urlencode "price=not-a-number")
assert_status "400" "$STATUS" "Non-numeric price rejected"

# 9. Garbage token -> 401/403
info "Create with an invalid token"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/products" \
  -H "Authorization: Bearer not-a-real-token" \
  --data-urlencode "name=Bad Token Product" \
  --data-urlencode "price=9.99")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
  pass "Invalid token rejected (got ${STATUS})"
else
  fail "Invalid token expected 401/403, got ${STATUS}"
fi

print_summary

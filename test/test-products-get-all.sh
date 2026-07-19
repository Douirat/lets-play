#!/usr/bin/env bash
#
# test-products-get-all.sh — GET /api/products
#
# Usage:
#   ./test-products-get-all.sh
#   BASE_URL=http://localhost:8080 ./test-products-get-all.sh
#
# Run test-login.sh first if you want the "valid token" case included —
# it's skipped gracefully otherwise.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

echo "=========================================="
echo " GET /api/products"
echo " Target: ${BASE_URL}"
echo "=========================================="

# 1. No Authorization header -> 200 (public endpoint)
info "GET without Authorization header"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/products")
assert_status "200" "$STATUS" "Public access without token"

# 2. Malformed Authorization header (no "Bearer" prefix) -> should still be 200
info "GET with malformed Authorization header"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/products" \
  -H "Authorization: not-bearer-format")
assert_status "200" "$STATUS" "Public access unaffected by malformed header"

# 3. Garbage/expired token -> endpoint is public regardless of token validity, still 200
info "GET with an invalid/garbage token"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/products" \
  -H "Authorization: Bearer not-a-real-token")
assert_status "200" "$STATUS" "Public access with garbage token still succeeds"

# 4. With a valid token -> also 200
if [ -f "${SCRIPT_DIR}/.last-login.txt" ]; then
  TOKEN=$(grep TOKEN= "${SCRIPT_DIR}/.last-login.txt" | cut -d= -f2)
  info "GET with a valid token"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/products" \
    -H "Authorization: Bearer ${TOKEN}")
  assert_status "200" "$STATUS" "Authenticated access also succeeds"
else
  info "Skipping authenticated GET check — run test-login.sh first to generate a token"
fi

# 5. Response is a JSON array/collection under the ResponseDTO wrapper
info "Response contains a data field"
RESPONSE=$(curl -s "${BASE_URL}/api/products")
if echo "$RESPONSE" | grep -q '"data"'; then
  pass "Response wrapped in ResponseDTO with a data field"
else
  fail "Response missing expected data field"
fi

print_summary

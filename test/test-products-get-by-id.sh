#!/usr/bin/env bash
#
# test-products-get-by-id.sh — GET /api/products/{id}
#
# Usage:
#   ./test-products-get-by-id.sh
#   BASE_URL=http://localhost:8080 ./test-products-get-by-id.sh

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

echo "=========================================="
echo " GET /api/products/{id}"
echo " Target: ${BASE_URL}"
echo "=========================================="

STAMP=$(date +%s)
EMAIL="prodget.${STAMP}@example.com"
PASSWORD="Str0ngPassw0rd!"

info "Seeding a user + token, and one product to fetch"
register_user "Product Getter" "$EMAIL" "$PASSWORD" > /dev/null
RESULT=$(login_user "$EMAIL" "$PASSWORD")
TOKEN="${RESULT##*|}"

if [ -z "$TOKEN" ]; then
  fail "Could not obtain a token — remaining checks skipped"
  print_summary
fi

CREATE_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/products" \
  -H "Authorization: Bearer ${TOKEN}" \
  --data-urlencode "name=Fetchable Product" \
  --data-urlencode "description=used for GET by id checks" \
  --data-urlencode "price=12.50")
PRODUCT_ID=$(extract_json_field "$CREATE_RESPONSE" "id")

if [ -z "$PRODUCT_ID" ]; then
  fail "Could not create a product to fetch — aborting remaining checks"
  print_summary
fi
pass "Product created (id=${PRODUCT_ID})"

# 1. Valid id, no auth -> 200 (this endpoint should be public, same as the collection)
info "GET by valid id without a token"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/products/${PRODUCT_ID}")
assert_status "200" "$STATUS" "Fetch by valid id succeeds without auth"

# 2. Valid id, with auth -> 200
info "GET by valid id with a token"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/products/${PRODUCT_ID}" \
  -H "Authorization: Bearer ${TOKEN}")
assert_status "200" "$STATUS" "Fetch by valid id succeeds with auth"

# 3. Response actually contains the expected fields
info "Response body contains the product's own fields"
RESPONSE=$(curl -s "${BASE_URL}/api/products/${PRODUCT_ID}")
NAME=$(extract_json_field "$RESPONSE" "name")
if [ "$NAME" = "Fetchable Product" ]; then
  pass "Fetched product name matches what was created"
else
  fail "Fetched product name did not match (got: ${NAME:-empty})"
fi

# 4. Nonexistent id -> 404
info "GET by nonexistent id"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/products/000000000000000000000000")
assert_status "404" "$STATUS" "Nonexistent product id returns 404"

# 5. Malformed id (not a valid ObjectId shape) -> 400 or 404 depending on how
# Mongo's id conversion error is handled; both are defensible, a raw 500 is not
info "GET by malformed id"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/products/not-a-valid-id")
if [ "$STATUS" = "400" ] || [ "$STATUS" = "404" ]; then
  pass "Malformed id handled cleanly (got ${STATUS})"
else
  fail "Malformed id expected 400 or 404, got ${STATUS} — check for a raw 500 leaking a stack trace"
fi

print_summary

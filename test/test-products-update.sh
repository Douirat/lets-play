#!/usr/bin/env bash
#
# test-products-update.sh — PUT /api/products/{id}
#
# Usage:
#   ./test-products-update.sh
#   BASE_URL=http://localhost:8080 ./test-products-update.sh
#
# Admin-override check is SKIPPED unless ADMIN_EMAIL and ADMIN_PASSWORD are
# set. Registration always assigns role=USER except for the very first user
# ever created against an empty database (bootstrapped as ADMIN).
#   ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=... ./test-products-update.sh

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

echo "=========================================="
echo " PUT /api/products/{id}"
echo " Target: ${BASE_URL}"
echo "=========================================="

STAMP=$(date +%s)
OWNER_EMAIL="ownerput.${STAMP}@example.com"
OTHER_EMAIL="otherput.${STAMP}@example.com"
PASSWORD="Str0ngPassw0rd!"

info "Seeding owner user"
register_user "Owner" "$OWNER_EMAIL" "$PASSWORD" > /dev/null
OWNER_RESULT=$(login_user "$OWNER_EMAIL" "$PASSWORD")
OWNER_TOKEN="${OWNER_RESULT##*|}"

info "Seeding other (non-owner) user"
register_user "Other" "$OTHER_EMAIL" "$PASSWORD" > /dev/null
OTHER_RESULT=$(login_user "$OTHER_EMAIL" "$PASSWORD")
OTHER_TOKEN="${OTHER_RESULT##*|}"

if [ -z "$OWNER_TOKEN" ] || [ -z "$OTHER_TOKEN" ]; then
  fail "Could not obtain owner/other tokens — aborting"
  print_summary
fi

ADMIN_TOKEN=$(get_admin_token)
if [ -z "$ADMIN_TOKEN" ]; then
  info "ADMIN_EMAIL/ADMIN_PASSWORD not set (or login failed) — admin-override check will be skipped"
fi

info "Owner creates a product to update"
CREATE_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/products" \
  -H "Authorization: Bearer ${OWNER_TOKEN}" \
  --data-urlencode "name=Update Target Product" \
  --data-urlencode "description=used for PUT checks" \
  --data-urlencode "price=25.00")
PRODUCT_ID=$(extract_json_field "$CREATE_RESPONSE" "id")

if [ -z "$PRODUCT_ID" ]; then
  fail "Could not create a product to test against — aborting remaining checks"
  print_summary
fi
pass "Product created (id=${PRODUCT_ID})"

# 1. Unauthenticated PUT -> 401/403
info "Unauthenticated PUT"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/products/${PRODUCT_ID}" \
  --data-urlencode "name=No Token" \
  --data-urlencode "price=1.00")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
  pass "Unauthenticated PUT rejected (got ${STATUS})"
else
  fail "Unauthenticated PUT expected 401/403, got ${STATUS}"
fi

# 2. Non-owner PUT -> 403
info "Non-owner PUT"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/products/${PRODUCT_ID}" \
  -H "Authorization: Bearer ${OTHER_TOKEN}" \
  --data-urlencode "name=Hijacked Name" \
  --data-urlencode "price=1.00")
assert_status "403" "$STATUS" "Non-owner PUT rejected"

# 3. Owner PUT -> 200
info "Owner PUT"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/products/${PRODUCT_ID}" \
  -H "Authorization: Bearer ${OWNER_TOKEN}" \
  --data-urlencode "name=Owner Updated Name" \
  --data-urlencode "description=updated by owner" \
  --data-urlencode "price=30.00")
assert_status "200" "$STATUS" "Owner PUT succeeds"

# 4. Update actually persisted
info "Update was actually persisted"
RESPONSE=$(curl -s "${BASE_URL}/api/products/${PRODUCT_ID}")
NAME=$(extract_json_field "$RESPONSE" "name")
if [ "$NAME" = "Owner Updated Name" ]; then
  pass "Product name reflects the update"
else
  fail "Product name did not reflect the update (got: ${NAME:-empty})"
fi

# 5. Admin PUT on someone else's product
if [ -n "$ADMIN_TOKEN" ]; then
  info "Admin PUT (non-owner but admin)"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/products/${PRODUCT_ID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    --data-urlencode "name=Admin Updated Name" \
    --data-urlencode "price=35.00")
  assert_status "200" "$STATUS" "Admin PUT succeeds despite not owning the product"
else
  info "Skipping admin PUT check (no ADMIN_EMAIL/ADMIN_PASSWORD)"
fi

# 6. Missing name -> 400
info "Missing name"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/products/${PRODUCT_ID}" \
  -H "Authorization: Bearer ${OWNER_TOKEN}" \
  --data-urlencode "price=10.00")
assert_status "400" "$STATUS" "Missing name rejected"

# 7. Negative price -> 400
info "Negative price"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/products/${PRODUCT_ID}" \
  -H "Authorization: Bearer ${OWNER_TOKEN}" \
  --data-urlencode "name=Bad Price" \
  --data-urlencode "price=-5")
assert_status "400" "$STATUS" "Negative price rejected"

# 8. PUT on a nonexistent product id -> 404
info "PUT on a nonexistent product id"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/products/000000000000000000000000" \
  -H "Authorization: Bearer ${OWNER_TOKEN}" \
  --data-urlencode "name=Ghost Product" \
  --data-urlencode "price=1.00")
assert_status "404" "$STATUS" "Nonexistent product PUT returns 404"

print_summary

#!/usr/bin/env bash
#
# test-products-update-delete.sh — PUT/DELETE /api/products/{id}
# Full owner / non-owner / admin / unauthenticated / missing-resource matrix.
#
# Usage:
#   ./test-products-update-delete.sh
#   BASE_URL=http://localhost:8080 ./test-products-update-delete.sh
#
# Admin-override checks (steps 5 and 9) are SKIPPED unless ADMIN_EMAIL and
# ADMIN_PASSWORD are set. Registration always assigns role=USER server-side
# (see UserService.createUser), so there is no API path to create an admin —
# point these at a pre-seeded admin account, e.g.:
#   ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=... ./test-products-update-delete.sh

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

echo "=========================================="
echo " PUT/DELETE /api/products/{id} — ownership matrix"
echo " Target: ${BASE_URL}"
echo "=========================================="

STAMP=$(date +%s)
OWNER_EMAIL="owner.${STAMP}@example.com"
OTHER_EMAIL="other.${STAMP}@example.com"
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

ADMIN_EMAIL="${ADMIN_EMAIL:-}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
ADMIN_TOKEN=""

if [ -n "$ADMIN_EMAIL" ] && [ -n "$ADMIN_PASSWORD" ]; then
  ADMIN_RESULT=$(login_user "$ADMIN_EMAIL" "$ADMIN_PASSWORD")
  ADMIN_STATUS="${ADMIN_RESULT%%|*}"
  ADMIN_TOKEN="${ADMIN_RESULT##*|}"
  if [ "$ADMIN_STATUS" != "200" ] || [ -z "$ADMIN_TOKEN" ]; then
    info "ADMIN_EMAIL/ADMIN_PASSWORD given but login failed (status ${ADMIN_STATUS}) — admin checks skipped"
    ADMIN_TOKEN=""
  fi
else
  info "ADMIN_EMAIL/ADMIN_PASSWORD not set — admin-override checks will be skipped"
fi

# --- Create a product as the owner, to run the matrix against ---
info "Owner creates a product"
CREATE_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/products" \
  -H "Authorization: Bearer ${OWNER_TOKEN}" \
  --data-urlencode "name=Ownership Test Product" \
  --data-urlencode "description=used for owner/admin checks" \
  --data-urlencode "price=25.00")
PRODUCT_ID=$(extract_json_field "$CREATE_RESPONSE" "id")

if [ -z "$PRODUCT_ID" ]; then
  fail "Could not create a product to test against — aborting remaining checks"
  print_summary
fi
pass "Product created (id=${PRODUCT_ID})"

# 1. Non-owner PUT -> 403
info "Non-owner PUT"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/products/${PRODUCT_ID}" \
  -H "Authorization: Bearer ${OTHER_TOKEN}" \
  --data-urlencode "name=Hijacked Name" \
  --data-urlencode "price=1.00")
assert_status "403" "$STATUS" "Non-owner PUT rejected"

# 2. Non-owner DELETE -> 403
info "Non-owner DELETE"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/products/${PRODUCT_ID}" \
  -H "Authorization: Bearer ${OTHER_TOKEN}")
assert_status "403" "$STATUS" "Non-owner DELETE rejected"

# 3. Unauthenticated PUT -> 401/403
info "Unauthenticated PUT"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/products/${PRODUCT_ID}" \
  --data-urlencode "name=No Token" \
  --data-urlencode "price=1.00")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
  pass "Unauthenticated PUT rejected (got ${STATUS})"
else
  fail "Unauthenticated PUT expected 401/403, got ${STATUS}"
fi

# 4. Unauthenticated DELETE -> 401/403
info "Unauthenticated DELETE"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/products/${PRODUCT_ID}")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
  pass "Unauthenticated DELETE rejected (got ${STATUS})"
else
  fail "Unauthenticated DELETE expected 401/403, got ${STATUS}"
fi

# 5. Owner PUT -> 200
info "Owner PUT"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/products/${PRODUCT_ID}" \
  -H "Authorization: Bearer ${OWNER_TOKEN}" \
  --data-urlencode "name=Owner Updated Name" \
  --data-urlencode "description=updated by owner" \
  --data-urlencode "price=30.00")
assert_status "200" "$STATUS" "Owner PUT succeeds"

# 6. Admin PUT on someone else's product (skipped without admin creds)
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

# 7. PUT on a nonexistent product id -> 404 preferred, 403 acceptable
# (depends on whether your @PreAuthorize ownership check or a prior existence
#  check runs first — see the AUDIT note in LETS-PLAY-TODO.md, item 6)
info "PUT on a nonexistent product id"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${BASE_URL}/api/products/000000000000000000000000" \
  -H "Authorization: Bearer ${OWNER_TOKEN}" \
  --data-urlencode "name=Ghost Product" \
  --data-urlencode "price=1.00")
if [ "$STATUS" = "404" ] || [ "$STATUS" = "403" ]; then
  pass "Nonexistent product PUT returned ${STATUS} (404 preferred, 403 acceptable)"
else
  fail "Nonexistent product PUT expected 404 or 403, got ${STATUS}"
fi

# 8. Owner DELETE -> 200
info "Owner DELETE"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/products/${PRODUCT_ID}" \
  -H "Authorization: Bearer ${OWNER_TOKEN}")
assert_status "200" "$STATUS" "Owner DELETE succeeds"

# 9. DELETE an already-deleted product -> 404
info "DELETE an already-deleted product"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/products/${PRODUCT_ID}" \
  -H "Authorization: Bearer ${OWNER_TOKEN}")
assert_status "404" "$STATUS" "Deleting a missing product returns 404"

# 10. Admin DELETE on someone else's product (skipped without admin creds)
if [ -n "$ADMIN_TOKEN" ]; then
  info "Admin DELETE (non-owner but admin)"
  SECOND_CREATE=$(curl -s -X POST "${BASE_URL}/api/products" \
    -H "Authorization: Bearer ${OWNER_TOKEN}" \
    --data-urlencode "name=Second Ownership Product" \
    --data-urlencode "price=15.00")
  SECOND_PRODUCT_ID=$(extract_json_field "$SECOND_CREATE" "id")
  if [ -n "$SECOND_PRODUCT_ID" ]; then
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/products/${SECOND_PRODUCT_ID}" \
      -H "Authorization: Bearer ${ADMIN_TOKEN}")
    assert_status "200" "$STATUS" "Admin DELETE succeeds despite not owning the product"
  else
    fail "Could not create a second product to test admin DELETE"
  fi
else
  info "Skipping admin DELETE check (no ADMIN_EMAIL/ADMIN_PASSWORD)"
fi

print_summary

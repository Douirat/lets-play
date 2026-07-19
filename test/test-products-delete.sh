#!/usr/bin/env bash
#
# test-products-delete.sh — DELETE /api/products/{id}
#
# Usage:
#   ./test-products-delete.sh
#   BASE_URL=http://localhost:8080 ./test-products-delete.sh
#
# Admin-override check is SKIPPED unless ADMIN_EMAIL and ADMIN_PASSWORD are
# set. Registration always assigns role=USER except for the very first user
# ever created against an empty database (bootstrapped as ADMIN).
#   ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=... ./test-products-delete.sh

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

echo "=========================================="
echo " DELETE /api/products/{id}"
echo " Target: ${BASE_URL}"
echo "=========================================="

STAMP=$(date +%s)
OWNER_EMAIL="ownerdel.${STAMP}@example.com"
OTHER_EMAIL="otherdel.${STAMP}@example.com"
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

create_product() {
  local token="$1" name="$2"
  local response
  response=$(curl -s -X POST "${BASE_URL}/api/products" \
    -H "Authorization: Bearer ${token}" \
    --data-urlencode "name=${name}" \
    --data-urlencode "price=15.00")
  extract_json_field "$response" "id"
}

# --- Product #1: non-owner / unauthenticated / owner delete flow ---
info "Owner creates a product to delete"
PRODUCT_ID=$(create_product "$OWNER_TOKEN" "Delete Target Product")
if [ -z "$PRODUCT_ID" ]; then
  fail "Could not create a product to test against — aborting remaining checks"
  print_summary
fi
pass "Product created (id=${PRODUCT_ID})"

# 1. Unauthenticated DELETE -> 401/403
info "Unauthenticated DELETE"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/products/${PRODUCT_ID}")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
  pass "Unauthenticated DELETE rejected (got ${STATUS})"
else
  fail "Unauthenticated DELETE expected 401/403, got ${STATUS}"
fi

# 2. Non-owner DELETE -> 403
info "Non-owner DELETE"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/products/${PRODUCT_ID}" \
  -H "Authorization: Bearer ${OTHER_TOKEN}")
assert_status "403" "$STATUS" "Non-owner DELETE rejected"

# 3. Owner DELETE -> 200
info "Owner DELETE"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/products/${PRODUCT_ID}" \
  -H "Authorization: Bearer ${OWNER_TOKEN}")
assert_status "200" "$STATUS" "Owner DELETE succeeds"

# 4. Deleted product is actually gone
info "Deleted product no longer resolves via GET"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/products/${PRODUCT_ID}")
assert_status "404" "$STATUS" "Product no longer exists after delete"

# 5. DELETE again (already deleted) -> 404
info "DELETE an already-deleted product"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/products/${PRODUCT_ID}" \
  -H "Authorization: Bearer ${OWNER_TOKEN}")
assert_status "404" "$STATUS" "Deleting a missing product returns 404"

# 6. DELETE on a never-existed id -> 404
info "DELETE on a never-existed product id"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/products/000000000000000000000000" \
  -H "Authorization: Bearer ${OWNER_TOKEN}")
assert_status "404" "$STATUS" "Never-existed product id returns 404"

# --- Product #2: admin-override flow (separate product, since #1 is gone) ---
if [ -n "$ADMIN_TOKEN" ]; then
  info "Owner creates a second product for the admin-override check"
  SECOND_PRODUCT_ID=$(create_product "$OWNER_TOKEN" "Second Delete Target")
  if [ -n "$SECOND_PRODUCT_ID" ]; then
    info "Admin DELETE (non-owner but admin)"
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

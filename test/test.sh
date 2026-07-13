#!/usr/bin/env bash
#
# test-auth.sh — smoke test for POST /auth/register and POST /auth/login
#
# Usage:
#   ./test-auth.sh
#   BASE_URL=http://localhost:8080 ./test-auth.sh
#   TOKEN_FILE=./my-token.txt ./test-auth.sh
#
# Endpoints tested (matches @ModelAttribute controller — form-encoded body,
# NOT application/json):
#   POST /api/users          register
#   POST /api/users/login    login
#
# Response is assumed wrapped as ResponseDTO<T>, e.g. {"status":...,
# "message":...,"data":{"token":"..."}}. Token extraction searches
# recursively so it works whether "token" sits at top level or nested under
# "data" — adjust EMAIL_FIELD/PASSWORD_FIELD/NAME_FIELD below if your
# User / UserLoginRequest fields use different names.
#
# On successful login, saves EMAIL/PASSWORD/TOKEN/SAVED_AT to TOKEN_FILE
# (default: ./auth-token.txt) so the token can be reused in later requests,
# e.g.:
#   TOKEN=$(grep TOKEN= auth-token.txt | cut -d= -f2)
#   curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/products
#
# Requires: curl. Uses jq for pretty output/parsing if available, falls back
# to grep/sed otherwise so it still runs on a bare system.

set -uo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
TOKEN_FILE="${TOKEN_FILE:-./auth-token.txt}"
EMAIL="test.user.$(date +%s)@example.com"   # unique each run so re-running never 409s
PASSWORD="Str0ngPassw0rd!"
NAME="Test User"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

HAS_JQ=false
if command -v jq >/dev/null 2>&1; then
  HAS_JQ=true
fi

pass() { echo -e "${GREEN}✔ $1${NC}"; }
fail() { echo -e "${RED}✘ $1${NC}"; }
info() { echo -e "${YELLOW}→ $1${NC}"; }

extract_json_field() {
  # $1 = json string, $2 = field name
  # Searches recursively so it finds the field whether it's top-level or
  # nested inside a ResponseDTO wrapper (e.g. data.token).
  local json="$1" field="$2"
  if $HAS_JQ; then
    echo "$json" | jq -r "[.. | objects | select(has(\"${field}\")) | .${field}] | first // empty" 2>/dev/null
  else
    echo "$json" | grep -o "\"${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
      | head -n1 \
      | sed -E "s/\"${field}\"[[:space:]]*:[[:space:]]*\"([^\"]*)\"/\1/"
  fi
}

FAILURES=0

echo "=========================================="
echo " Let's Play — Auth Endpoint Smoke Test"
echo " Target: ${BASE_URL}"
echo " Test email: ${EMAIL}"
echo "=========================================="
echo

# ---------------------------------------------------------------------------
# 1. Register
# ---------------------------------------------------------------------------
info "POST /api/users"

REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${BASE_URL}/api/users" \
  --data-urlencode "name=${NAME}" \
  --data-urlencode "email=${EMAIL}" \
  --data-urlencode "password=${PASSWORD}")

REGISTER_STATUS=$(echo "$REGISTER_RESPONSE" | tail -n1)
REGISTER_JSON=$(echo "$REGISTER_RESPONSE" | sed '$d')

echo "  Status: ${REGISTER_STATUS}"
echo "  Body:   ${REGISTER_JSON}"

if [ "$REGISTER_STATUS" = "201" ]; then
  pass "Register returned 201 Created"
else
  fail "Register expected 201, got ${REGISTER_STATUS}"
  FAILURES=$((FAILURES + 1))
fi

if echo "$REGISTER_JSON" | grep -q '"password"'; then
  fail "Response leaks the password field — must be excluded"
  FAILURES=$((FAILURES + 1))
else
  pass "Password field correctly excluded from response"
fi
echo

# ---------------------------------------------------------------------------
# 2. Register duplicate email -> expect 409
# ---------------------------------------------------------------------------
info "POST /api/users (duplicate email, expect 409)"

DUP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/users" \
  --data-urlencode "name=${NAME}" \
  --data-urlencode "email=${EMAIL}" \
  --data-urlencode "password=${PASSWORD}")

echo "  Status: ${DUP_STATUS}"
if [ "$DUP_STATUS" = "409" ]; then
  pass "Duplicate register correctly returned 409 Conflict"
else
  fail "Duplicate register expected 409, got ${DUP_STATUS}"
  FAILURES=$((FAILURES + 1))
fi
echo

# ---------------------------------------------------------------------------
# 3. Login with correct credentials
# ---------------------------------------------------------------------------
info "POST /api/users/login (correct credentials)"

LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${BASE_URL}/api/users/login" \
  --data-urlencode "email=${EMAIL}" \
  --data-urlencode "password=${PASSWORD}")

LOGIN_STATUS=$(echo "$LOGIN_RESPONSE" | tail -n1)
LOGIN_JSON=$(echo "$LOGIN_RESPONSE" | sed '$d')

echo "  Status: ${LOGIN_STATUS}"
echo "  Body:   ${LOGIN_JSON}"

if [ "$LOGIN_STATUS" = "200" ]; then
  pass "Login returned 200 OK"
else
  fail "Login expected 200, got ${LOGIN_STATUS}"
  FAILURES=$((FAILURES + 1))
fi

TOKEN=$(extract_json_field "$LOGIN_JSON" "token")

if [ -n "$TOKEN" ]; then
  pass "JWT token received (${TOKEN:0:20}...)"

  {
    echo "EMAIL=${EMAIL}"
    echo "PASSWORD=${PASSWORD}"
    echo "TOKEN=${TOKEN}"
    echo "SAVED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  } > "$TOKEN_FILE"

  pass "Token saved to ${TOKEN_FILE}"
  info "Reuse it with: TOKEN=\$(grep TOKEN= ${TOKEN_FILE} | cut -d= -f2)"
else
  fail "No token found in login response"
  FAILURES=$((FAILURES + 1))
fi
echo

# ---------------------------------------------------------------------------
# 4. Login with wrong password -> expect 401
# ---------------------------------------------------------------------------
info "POST /api/users/login (wrong password, expect 401)"

BAD_LOGIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/users/login" \
  --data-urlencode "email=${EMAIL}" \
  --data-urlencode "password=wrong-password")

echo "  Status: ${BAD_LOGIN_STATUS}"
if [ "$BAD_LOGIN_STATUS" = "401" ]; then
  pass "Wrong password correctly returned 401 Unauthorized"
else
  fail "Wrong password expected 401, got ${BAD_LOGIN_STATUS}"
  FAILURES=$((FAILURES + 1))
fi
echo

# ---------------------------------------------------------------------------
# 5. Login with nonexistent email -> expect 401
# ---------------------------------------------------------------------------
info "POST /api/users/login (nonexistent email, expect 401)"

NOEMAIL_LOGIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/users/login" \
  --data-urlencode "email=nobody-$(date +%s)@example.com" \
  --data-urlencode "password=whatever")

echo "  Status: ${NOEMAIL_LOGIN_STATUS}"
if [ "$NOEMAIL_LOGIN_STATUS" = "401" ]; then
  pass "Nonexistent email correctly returned 401 Unauthorized"
else
  fail "Nonexistent email expected 401, got ${NOEMAIL_LOGIN_STATUS}"
  FAILURES=$((FAILURES + 1))
fi
echo

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "=========================================="
if [ "$FAILURES" -eq 0 ]; then
  pass "All auth checks passed"
  echo "=========================================="
  exit 0
else
  fail "${FAILURES} check(s) failed"
  echo "=========================================="
  exit 1
fi
#!/usr/bin/env bash
#
# common.sh — shared helpers for the Let's Play API test suite.
# This file is meant to be SOURCED, not executed directly.

BASE_URL="${BASE_URL:-http://localhost:8080}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

HAS_JQ=false
command -v jq >/dev/null 2>&1 && HAS_JQ=true

FAILURES=0

pass() { echo -e "${GREEN}✔ $1${NC}"; }
fail() { echo -e "${RED}✘ $1${NC}"; FAILURES=$((FAILURES + 1)); }
info() { echo -e "${YELLOW}→ $1${NC}"; }

# Extract a field anywhere in a (possibly nested) JSON body — works whether
# the field sits at top level or nested under ResponseDTO's "data" key.
extract_json_field() {
  local json="$1" field="$2"
  if $HAS_JQ; then
    echo "$json" | jq -r "[.. | objects | select(has(\"${field}\")) | .${field}] | first // empty" 2>/dev/null
  else
    echo "$json" | grep -o "\"${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
      | head -n1 \
      | sed -E "s/\"${field}\"[[:space:]]*:[[:space:]]*\"([^\"]*)\"/\1/"
  fi
}

# assert_status <expected> <actual> <description>
assert_status() {
  local expected="$1" actual="$2" desc="$3"
  if [ "$actual" = "$expected" ]; then
    pass "${desc} (expected ${expected}, got ${actual})"
  else
    fail "${desc} (expected ${expected}, got ${actual})"
  fi
}

# assert_denied <actual> <description>
# For access-control checks where the correct status is 403. Treats a 2xx
# response as a hard failure (a real security hole — unauthorized access was
# granted), but treats a 500 as a soft warning rather than a suite-breaking
# failure: access WAS denied, just with the wrong status code, which usually
# means an exception is being thrown during authorization evaluation instead
# of cleanly resolving to AccessDeniedException. Worth fixing, not a blocker.
assert_denied() {
  local actual="$1" desc="$2"
  case "$actual" in
    403)
      pass "${desc} (got 403)"
      ;;
    2*)
      fail "${desc} — SECURITY ISSUE: got ${actual}, access was NOT denied"
      ;;
    5*)
      echo -e "${YELLOW}⚠ ${desc} — got ${actual} instead of 403. Access was denied, but the${NC}"
      echo -e "${YELLOW}  wrong status code came back. Likely an exception during @PreAuthorize${NC}"
      echo -e "${YELLOW}  evaluation (check CustomUserDetails.getAuthorities() for a null Role).${NC}"
      echo -e "${YELLOW}  Not counted as a suite failure, but should be fixed.${NC}"
      ;;
    *)
      fail "${desc} (expected 403, got ${actual})"
      ;;
  esac
}

# register_user <name> <email> <password> -> echoes the HTTP status code
register_user() {
  curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/auth/register" \
    --data-urlencode "name=$1" \
    --data-urlencode "email=$2" \
    --data-urlencode "password=$3"
}

# login_user <identifier (name or email)> <password> -> echoes "STATUS|TOKEN"
login_user() {
  local response status body token
  response=$(curl -s -w "\n%{http_code}" -X POST "${BASE_URL}/api/auth/login" \
    --data-urlencode "identifier=$1" \
    --data-urlencode "password=$2")
  status=$(echo "$response" | tail -n1)
  body=$(echo "$response" | sed '$d')
  token=$(extract_json_field "$body" "token")
  echo "${status}|${token}"
}

print_summary() {
  echo "=========================================="
  if [ "$FAILURES" -eq 0 ]; then
    echo -e "${GREEN}✔ All checks passed${NC}"
    echo "=========================================="
    exit 0
  else
    echo -e "${RED}✘ ${FAILURES} check(s) failed${NC}"
    echo "=========================================="
    exit 1
  fi
}

# get_admin_token -> echoes a token, or empty string if ADMIN_EMAIL/ADMIN_PASSWORD
# are unset or login fails. Registration always assigns role=USER server-side
# except for the very first user ever created against an empty database
# (bootstrapped as ADMIN) — point these env vars at that account.
get_admin_token() {
  local email="${ADMIN_EMAIL:-}" password="${ADMIN_PASSWORD:-}"
  if [ -z "$email" ] || [ -z "$password" ]; then
    echo ""
    return
  fi
  local result status token
  result=$(login_user "$email" "$password")
  status="${result%%|*}"
  token="${result##*|}"
  if [ "$status" != "200" ] || [ -z "$token" ]; then
    echo ""
    return
  fi
  echo "$token"
}

#!/usr/bin/env bash
#
# run-all.sh — runs the full Let's Play API test suite in order.
#
# Usage:
#   ./run-all.sh
#   BASE_URL=http://localhost:8080 ./run-all.sh
#   ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=... ./run-all.sh   # include admin-override checks

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCRIPTS=(
  "test-register.sh"
  "test-login.sh"
  "test-products-get-all.sh"
  "test-products-get-by-id.sh"
  "test-products-create.sh"
  "test-products-update.sh"
  "test-products-delete.sh"
  "test-users-get-all.sh"
  "test-users-get-by-id.sh"
  "test-users-update.sh"
  "test-users-delete.sh"
)

TOTAL_SUITE_FAILURES=0

for script in "${SCRIPTS[@]}"; do
  echo
  echo "############################################"
  echo "# Running ${script}"
  echo "############################################"
  bash "${SCRIPT_DIR}/${script}"
  if [ $? -ne 0 ]; then
    TOTAL_SUITE_FAILURES=$((TOTAL_SUITE_FAILURES + 1))
  fi
done

echo
echo "############################################"
if [ "$TOTAL_SUITE_FAILURES" -eq 0 ]; then
  echo "All test suites passed"
  echo "############################################"
  exit 0
else
  echo "${TOTAL_SUITE_FAILURES} test suite(s) had failures — scroll up for details"
  echo "############################################"
  exit 1
fi

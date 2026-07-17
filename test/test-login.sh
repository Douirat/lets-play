#!/bin/bash

BASE_URL="http://localhost:8080"

curl -s \
  -X POST "$BASE_URL/api/auth/login" \
  -F "identifier=mike@example.com" \
  -F "password=Password123" \
| grep -o '"token":"[^"]*"' \
| cut -d'"' -f4 > token.txt

echo "Token saved to token.txt"
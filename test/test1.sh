#!/bin/bash

BASE_URL="http://localhost:8080"

curl -v \
  -X POST "$BASE_URL/api/auth/register" \
  -F "name=John Doe" \
  -F "email=john@example.com" \
  -F "password=Password123"
# #!/bin/bash

BASE_URL="http://localhost:8080"

curl -v \
  -X POST "$BASE_URL/api/auth/register" \
  -F "name=Mike Doe" \
  -F "email=mike@example.com" \
  -F "password=Password123"

    !/bin/bash
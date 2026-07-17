#!/bin/bash

BASE_URL="http://localhost:8080"

TOKEN=$(cat token.txt)

curl -v \
  -X POST "$BASE_URL/api/products" \
  -H "Authorization: Bearer $TOKEN" \
  -F "name=Gaming Mouse" \
  -F "description=RGB Gaming Mouse" \
  -F "price=49.99" \
  -F "userId=REPLACE_WITH_USER_ID"
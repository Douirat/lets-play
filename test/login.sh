curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "identifier=john@example.com" \
  -d "password=Password123"
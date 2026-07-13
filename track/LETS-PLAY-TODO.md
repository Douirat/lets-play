# Let's Play — Build TODO

Cross-referenced against `README.md` (requirements) and `AUDIT.md` (what the evaluator will actually check). Order follows a logical build sequence: setup → data layer → security → API → error handling → hardening → bonus.

---

## 0. Project Setup

- [ ] Generate project via [Spring Initializer](https://start.spring.io/) with dependencies: `Spring Web`, `Spring Data MongoDB`, `Spring Security`, `Validation`, `JWT` (jjwt or similar)
- [ ] Configure MongoDB connection in `application.properties` / `application.yml`
- [ ] Verify app boots and connects to MongoDB before writing any endpoint

---

## 1. Database Design (`User` & `Product`)

- [ ] Create `User` entity: `id`, `name`, `email`, `password`, `role`
  - [ ] Annotate class with `@Document`
  - [ ] Annotate id field with `@Id`
  - [ ] Use `@Field` where the Mongo field name differs from the Java field name
- [ ] Create `Product` entity: `id`, `name`, `description`, `price`, `userId`
  - [ ] Same `@Document` / `@Id` / `@Field` treatment
- [ ] Model the one-to-many relationship: one `User` → many `Product` (via `userId` reference, not embedding)
- [ ] Add validation annotations on entity fields:
  - [ ] `@NotNull` / `@NotBlank` on required fields (name, email, password, role, price)
  - [ ] `@Email` on the email field
  - [ ] `@Size` on name/description/password length constraints
- [ ] Create repositories: `UserRepository`, `ProductRepository` extending `MongoRepository`

---

## 2. Authentication & Authorization (JWT + Spring Security)

- [ ] Implement password hashing with `BCryptPasswordEncoder` — hash before every save, never store plaintext
- [ ] Build JWT utility: generate token, validate token, extract claims (userId, role, expiry)
- [ ] Implement `POST /auth/register` — create user, hash password, assign default role
- [ ] Implement `POST /auth/login` — verify credentials, issue JWT on success
- [ ] Create a `JwtAuthenticationFilter` (extends `OncePerRequestFilter`) to intercept requests and populate the security context
- [ ] Configure `SecurityFilterChain`:
  - [ ] Annotate config class with `@EnableWebSecurity`
  - [ ] Annotate with `@EnableMethodSecurity` to allow method-level checks
  - [ ] Register the JWT filter before `UsernamePasswordAuthenticationFilter`
  - [ ] Disable CSRF (stateless JWT API), set session policy to `STATELESS`
- [ ] Apply role-based access:
  - [ ] `@PermitAll` on `GET /products` and auth endpoints (register/login)
  - [ ] `@PreAuthorize("hasRole('ADMIN')")` on user-management endpoints
  - [ ] `@PreAuthorize` (owner-or-admin check) on `PUT /products/{id}` and `DELETE /products/{id}`
  - [ ] Consider `@PostAuthorize` where the decision depends on the loaded resource (e.g., verifying `product.userId == principal.id` after fetch)
- [ ] Inject dependencies (`UserRepository`, `PasswordEncoder`, `JwtUtil`, etc.) using `@Autowired` (constructor injection preferred)

---

## 3. Product API

- [ ] `@RestController` + `@RequestMapping("/products")` on `ProductController`
- [ ] `GET /products` — `@GetMapping`, public, no auth required
- [ ] `POST /products` — `@PostMapping`, requires authentication, product owner = current user
- [ ] `GET /products/{id}` — fetch single product
- [ ] `PUT /products/{id}` — `@PutMapping`, restricted to owner or admin
- [ ] `DELETE /products/{id}` — `@DeleteMapping`, restricted to owner or admin
- [ ] Return `404` when a product id doesn't exist
- [ ] Return `403` when a non-owner/non-admin attempts update/delete

---

## 4. User API

- [ ] `@RestController` + `@RequestMapping("/users")` on `UserController`
- [ ] `GET /users` — admin only
- [ ] `GET /users/{id}` — admin only (or self, if you choose to allow it — document the choice)
- [ ] `PUT /users/{id}` — admin only (or self for own profile)
- [ ] `DELETE /users/{id}` — admin only
- [ ] Ensure `password` field is **excluded** from every response (use a DTO, `@JsonIgnore`, or projection — never return the raw entity)

---

## 5. Error Handling

- [ ] Create a `@RestControllerAdvice` global exception handler
- [ ] Handle "resource not found" → `404` with descriptive message
- [ ] Handle validation failures (`MethodArgumentNotValidException`) → `400` with field-level messages
- [ ] Handle bad/duplicate data (e.g., duplicate email on register) → `409`
- [ ] Handle authentication failures (bad credentials, expired/invalid token) → `401`
- [ ] Handle authorization failures (role/ownership denied) → `403`
- [ ] Add a catch-all handler so no exception ever surfaces as a raw, unhandled `5XX`
- [ ] Verify: updating a non-existent user/product returns a clean `404`, not a stack trace

---

## 6. Security Hardening

- [ ] Sanitize/validate all inputs to prevent MongoDB operator injection (reject raw `$`-prefixed keys in user-supplied JSON, rely on typed DTOs rather than `Map`/`Document` bodies)
- [ ] Confirm HTTPS is documented/configured as the transport expectation (even if local dev runs HTTP, note the production requirement)
- [ ] Double-check every endpoint has an explicit access rule — nothing should fall through to an unintended default

---

## 7. Bonus Features

- [ ] **CORS**: configure a `CorsConfigurationSource` with explicit allowed origins/methods/headers (avoid `*` with credentials)
- [ ] **Rate limiting**: add a filter/bucket (e.g., Bucket4j) to throttle repeated requests, especially on `/auth/login`

---

## 8. Pre-Audit Self-Check (walk through `AUDIT.md` yourself)

- [ ] App runs and responds via Postman/curl
- [ ] All CRUD ops for Users and Products work end-to-end
- [ ] Login works; role restrictions are actually enforced (test as both `USER` and `ADMIN`)
- [ ] Exceptions produce proper status codes, not crashes
- [ ] `GET /products` truly works with **no** Authorization header
- [ ] Passwords are hashed in the DB; sensitive fields never appear in any response
- [ ] Annotations checklist: `@Document`, `@Id`, `@Field`, `@RestController`, `@RequestMapping`, `@GetMapping`, `@PostMapping`, `@PutMapping`, `@DeleteMapping`, `@Autowired`, `@EnableWebSecurity`, `@EnableMethodSecurity`, `@PermitAll`, `@PostAuthorize`, `@PreAuthorize`, `@NotNull`, `@Size`, `@Email` — all present and used correctly
- [ ] CORS and rate limiting demoed if claiming bonus points

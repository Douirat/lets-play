# Let's Play — Sequence Diagrams

Oriented flows for the core scenarios the audit will actually walk through.

---

## 1. Registration

```mermaid
sequenceDiagram
    actor Client
    participant AuthController
    participant UserRepository
    participant BCrypt as PasswordEncoder
    participant MongoDB

    Client->>AuthController: POST /auth/register {name, email, password}
    AuthController->>UserRepository: findByEmail(email)
    UserRepository->>MongoDB: query
    MongoDB-->>UserRepository: null (no match)
    UserRepository-->>AuthController: not found
    AuthController->>BCrypt: encode(password)
    BCrypt-->>AuthController: hashedPassword
    AuthController->>UserRepository: save(User{..., hashedPassword, role=USER})
    UserRepository->>MongoDB: insert
    MongoDB-->>UserRepository: saved User
    UserRepository-->>AuthController: saved User
    AuthController-->>Client: 201 Created {id, name, email, role} (no password)
```

---

## 2. Login (JWT issuance)

```mermaid
sequenceDiagram
    actor Client
    participant AuthController
    participant UserRepository
    participant BCrypt as PasswordEncoder
    participant JwtUtil

    Client->>AuthController: POST /auth/login {email, password}
    AuthController->>UserRepository: findByEmail(email)
    UserRepository-->>AuthController: User (or none)
    alt user not found
        AuthController-->>Client: 401 Unauthorized
    else user found
        AuthController->>BCrypt: matches(rawPassword, storedHash)
        alt password mismatch
            BCrypt-->>AuthController: false
            AuthController-->>Client: 401 Unauthorized
        else password OK
            BCrypt-->>AuthController: true
            AuthController->>JwtUtil: generateToken(userId, role)
            JwtUtil-->>AuthController: signed JWT
            AuthController-->>Client: 200 OK {token}
        end
    end
```

---

## 3. Authenticated Request Filter Chain

Every protected endpoint passes through this before reaching the controller.

```mermaid
sequenceDiagram
    actor Client
    participant JwtAuthFilter
    participant JwtUtil
    participant SecurityContext
    participant Controller

    Client->>JwtAuthFilter: request + Authorization: Bearer <token>
    JwtAuthFilter->>JwtUtil: validateToken(token)
    alt token missing/invalid/expired
        JwtUtil-->>JwtAuthFilter: invalid
        JwtAuthFilter-->>Client: 401 Unauthorized
    else token valid
        JwtUtil-->>JwtAuthFilter: claims (userId, role)
        JwtAuthFilter->>SecurityContext: setAuthentication(userId, role)
        JwtAuthFilter->>Controller: forward request
        Controller-->>Client: (proceeds to endpoint logic)
    end
```

---

## 4. Get Products (public, no auth)

```mermaid
sequenceDiagram
    actor Client
    participant ProductController
    participant ProductRepository
    participant MongoDB

    Client->>ProductController: GET /products (no Authorization header)
    Note over ProductController: @PermitAll — filter chain allows through
    ProductController->>ProductRepository: findAll()
    ProductRepository->>MongoDB: query
    MongoDB-->>ProductRepository: List<Product>
    ProductRepository-->>ProductController: List<Product>
    ProductController-->>Client: 200 OK [products]
```

---

## 5. Create Product (authenticated user)

```mermaid
sequenceDiagram
    actor Client
    participant JwtAuthFilter
    participant ProductController
    participant ProductRepository
    participant MongoDB

    Client->>JwtAuthFilter: POST /products + Bearer token + body
    JwtAuthFilter->>JwtAuthFilter: validate token, set principal
    JwtAuthFilter->>ProductController: forward
    ProductController->>ProductController: validate body (@NotNull/@Size)
    alt validation fails
        ProductController-->>Client: 400 Bad Request
    else valid
        ProductController->>ProductRepository: save(Product{..., userId=principal.id})
        ProductRepository->>MongoDB: insert
        MongoDB-->>ProductRepository: saved Product
        ProductRepository-->>ProductController: saved Product
        ProductController-->>Client: 201 Created {product}
    end
```

---

## 6. Update/Delete Product (owner-or-admin check)

```mermaid
sequenceDiagram
    actor Client
    participant JwtAuthFilter
    participant ProductController
    participant ProductRepository
    participant MongoDB

    Client->>JwtAuthFilter: PUT /products/{id} + Bearer token + body
    JwtAuthFilter->>ProductController: forward (principal set)
    ProductController->>ProductRepository: findById(id)
    ProductRepository->>MongoDB: query
    MongoDB-->>ProductRepository: Product or empty
    alt product not found
        ProductRepository-->>ProductController: empty
        ProductController-->>Client: 404 Not Found
    else product found
        ProductRepository-->>ProductController: Product
        ProductController->>ProductController: @PostAuthorize check (principal.id == product.userId OR role == ADMIN)
        alt not owner and not admin
            ProductController-->>Client: 403 Forbidden
        else authorized
            ProductController->>ProductRepository: save(updatedProduct)
            ProductRepository->>MongoDB: update
            MongoDB-->>ProductRepository: updated Product
            ProductRepository-->>ProductController: updated Product
            ProductController-->>Client: 200 OK {product}
        end
    end
```

---

## 7. Admin Lists Users

```mermaid
sequenceDiagram
    actor Client
    participant JwtAuthFilter
    participant UserController
    participant UserRepository
    participant MongoDB

    Client->>JwtAuthFilter: GET /users + Bearer token
    JwtAuthFilter->>UserController: forward (principal set)
    UserController->>UserController: @PreAuthorize("hasRole('ADMIN')")
    alt role != ADMIN
        UserController-->>Client: 403 Forbidden
    else role == ADMIN
        UserController->>UserRepository: findAll()
        UserRepository->>MongoDB: query
        MongoDB-->>UserRepository: List<User>
        UserRepository-->>UserController: List<User>
        UserController-->>Client: 200 OK [users] (passwords excluded)
    end
```

---

## 8. Global Exception Handling (any endpoint)

```mermaid
sequenceDiagram
    actor Client
    participant Controller
    participant Service/Repository
    participant GlobalExceptionHandler as @RestControllerAdvice

    Client->>Controller: request
    Controller->>Service/Repository: perform operation
    Service/Repository-->>Controller: throws exception
    Controller-->>GlobalExceptionHandler: exception propagates
    alt ResourceNotFoundException
        GlobalExceptionHandler-->>Client: 404 + message
    else MethodArgumentNotValidException
        GlobalExceptionHandler-->>Client: 400 + field errors
    else DuplicateResourceException
        GlobalExceptionHandler-->>Client: 409 + message
    else AccessDeniedException
        GlobalExceptionHandler-->>Client: 403 + message
    else BadCredentialsException
        GlobalExceptionHandler-->>Client: 401 + message
    else any other unhandled exception
        GlobalExceptionHandler-->>Client: 500 mapped to a clean, generic error body (never a raw stack trace)
    end
```

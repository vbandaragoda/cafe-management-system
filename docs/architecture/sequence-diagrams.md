# Sequence Diagrams

Five key runtime flows through the Caffora system. All requests go through
`backend/.../security/JwtAuthenticationFilter.java` before reaching a
controller; that filter is omitted from most diagrams below for clarity
except where it is the point being illustrated (diagram a).

## (a) Login

```mermaid
sequenceDiagram
    actor U as User (web or mobile)
    participant C as Client (React or Flutter)
    participant F as JwtAuthenticationFilter
    participant AC as AuthController
    participant AS as AuthService
    participant UR as UserRepository
    participant DB as MySQL (users)

    U->>C: enters email + password
    C->>AC: POST /api/auth/login {email, password}
    Note over F: unauthenticated route — filter passes request through
    AC->>AS: login(request)
    AS->>UR: findByEmail(email)
    UR->>DB: SELECT * FROM users WHERE email = ?
    DB-->>UR: user row (or none)
    UR-->>AS: Optional<User>
    alt user not found or BCrypt password mismatch
        AS-->>AC: throws BadCredentialsException
        AC-->>C: 401 {message: "Invalid email or password"}
        C-->>U: show error
    else credentials valid
        AS->>AS: JwtService.generateToken(user.id, user.role)
        AS-->>AC: AuthResponse {token, user}
        AC-->>C: 200 {token, user}
        C->>C: store JWT (web: AppContext/localStorage; mobile: shared_preferences via session_service.dart)
        C-->>U: navigate to home, role-aware nav shown
    end
```

## (b) Product retrieval (public / guest-accessible)

```mermaid
sequenceDiagram
    actor G as Guest or logged-in user
    participant C as Client (React MenuPage or Flutter menu_screen)
    participant PC as ProductController
    participant PS as ProductService
    participant PR as ProductRepository
    participant DB as MySQL (products, categories)

    G->>C: opens Menu, optionally filters by category / searches
    C->>PC: GET /api/products?categoryId=&search=
    Note over PC: no Authorization header required — public endpoint
    PC->>PS: list(categoryId, search)
    PS->>PR: findByCategoryIdAndNameContaining(...) / findAll(...)
    PR->>DB: SELECT p.*, c.name FROM products p JOIN categories c ...\nWHERE (category filter) AND (search filter)
    DB-->>PR: rows
    PR-->>PS: List<Product>
    PS-->>PC: List<ProductResponse> (DTO, includes status AVAILABLE/SOLD_OUT)
    PC-->>C: 200 [ {id, name, price, imageUrl, status, category}, ... ]
    C-->>G: render product grid (mobile: falls back to sqflite cache if this call fails offline — see diagram (e)/offline notes)
```

## (c) Order placement (authenticated customer)

```mermaid
sequenceDiagram
    actor U as Logged-in customer
    participant C as Client (CartOrdersPage or cart_screen.dart)
    participant F as JwtAuthenticationFilter
    participant OC as OrderController
    participant OS as OrderService
    participant PR as ProductRepository
    participant OR as OrderRepository
    participant OIR as OrderItemRepository
    participant DB as MySQL (products, orders, order_items)

    U->>C: taps "Place order" on cart {items:[{productId,qty,note}], tableId?, pickupType}
    C->>OC: POST /api/orders  Authorization: Bearer <JWT>
    OC->>F: (filter runs first) validate JWT, set principal + role
    F-->>OC: authenticated as CUSTOMER, userId=42
    OC->>OS: placeOrder(userId=42, request)
    loop for each requested line item
        OS->>PR: findById(productId)
        PR->>DB: SELECT * FROM products WHERE id = ?
        DB-->>PR: product row
        PR-->>OS: Product (current price, status)
        OS->>OS: reject if status = SOLD_OUT
        OS->>OS: snapshot productName + unitPrice onto the line\n(never trusts any price sent by the client)
    end
    OS->>OS: subtotal = Σ(quantity × unitPrice)\ntotal = subtotal + tax (PricingProperties.taxRate) + pickupFee
    OS->>OR: save(Order{status=PENDING, subtotal, tax, pickupFee, total, tableId, userId})
    OR->>DB: INSERT INTO orders (...)
    DB-->>OR: generated id + order_number
    OS->>OIR: saveAll(orderItems with orderId, productId, snapshot fields, lineTotal)
    OIR->>DB: INSERT INTO order_items (...) [one row per line]
    OS-->>OC: OrderResponse {orderNumber, status, items[], subtotal, tax, pickupFee, total}
    OC-->>C: 201 Created
    C-->>U: show order confirmation, proceed to payment
```

**Why the total is recomputed server-side, not trusted from the client:**
the request body carries only `productId`, `quantity`, and an optional
`note` per line — never a price. `OrderService` re-reads the authoritative
`unit_price` from the `products` table at the moment of order placement and
computes every monetary figure itself. This is the multi-table calculation
evidence item #1 referenced in the traceability matrix.

## (d) Admin product update reflected to another client

```mermaid
sequenceDiagram
    actor A as Admin (web AdminPage)
    actor B as Customer (mobile app, different device)
    participant WebC as React AdminPage
    participant PC as ProductController
    participant PS as ProductService
    participant DB as MySQL (products)
    participant MobC as Flutter menu_screen

    A->>WebC: edits product price / toggles availability
    WebC->>PC: PUT /api/products/{id}  or  PATCH /api/products/{id}/toggle-availability
    Note over PC: Authorization: Bearer <admin JWT> — role check requires ADMIN
    PC->>PS: update(id, request)
    PS->>DB: UPDATE products SET price=?, status=?, updated_at=NOW() WHERE id=?
    DB-->>PS: 1 row affected
    PS-->>PC: ProductResponse
    PC-->>WebC: 200 OK
    WebC-->>A: shows updated price/badge immediately (optimistic + response-confirmed)

    Note over B,MobC: independently, no push/socket involved
    B->>MobC: opens or refreshes Menu screen
    MobC->>PC: GET /api/products (or /products/{id})
    PC->>DB: SELECT ... WHERE id = ?
    DB-->>PC: the row the admin just updated
    PC-->>MobC: 200 {price: newPrice, status: newStatus}
    MobC-->>B: renders the new price / SOLD OUT badge
```

Caffora uses a **pull-based** consistency model: there is no WebSocket or
push layer. Because both clients read from the same MySQL row through the
same API, the mobile customer sees the admin's change on their very next
fetch (page load, pull-to-refresh, or the periodic `orderPollInterval` used
for order-status screens) — not instantly like a live push, but always
correctly, since there is only one row to disagree about. This trade-off
and its limitation are called out explicitly in `DEMONSTRATION.md`'s
"known limitations" section.

## (e) Table-QR scan → menu → dine-in order (end to end)

```mermaid
sequenceDiagram
    actor U as Customer, seated at a physical table
    participant Scan as Flutter admin_scanner_screen.dart\n(mobile_scanner package, camera)
    participant TC as TableController
    participant TS as TableService
    participant DB as MySQL (cafe_tables)
    participant Menu as menu_screen.dart
    participant Cart as cart_screen.dart
    participant OC as OrderController
    participant OS as OrderService

    Note over U: table has a printed QR code showing\ncafe://table/{tableNumber}, generated by admin via qr_flutter
    U->>Scan: opens app, taps "Scan table QR", grants camera permission
    Scan->>Scan: decodes cafe://table/7 → tableNumber=7
    alt scan fails / camera unavailable
        U->>Scan: taps "Enter table number manually"
        Scan->>Scan: user types 7
    end
    Scan->>TC: GET /api/tables/lookup?code=cafe://table/7
    Note over TC: public endpoint — works for GUEST too
    TC->>TS: lookupByCode(code)
    TS->>DB: SELECT * FROM cafe_tables WHERE qr_code_value = ?
    DB-->>TS: CafeTable{id=7, tableNumber=7}
    TS-->>TC: TableResponse
    TC-->>Scan: 200 {tableId:7, tableNumber:7}
    Scan->>Menu: navigate to Menu, tableId=7 carried in navigation state
    U->>Menu: browses categories/products, adds items to cart
    Menu->>Cart: cart updated (cart_provider.dart, in-memory + persisted)
    U->>Cart: taps "Place order"
    Cart->>OC: POST /api/orders {items[], tableId: 7, pickupType: DINE_IN}
    OC->>OS: placeOrder(...) — same flow as diagram (c), with tableId set
    OS-->>OC: OrderResponse {orderNumber, tableId: 7, status: PENDING}
    OC-->>Cart: 201 Created
    Cart-->>U: confirmation screen: "Order #... — Table 7"
    Note over U: admin's Orders queue (web AdminPage or mobile admin_screen.dart)\nnow shows this order tagged "Table 7" on its next fetch
```

If the network is unavailable at any point in this flow, the mobile app
falls back to its `sqflite` cache for menu browsing (via
`connectivity_provider.dart` + `local_db_service.dart`) and shows the
"offline — showing cached data" banner (`offline_banner.dart`); order
*placement* itself requires connectivity, since it must reach the
authoritative backend.

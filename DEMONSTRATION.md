# Caffora — Demonstration Script (~15 minutes)

Run this against a live stack: backend via `docker compose up --build`
(or local Maven), web via `npm run dev`, mobile via `flutter run` on an
emulator/device — all pointed at the same backend instance (see root
`README.md`). Two screens/windows side by side (web browser + mobile
emulator) make steps 12–13 much clearer.

## Demo flow

1. **Intro (1 min).** State what Caffora is: a cafe ordering + management
   system with a shared Spring Boot/MySQL backend, a React web app, and a
   Flutter Android app — one system, three surfaces, built from a real
   Figma design. Mention the three roles: ADMIN, CUSTOMER, GUEST.

2. **Guest browsing (1 min).** Open the web app with no login. Browse the
   menu, filter by category, search a product. Point out this works with
   zero authentication — `GET /products` is a public endpoint.

3. **Register / login (1.5 min).** Register a new customer account on the
   web app (or mobile — pick one, mention the other is identical against
   the same API). Show the JWT-backed session start; note password is
   BCrypt-hashed server-side and never round-trips in plaintext after
   registration.

4. **Table QR scan (mobile) (1.5 min).** On the mobile app, tap "Scan table
   QR," point the camera at a printed/displayed table QR code (generated
   earlier from the admin Tables screen). Show the app resolving the table
   via `GET /tables/lookup?code=...` and landing on the menu with the table
   already attached. Briefly show the manual "enter table number" fallback
   too.

5. **Menu → cart (1 min).** Add 2–3 items to the cart, adjust a quantity,
   add a note to one item (e.g. "oat milk"). Show the running subtotal.

6. **Checkout + simulated payment (1.5 min).** Place the order. Show the
   order confirmation screen with a server-returned total (call out: the
   client sent only product IDs/quantities — the price came back from the
   server). Trigger the simulated payment (`POST /payments`) and show it
   resolves instantly to `PAID`.

7. **Order tracking (1 min).** Show the order appearing in "My Orders"
   with status `PENDING`.

8. **Admin login (0.5 min).** Log out, log in as the seeded admin account
   (web).

9. **Admin dashboard + reports (1.5 min).** Show `GET /admin/dashboard`
   (today's gross sales, active order count, average prep time) and the
   sales/top-products reports — point out these are real `GROUP BY`
   queries over `orders`/`order_items`/`products`, not hardcoded numbers.

10. **Product + category CRUD (1.5 min).** Create a new category, create a
    product in it, edit an existing product's price, toggle a product to
    `SOLD_OUT`.

11. **Order status update (1 min).** Find the order placed in step 6 in the
    admin order queue, transition it `PENDING → PREPARING`.

12. **Show the change reflected on the customer's device (1 min).** Switch
    to the mobile app (still logged in as the customer from step 3),
    refresh/reopen the order detail screen, and show the status now reads
    `PREPARING` — driven purely by both apps reading the same MySQL row
    through the same API, no push mechanism involved.

13. **Light/dark mode toggle (0.5 min).** Toggle dark mode on mobile (or
    web), show the Figma-matched dark palette apply immediately, and note
    it's persisted (kill and reopen the app if time allows).

14. **Offline mode demo (1 min).** Enable airplane mode on the mobile
    device/emulator, reopen the menu screen, show the "offline — showing
    cached data" banner and that previously-loaded products still render
    from the local `sqflite` cache. Turn airplane mode back off and show
    the banner clear.

15. **Architecture/security explanation (1 min).** Briefly recap: one
    shared Spring Boot backend behind JWT auth and role-based Spring
    Security rules; both clients are equally "dumb" HTTPS/JSON clients;
    the database is only reachable from the backend.

16. **Wrap-up (0.5 min).** Summarize what was shown against the
    requirements: 3 roles, full CRUD, guest access, remote data store,
    multi-table calculation (checkout total + reports), cross-client
    update reflection, a mobile device feature (QR/camera), offline mode,
    light/dark mode, 7 database tables, responsive/well-designed screens.

## Likely questions — real answers

**Why React for the web app?**
Component-based UI with a large ecosystem and fast iteration via Vite's
dev server; React Router gives straightforward client-side routing for a
small number of pages (`HomePage`, `AuthPage`, `MenuPage`,
`CartOrdersPage`, `AdminPage`) without needing a heavier meta-framework,
since the app has no SEO/SSR requirement — it's a logged-in-mostly
ordering tool, not a public content site.

**Why Flutter for the mobile app?**
A single Dart codebase compiles to a real native Android app with direct
access to camera (QR scanning), GPS, and contacts via well-maintained
plugins (`mobile_scanner`, `geolocator`, `flutter_contacts`), while
keeping UI, state (`provider`), and business logic in one language and one
codebase — avoiding the overhead of maintaining separate native
Kotlin/Swift codebases for what the coursework scope needs (a single
Android target).

**Why Spring Boot for the backend?**
Mature, batteries-included framework for exactly this shape of problem:
Spring Security gives a well-understood, testable way to enforce
role-based authorization; Spring Data JPA maps entities to MySQL tables
with minimal boilerplate; it's a natural fit for a REST API needing strict
server-side authorization and validation — which this system leans on
heavily (never trusting price or role from the client).

**Why one shared backend instead of two (or backend logic duplicated in
each client)?**
Single source of truth: two clients hitting two independently
business-logic'd backends (or worse, doing pricing/authorization
client-side) would drift — e.g. a tax-rate change shipped to one client
but not the other would silently produce different totals for the same
cart. One backend means one place enforces "only ADMIN can change order
status" and one place computes "total = Σ(qty×price)+tax+fee." Full
reasoning: `docs/architecture/system-context.md`.

**Why REST instead of GraphQL or gRPC?**
The API surface is a fixed, well-understood set of resources
(users/categories/products/tables/orders/payments) with conventional
CRUD-plus-a-few-actions shapes (`toggle-availability`, `status`) — REST
maps onto that directly, is simple for both a browser `fetch` and Dart's
`http` package to consume without extra tooling/codegen, and keeps the
learning curve low across a team split across two client stacks.

**Why MySQL?**
The data is inherently relational — orders reference users, tables, and
have child order-item rows; products reference categories; payments are
1:1 with orders. Foreign keys and constraints (unique table numbers,
unique QR values, `CHECK` constraints on non-negative money columns) are a
natural fit for a relational database, and MySQL is free, widely
supported by every hosting option considered in
`docs/architecture/deployment-diagram.md`, and is what Spring Data JPA/
Hibernate targets cleanly via `MySQLDialect`.

**How does authentication/authorization actually work?**
Stateless JWTs: `AuthService` issues a signed token (jjwt) containing the
user's ID and role on successful login. Every subsequent request carries
it as `Authorization: Bearer <token>`; `JwtAuthenticationFilter` validates
the signature and expiry on every request and populates Spring Security's
context, which `SecurityConfig`'s route rules then check against
(`ADMIN`-only routes reject anything without the `ADMIN` authority). No
server-side session state is kept — the token itself is the credential.

**How are guests blocked from protected resources?**
By the absence of a valid `Authorization` header: `SecurityConfig` marks a
small explicit set of routes `permitAll()` (auth endpoints, category/
product reads, table lookup); everything else requires a valid,
unexpired, correctly-signed JWT, enforced in
`JwtAuthenticationFilter`/Spring Security's filter chain — not by the
client hiding a button. A GUEST calling `POST /orders` gets a 401 regardless
of what the UI shows.

**How do mobile and web each talk to the backend?**
Both use a single shared HTTP wrapper per codebase — `web/src/api/
client.js`'s `apiRequest()` on the web side, `mobile/lib/services/
api_client.dart` on the mobile side — that attaches the bearer token,
serializes JSON, and normalizes the backend's error shape (`status`,
`message`, `fieldErrors`) into a typed error (`ApiError` / `ApiException`)
that every screen can handle consistently.

**How does QR scanning work end to end?**
Each physical table has a `cafe_tables` row with a unique `qr_code_value`
(e.g. `cafe://table/7`), rendered as a printable QR via `qr_flutter` from
the admin Tables screen. The mobile app's `mobile_scanner` package reads
the device camera, decodes the QR payload, and calls the public `GET
/tables/lookup?code=...` endpoint to resolve it to a real table before
attaching that `tableId` to the order at checkout. Full flow:
`docs/architecture/sequence-diagrams.md` diagram (e).

**What happens when the mobile app goes offline?**
`connectivity_plus` detects the network loss (`connectivity_provider.dart`);
the app falls back to `sqflite`-cached menu/order data
(`local_db_service.dart`) and shows a persistent "offline — showing cached
data" banner (`offline_banner.dart`) rather than a blank screen or a
generic error. Placing a *new* order still requires connectivity, since it
must reach the authoritative backend — the app makes that limitation
explicit rather than queuing writes silently (which would risk placing an
order against stale prices/availability).

**How is concurrent access / order consistency handled?**
There is a single authoritative `orders`/`order_items` row set per order in
MySQL; the backend recomputes prices from the live `products` table at the
moment of order placement rather than trusting anything from the client,
so two customers ordering the same product simultaneously each get an
order priced from whatever the product's price actually was at their
respective request times — there's no shared mutable client-side state to
race on. Stock/availability is a simple `AVAILABLE`/`SOLD_OUT` flag rather
than a decrementing counter, so there is no inventory race condition to
resolve in this version of the system (a known simplification, see
"Known limitations" below).

**How is the order total calculated, and which tables participate?**
`total = subtotal + tax + pickup_fee`, where `subtotal = Σ(order_items.
quantity × order_items.unit_price)`. This is computed once, server-side,
in `OrderService.placeOrder()`, using the live `products.price` at that
moment (then snapshotted onto `order_items.unit_price`/`product_name` so
it's immutable afterward). Tables involved: `products` (source price),
`orders` (subtotal/tax/pickup_fee/total columns), `order_items` (the
per-line figures being summed). The same `order_items`↔`products`↔`orders`
relationship also backs the `/admin/reports/sales` and
`/admin/reports/top-products` aggregate queries.

**How was accessibility considered?**
Semantic HTML structure and labeled form inputs on the web app, sufficient
text/background contrast chosen directly from the Figma tokens (dark
espresso text on cream, light cream text on dark espresso — not
low-contrast decorative colors used as text), `alt` text on product
images, and keyboard-reachable interactive elements. This was a design-time
and code-review consideration; no automated accessibility audit tool or
screen-reader test session was run as part of this documentation pass —
see `docs/testing/test-plan.md` WEB-14/WEB-15 for the pending manual
verification.

**How was testing approached?**
A 72-case test matrix (`docs/testing/test-plan.md`) covering backend
auth/authorization/validation/CRUD/calculation/reporting, web
browsing/cart/checkout/admin/responsive/accessibility/error-handling, and
mobile login/QR-scan/cart/offline/theming/orientation/device-permissions —
written against the real implementation but **not executed** in the
sandboxed documentation environment (no Flutter SDK, no package registry
access there); the team runs it for real against a live stack before
submission.

**Why these key UI decisions (palette, bottom nav, QR-first entry)?**
See `docs/design/design-progression.md` section 4 in full — in short: a
warm rust/espresso palette reads as "cafe," not "generic SaaS"; a bottom
tab bar suits one-handed use while seated at a table; QR-first mobile entry
collapses "just sat down" to "menu open, table linked" into a single scan
instead of several manual steps.

**What are the known limitations?**
(1) No real payment gateway — payments are simulated and always succeed
instantly; a production version would integrate Stripe or similar. (2) No
push/WebSocket layer — cross-client updates are pull-based (next fetch/
poll), not instant; acceptable for an order-status use case but not
real-time chat-grade. (3) Stock is a boolean AVAILABLE/SOLD_OUT flag, not a
decrementing quantity, so there's no true inventory-race handling. (4) No
production infrastructure is actually provisioned yet — see
`docs/architecture/deployment-diagram.md`'s manual-steps table. (5) The
test matrix has not been executed against a live stack as part of this
documentation pass.

**How would this scale?**
The backend is stateless (JWT-based, no server-side session), so it can
run as multiple horizontally-scaled instances behind a load balancer
without any sticky-session requirement; the bottleneck would be MySQL,
which could be scaled with read replicas for the read-heavy menu/report
endpoints, or with connection pooling tuning first, before anything more
drastic. The reporting queries (`GROUP BY` over potentially large
`order_items` tables) are the most likely place to need added indexes or
a move to a scheduled/materialized aggregate as order volume grows, rather
than computing them live on every request.

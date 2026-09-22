# Caffora Backend

Spring Boot REST API for the Caffora coffee ordering app (pairs with the React frontend generated earlier from the Figma design). Java 17, Spring Boot 3.3, Spring Security with stateless JWT auth, Spring Data JPA, MySQL.

## Stack

- **Java 17** / **Spring Boot 3.3.4**
- **Spring Web** — REST controllers
- **Spring Security 6** — stateless JWT authentication, role-based authorization (`CUSTOMER`, `ADMIN`)
- **Spring Data JPA** + **MySQL 8**
- **jjwt 0.12** — JWT issuing/verification
- **Bean Validation** (`jakarta.validation`) on all request DTOs
- **Lombok** — boilerplate reduction on entities
- **Docker + docker-compose** — one-command local stack (MySQL + API)

## Project layout

```
src/main/java/com/caffora/backend/
  config/       Spring config: security, CORS, pricing, admin-seed properties, data seeder
  controller/   REST controllers (Auth, Menu, Order, Admin)
  dto/          Request/response records, grouped by feature
  entity/       JPA entities + enums
  exception/    Custom exceptions + a single @RestControllerAdvice for consistent error JSON
  repository/   Spring Data JPA repositories
  security/     JWT service, filter, UserDetails adapter
  service/      Business logic
  util/         Order number generator
```

## Running locally

### Option A — Docker (recommended, zero local setup)

```bash
cp .env.example .env    # edit values as you like
docker compose up --build
```

The API comes up on `http://localhost:8080` once MySQL passes its healthcheck. An admin account and the starter menu (matching the Figma design) are seeded automatically on first boot — see `ADMIN_SEED_EMAIL` / `ADMIN_SEED_PASSWORD` in `.env.example`.

### Option B — Local Maven + your own MySQL

```bash
mysql -u root -p -e "CREATE DATABASE caffora;"

export DB_HOST=localhost DB_PORT=3306 DB_NAME=caffora DB_USERNAME=root DB_PASSWORD=yourpassword
export JWT_SECRET=some-long-random-string-at-least-32-bytes

mvn spring-boot:run
```

> **Note on this deliverable:** this project was generated and reviewed in a sandboxed environment whose network policy blocks Maven Central, so `mvn compile`/`mvn test` could not be executed here to produce a green build log. The code was written and manually re-checked against Spring Boot 3.3 / Spring Security 6 / jjwt 0.12 APIs, and an integration test suite (`src/test/java`) is included so you can verify it yourself with one command as soon as you have normal internet access:
> ```bash
> mvn test
> ```
> If anything doesn't compile in your environment, paste the error back to me and I'll fix it directly.

## Authentication

JWT-based, stateless. Register or log in to get a token, then send it as `Authorization: Bearer <token>` on subsequent requests.

```bash
# Register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Elena Woods","email":"elena@example.com","password":"SecurePass123"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"elena@example.com","password":"SecurePass123"}'

# Current user
curl http://localhost:8080/api/auth/me -H "Authorization: Bearer <TOKEN>"
```

The seeded admin (`ADMIN_SEED_EMAIL` / `ADMIN_SEED_PASSWORD`) logs in the same way via `/api/auth/login` and receives a token with the `ADMIN` role baked in.

## API reference

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/register` | public | Create a customer account, returns a JWT |
| POST | `/api/auth/login` | public | Log in, returns a JWT |
| GET | `/api/auth/me` | any authenticated user | Current user profile |
| GET | `/api/menu?category=&search=` | public | List menu items, optional category filter + name search |
| GET | `/api/menu/{id}` | public | Single menu item |
| POST | `/api/menu` | ADMIN | Create a menu item |
| PUT | `/api/menu/{id}` | ADMIN | Replace a menu item's fields |
| PATCH | `/api/menu/{id}/status` | ADMIN | Set status explicitly (`AVAILABLE` / `SOLD_OUT`) |
| PATCH | `/api/menu/{id}/toggle-availability` | ADMIN | Flip Available ⇄ Sold Out (used by the admin table's status pill) |
| DELETE | `/api/menu/{id}` | ADMIN | Delete a menu item |
| POST | `/api/orders` | customer | Place an order from cart line items (server recomputes all prices/totals — never trusts client-sent amounts) |
| GET | `/api/orders/my` | customer | Current user's order history, newest first |
| GET | `/api/orders/{id}` | owner or ADMIN | Single order detail (for the live tracker) |
| GET | `/api/orders?active=true` | ADMIN | All orders, or just the active kitchen queue |
| PATCH | `/api/orders/{id}/status` | ADMIN | Advance a ticket's status (Pending → Preparing → Ready → Completed) |
| GET | `/api/admin/dashboard` | ADMIN | Today's gross sales, active order counts, average prep time |

Full request/response shapes are defined as Java records under `dto/` — e.g. `PlaceOrderRequest`, `OrderResponse`, `MenuItemRequest`. Validation errors come back as HTTP 400 with a `fieldErrors` array; not-found/conflict/auth errors come back as HTTP 404/409/401/403 — all in the same `ErrorResponse` JSON shape (see `exception/ErrorResponse.java`).

### Placing an order

```bash
curl -X POST http://localhost:8080/api/orders \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
        "items": [
          { "menuItemId": 1, "quantity": 1, "note": "Oat milk, extra hot" },
          { "menuItemId": 2, "quantity": 2 }
        ],
        "pickupType": "COUNTER"
      }'
```

The response includes the generated `orderNumber` (e.g. `"C408"`, matching the frontend's ticket format) and the server-computed `subtotal` / `pickupFee` / `tax` / `total`.

## How this maps to the frontend

- The React app's in-memory `AppContext` cart becomes real, persisted orders once `POST /api/orders` is wired in (replace the local `placeOrder()` with an API call; the response shape lines up with the `lastOrder` object already used by the order tracker).
- `MenuPage`'s search + category filter map directly to `GET /api/menu?category=&search=`.
- `AdminPage`'s menu table and kitchen queue map to the menu CRUD endpoints and `GET /api/orders?active=true` + `PATCH /api/orders/{id}/status`.
- `AdminPage`'s three metric cards map to `GET /api/admin/dashboard`.
- Tax rate (8%) and pickup fee ($0.50) are configurable server-side (`caffora.pricing.*` in `application.yml`), not hardcoded in the frontend — the backend is the source of truth for money.

## Pricing & business rules worth knowing

- Order totals are **always recomputed server-side** from the current menu item prices at order time — a client can't manipulate prices by sending arbitrary numbers.
- A sold-out item cannot be ordered; `POST /api/orders` returns `400` naming the offending item.
- `OrderItem` snapshots the item's name and price at order time, so editing or deleting a menu item later doesn't corrupt historical order records.
- Deleting a `MenuItem` that's referenced by existing orders is blocked at the database level (foreign key) and surfaces as a clean `409 Conflict` rather than a stack trace.

## Security notes before deploying for real

1. Set a long, random `JWT_SECRET` (`openssl rand -base64 48`) — the default in `.env.example` is a placeholder.
2. Change `ADMIN_SEED_PASSWORD` immediately after first login, or set your own before first boot.
3. `spring.jpa.hibernate.ddl-auto=update` is convenient for development; for production, switch to a real migration tool (Flyway/Liquibase) and set it to `validate`.
4. Restrict `CORS_ALLOWED_ORIGINS` to your actual deployed frontend origin(s).

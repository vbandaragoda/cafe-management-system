# Caffora — Cafe Management System

Caffora is a full cafe ordering and management system built across three
coordinated codebases:

- **`backend/`** — Spring Boot 3.3.4 / Java 17 REST API, JWT auth, MySQL
  via Spring Data JPA/Hibernate.
- **`web/`** — React 18 + Vite + Tailwind CSS web app (customer ordering +
  full admin console).
- **`mobile/`** — Flutter/Dart Android app (customer ordering with a
  table-QR-scan dine-in flow, offline caching, light/dark theming, plus an
  admin surface).

All three talk to **one shared backend and one shared MySQL database** —
see `docs/architecture/system-context.md` for why this matters (single
source of truth for data, business rules, and authorization).

## Feature list

- Three roles: **ADMIN**, **CUSTOMER** (registered), **GUEST**
  (unauthenticated).
- Email/password registration and login, JWT-based sessions, BCrypt
  password hashing.
- Public menu browsing by category and search, with live availability
  (`AVAILABLE`/`SOLD_OUT`).
- Cart, checkout, and a simulated instant-success payment (no real
  payment gateway).
- Order placement with **server-side price recomputation** — the client
  never sends prices, only product IDs and quantities.
- Order status lifecycle: `PENDING → PREPARING → READY → COMPLETED` (or
  `CANCELLED`), managed by admins, visible to the owning customer.
- Table-QR dine-in flow (mobile): scan a physical table's QR code →
  resolve the table → order tied to that table — with a manual
  table-number fallback.
- Admin console (web + mobile): category/product CRUD, table management
  with printable QR codes, live order queue, sales dashboard, and
  sales/top-products reports.
- Mobile device features: camera-based QR scanning, geolocation
  (distance-to-cafe), and explicit stored-contacts access ("Invite a
  friend").
- Offline support (mobile): last-fetched menu/orders cached in `sqflite`,
  with a visible "offline — showing cached data" banner.
- Light/dark mode on both web and mobile, from the same Figma design
  tokens, persisted across sessions.

## Tech stack

| Layer | Technology |
|---|---|
| Backend | Java 17, Spring Boot 3.3.4, Spring Security, Spring Data JPA, jjwt 0.12, MySQL 8, Maven |
| Web | React 18, Vite 5, Tailwind CSS 3, React Router 6 |
| Mobile | Flutter/Dart (SDK ≥3.3.0), Provider, `http`, `sqflite`, `mobile_scanner`, `qr_flutter`, `geolocator`, `flutter_contacts`, `connectivity_plus`, `shared_preferences`, `google_fonts` |
| Database | MySQL 8.4 (see `docs/database/schema.sql`) |

## Architecture summary

React and Flutter are both thin HTTPS/JSON clients of the same Spring Boot
REST API; the API is the only process that talks to MySQL. Full details
and diagrams: `docs/architecture/system-context.md`,
`component-diagram.md`, `deployment-diagram.md`, and
`sequence-diagrams.md`.

## Roles

| Role | Can do |
|---|---|
| **GUEST** | Browse categories/products, look up a table by QR code, register, log in |
| **CUSTOMER** | Everything GUEST can, plus: place orders, view own order history, make (simulated) payments, use device features (geolocation, invite-a-friend) |
| **ADMIN** | Everything CUSTOMER can, plus: full category/product/table CRUD, view/update any order's status, view dashboard and reports, view the user list |

## API reference

Base path: `/api`. Auth: `Authorization: Bearer <JWT>` where noted.

| Method & path | Auth | Description |
|---|---|---|
| `POST /auth/register` | Public | Register a new CUSTOMER account |
| `POST /auth/login` | Public | Log in, returns JWT + user |
| `GET /auth/me` | Any authenticated | Current user's profile |
| `GET /categories` | Public | List categories |
| `POST /categories` | ADMIN | Create category |
| `PUT /categories/{id}` | ADMIN | Update category |
| `DELETE /categories/{id}` | ADMIN | Delete category |
| `GET /products?categoryId=&search=` | Public | List/filter/search products |
| `GET /products/{id}` | Public | Single product |
| `POST /products` | ADMIN | Create product |
| `PUT /products/{id}` | ADMIN | Update product |
| `PATCH /products/{id}/toggle-availability` | ADMIN | Flip AVAILABLE/SOLD_OUT |
| `DELETE /products/{id}` | ADMIN | Delete product |
| `GET /tables` | ADMIN | List tables |
| `POST /tables` | ADMIN | Create table (generates QR value) |
| `GET /tables/lookup?code=` | Public | Resolve a scanned/entered table code |
| `POST /orders` | Authenticated | Place an order (`items[]`, `tableId?`, `pickupType`) |
| `GET /orders/my` | Authenticated | Caller's own order history |
| `GET /orders/{id}` | Owner or ADMIN | Single order |
| `GET /orders?active=true` | ADMIN | Active order queue |
| `PUT /orders/{id}/status` | ADMIN | Transition order status |
| `POST /payments` | Authenticated | Simulated instant-success payment capture |
| `GET /payments/{id}` | Owner or ADMIN | Single payment |
| `GET /payments/order/{orderId}` | Owner or ADMIN | Payment for a given order |
| `GET /admin/dashboard` | ADMIN | Today's gross sales, active order count, avg prep time |
| `GET /admin/reports/sales?range=daily\|monthly` | ADMIN | Sales aggregate report |
| `GET /admin/reports/top-products?limit=5` | ADMIN | Top-selling products by quantity/revenue |
| `GET /admin/users` | ADMIN | List all users |

## Setup instructions

### Backend

Option A — Docker (recommended, matches `backend/docker-compose.yml`):

```
cd backend
cp .env.example .env
# edit .env: set real DB_PASSWORD/DB_ROOT_PASSWORD, a strong JWT_SECRET, etc.
docker compose up --build
```

This starts MySQL 8.4 and the Spring Boot API together; the API listens on
`SERVER_PORT` (default `8080`).

Option B — Local Maven + a local MySQL instance:

```
cd backend
# ensure a MySQL server is running and matches the DB_* values in .env
mvn spring-boot:run
```

Either way, a bootstrap admin account is created on first startup from
`ADMIN_SEED_EMAIL`/`ADMIN_SEED_PASSWORD`/`ADMIN_SEED_NAME` (see
`backend/.env.example` — **do not use the example placeholder credentials
in any real deployment; change them immediately**).

### Web

```
cd web
npm install
npm run dev
```

Set `VITE_API_URL` (e.g. in a `web/.env.local` file) to point at the
running backend, e.g.:

```
VITE_API_URL=http://localhost:8080/api
```

If unset, it falls back to `http://localhost:8080/api` (see
`web/src/api/client.js`).

### Mobile

```
cd mobile
flutter create . --platforms=android   # only needed once, to generate the android/ project files
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

Notes on `API_BASE_URL` (see `mobile/lib/core/constants.dart`):
- Android emulator → host machine's localhost: use `http://10.0.2.2:8080/api` (the default).
- iOS simulator → `http://localhost:8080/api`.
- A physical device → your development machine's LAN IP, e.g.
  `http://192.168.1.50:8080/api`, with the phone on the same network.

### Pointing all three clients at the same backend

Run exactly one backend instance (local Docker, local Maven, or a deployed
one) and set `VITE_API_URL` (web) and `--dart-define=API_BASE_URL=...`
(mobile) to that same instance's URL. This is what makes the
cross-client-update-reflection behavior described in
`docs/architecture/sequence-diagrams.md` (diagram d) actually observable —
two clients pointed at two different backend instances would not see each
other's changes.

### Default seeded admin credentials

Reference only — see `backend/.env.example`'s `ADMIN_SEED_EMAIL` /
`ADMIN_SEED_PASSWORD` values, which are placeholders meant to be changed
before any real deployment. This README does not restate them as if they
were safe to keep — treat the values in `.env.example` as "change before
you deploy anywhere reachable by anyone else."

## Testing

See `docs/testing/test-plan.md` for the full test matrix (72 test cases
across backend, web, and mobile). It states plainly that these cases were
not executed against a live stack as part of writing the documentation —
run them for real before submission.

## Deployment

See `docs/publishing/publishing-plan.md` for taking the web app to a
static HTTPS host and the mobile app through Play Store publishing
(signing, listing requirements, privacy policy, data safety form), and
`docs/architecture/deployment-diagram.md` for the target production
topology.

## Verification notes (read before assuming this was tested end-to-end)

This documentation, and the accompanying review of the codebase, was
produced in a **sandboxed environment with no Maven Central, npm registry,
or pub.dev network access, and no Flutter SDK installed**. Concretely,
that means **`mvn test`/`mvn verify`, `flutter analyze`/`flutter test`, and
a full `npm run build` were not run end-to-end here**, and no emulator or
device was used to exercise the running apps.

What verification *was* done, per engineer/codebase, was manual code
review: reading the actual source files in `backend/src/`, `web/src/`, and
`mobile/lib/` against the authoritative API/entity spec this documentation
is built from; checking that file/package structure, naming, and endpoint
shapes referenced throughout `docs/` correspond to real files in the
repository at the time of writing; and basic structural sanity checks
(e.g. brace/bracket balance, consistent import/package naming) rather than
a compiler or test runner.

**Before submission, the team should run the real toolchain** — `mvn
clean verify` (or `mvn spring-boot:run` against a live MySQL) for the
backend, `npm install && npm run build` for the web app, and `flutter pub
get && flutter analyze && flutter run` for the mobile app — and fix
whatever errors surface. Two engineers were making active changes to
`backend/`, `web/`, and `mobile/` in parallel with this documentation pass
(entity renames, new admin screens, the QR dine-in rework); this
documentation describes the **target, final spec** all three are building
toward, so a final read-through of the actual merged code against this
README and the traceability matrix is recommended once that work lands.
#   c a f e - m a n a g e m e n t - s y s t e m  
 
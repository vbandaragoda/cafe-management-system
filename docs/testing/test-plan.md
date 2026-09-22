# Caffora Test Plan

## Environment limitation (read first)

This test plan was authored in a sandboxed documentation environment that
has **no Flutter SDK installed, no Maven Central / npm registry network
access, and no browser test runner available**. That means the test cases
below could not actually be *executed* here — no `mvn test`, no `flutter
test`/`flutter analyze`, no `npm run build`/browser run was performed as
part of writing this document. Every row's **Actual Result** and **Status**
columns are therefore left as `Pending manual execution` rather than
filled in with invented outcomes. The team must run these test cases
against a real running stack (`docker compose up --build` for the backend,
`npm run dev` for the web app, `flutter run` for the mobile app — see the
root `README.md`) and record real results before submission. What manual
code review *was* done is described in `README.md`'s "Verification notes"
section.

## Legend

- **Status** values once executed: `Pass`, `Fail`, `Blocked`, `Pending manual execution`.
- IDs: `BE-##` backend, `WEB-##` web, `MOB-##` mobile.

## Backend test cases (Spring Boot API)

| Test ID | Feature | Test Case | Precondition | Steps | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|---|
| BE-01 | Auth — Register | New user can register with valid data | Backend running, MySQL reachable | 1. POST `/api/auth/register` with unique email, name, password | 201 Created, JWT + user returned, password never in response | | Pending manual execution |
| BE-02 | Auth — Register | Duplicate email is rejected | A user with `test@x.com` already exists | 1. POST `/api/auth/register` with the same email | 409 Conflict, `EmailAlreadyInUseException` message, no new row created | | Pending manual execution |
| BE-03 | Auth — Register | Validation rejects malformed input | none | 1. POST `/api/auth/register` with blank name, invalid email, 3-char password | 400 Bad Request with `fieldErrors` naming each invalid field | | Pending manual execution |
| BE-04 | Auth — Login | Valid credentials return a JWT | A registered user exists | 1. POST `/api/auth/login` with correct email/password | 200 OK, `token` + `user{role}` in body | | Pending manual execution |
| BE-05 | Auth — Login | Wrong password is rejected | A registered user exists | 1. POST `/api/auth/login` with wrong password | 401 Unauthorized, generic "Invalid email or password" (no user-enumeration hint) | | Pending manual execution |
| BE-06 | Auth — Me | `/auth/me` returns the caller's own profile | Valid JWT from BE-04 | 1. GET `/api/auth/me` with `Authorization: Bearer <token>` | 200 OK, matches the logged-in user, password hash never included | | Pending manual execution |
| BE-07 | Authorization | GUEST is blocked from protected routes | No JWT | 1. GET `/api/orders/my` with no Authorization header | 401 Unauthorized | | Pending manual execution |
| BE-08 | Authorization | CUSTOMER is blocked from admin routes | Valid CUSTOMER JWT | 1. POST `/api/products` with a CUSTOMER token | 403 Forbidden | | Pending manual execution |
| BE-09 | Authorization | ADMIN can access admin routes | Valid ADMIN JWT (seeded via `ADMIN_SEED_EMAIL`) | 1. GET `/api/admin/dashboard` with ADMIN token | 200 OK with dashboard payload | | Pending manual execution |
| BE-10 | Categories CRUD | Admin creates a category | Valid ADMIN JWT | 1. POST `/api/categories` `{name:"Cold Brew"}` | 201 Created, category persisted, unique-name constraint respected | | Pending manual execution |
| BE-11 | Categories CRUD | Public can list categories | none | 1. GET `/api/categories` with no auth | 200 OK, array of categories | | Pending manual execution |
| BE-12 | Products CRUD | Admin creates a product linked to a category | ADMIN JWT, category exists | 1. POST `/api/products` with valid `categoryId`, name, price, status | 201 Created, product returned with nested category | | Pending manual execution |
| BE-13 | Products CRUD | Product creation rejects unknown category | ADMIN JWT | 1. POST `/api/products` with `categoryId: 999999` | 404/400 with a clear "category not found" message | | Pending manual execution |
| BE-14 | Products — filtering | `GET /products` filters by category and search text | Several products across categories seeded | 1. GET `/api/products?categoryId=2&search=latte` | 200 OK, only matching products returned | | Pending manual execution |
| BE-15 | Products — toggle | Admin toggles availability | ADMIN JWT, product exists, status=AVAILABLE | 1. PATCH `/api/products/{id}/toggle-availability` | 200 OK, status flips to SOLD_OUT; a second call flips it back | | Pending manual execution |
| BE-16 | Products CRUD | Admin deletes a product not referenced by any order | ADMIN JWT, unreferenced product exists | 1. DELETE `/api/products/{id}` | 204 No Content, row removed | | Pending manual execution |
| BE-17 | Products CRUD | Deleting a product referenced by historical orders is prevented or handled safely | ADMIN JWT, product has order_items referencing it | 1. DELETE `/api/products/{id}` | Request fails cleanly (FK `ON DELETE RESTRICT`) rather than corrupting order history | | Pending manual execution |
| BE-18 | Tables | Admin creates a table and its QR value is unique | ADMIN JWT | 1. POST `/api/tables` `{tableNumber:12}` | 201 Created, `qrCodeValue` generated and unique | | Pending manual execution |
| BE-19 | Tables | Public QR lookup resolves a table | Table 12 exists | 1. GET `/api/tables/lookup?code=cafe://table/12` (no auth) | 200 OK, correct table returned | | Pending manual execution |
| BE-20 | Tables | QR lookup with unknown code fails gracefully | none | 1. GET `/api/tables/lookup?code=cafe://table/999` | 404 Not Found with clear message (drives mobile's "table not found" UI) | | Pending manual execution |
| BE-21 | Order placement | Total is computed server-side from current prices, not client input | CUSTOMER JWT, product exists priced $4.50 | 1. POST `/api/orders` with `productId`, `quantity:2`, no price field accepted at all | 201 Created; `subtotal = 9.00`, `total = subtotal+tax+pickupFee` matches `PricingProperties` | | Pending manual execution |
| BE-22 | Order placement | Ordering a SOLD_OUT product is rejected | Product status=SOLD_OUT | 1. POST `/api/orders` including that product | 400 Bad Request, order not created | | Pending manual execution |
| BE-23 | Order placement | Dine-in order stores tableId; pickup order stores null | CUSTOMER JWT, table exists | 1. POST `/api/orders` with `tableId` set → order.tableId set. 2. POST again with no `tableId` | Both succeed; first has non-null `table_id`, second has null | | Pending manual execution |
| BE-24 | Order retrieval | Customer can only view their own orders | Two customers, each with an order | 1. Customer A: GET `/api/orders/{ownOrderId}` → 200. 2. Customer A: GET `/api/orders/{B's orderId}` | Second call returns 403/404, not another customer's data | | Pending manual execution |
| BE-25 | Order status | Admin transitions an order through its lifecycle | ADMIN JWT, order exists PENDING | 1. PUT `/api/orders/{id}/status` PREPARING, then READY, then COMPLETED | Each transition returns 200 with updated status and `updated_at` bumped | | Pending manual execution |
| BE-26 | Order status | Non-admin cannot change order status | CUSTOMER JWT | 1. PUT `/api/orders/{id}/status` as CUSTOMER | 403 Forbidden | | Pending manual execution |
| BE-27 | Payments | Simulated payment capture succeeds instantly | CUSTOMER JWT, unpaid order exists | 1. POST `/api/payments` `{orderId, method:"CARD"}` | 201 Created, `status:"PAID"`, `paid_at` set, amount matches order total | | Pending manual execution |
| BE-28 | Payments | An order cannot be paid twice (1:1 enforced) | Order already has a PAID payment | 1. POST `/api/payments` again for the same orderId | Rejected (unique constraint / service-level check), no duplicate payment row | | Pending manual execution |
| BE-29 | Reports | `/admin/reports/sales?range=daily` aggregates correctly | Several orders placed today across statuses | 1. GET as ADMIN | 200 OK; totals match manual SUM over today's `orders`/`order_items` | | Pending manual execution |
| BE-30 | Reports | `/admin/reports/top-products?limit=5` ranks by quantity sold | Multiple products ordered at different quantities | 1. GET as ADMIN | 200 OK; results ordered descending by `SUM(quantity)`, capped at 5 | | Pending manual execution |
| BE-31 | Dashboard | `/admin/dashboard` returns today's gross sales, active order count, avg prep time | Mixed orders (some COMPLETED, some active) today | 1. GET as ADMIN | 200 OK; active count excludes COMPLETED/CANCELLED; figures match underlying data | | Pending manual execution |
| BE-32 | Security | JWT tampering is rejected | Valid JWT, then one character of the signature altered | 1. Call any protected endpoint with the tampered token | 401 Unauthorized (signature validation fails in `JwtService`) | | Pending manual execution |
| BE-33 | Security | Expired JWT is rejected | `JWT_EXPIRATION_MS` set very low for the test, token allowed to expire | 1. Call a protected endpoint after expiry | 401 Unauthorized | | Pending manual execution |
| BE-34 | CORS | Requests from a disallowed origin are blocked | `CORS_ALLOWED_ORIGINS` does not include `http://evil.example` | 1. Browser fetch from that origin | Preflight/response blocked by CORS policy | | Pending manual execution |

## Web app test cases (React)

| Test ID | Feature | Test Case | Precondition | Steps | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|---|
| WEB-01 | Register/Login | User can register and is redirected logged-in | Backend reachable at `VITE_API_URL` | 1. Go to `/auth`, fill register form, submit | Account created, JWT stored, redirected to home as CUSTOMER | | Pending manual execution |
| WEB-02 | Register/Login | Invalid login shows a clear error, not a raw error object | Backend reachable | 1. Submit wrong password on `AuthPage` | Human-readable error message shown via `formatApiError` | | Pending manual execution |
| WEB-03 | Guest browsing | Guest can browse the menu without logging in | Not logged in | 1. Visit `/menu` directly | Products render; no redirect to login | | Pending manual execution |
| WEB-04 | Guest restriction | Guest is blocked from checkout | Not logged in, items in cart | 1. Attempt to place an order | Redirected to `/auth` or blocked with a clear "please log in" prompt, no 401 leaking to the console as the only feedback | | Pending manual execution |
| WEB-05 | Cart | Adding/removing items updates cart totals live | Logged in, on `MenuPage` | 1. Add 2 items, change quantity, remove one | Cart badge and running subtotal update correctly at each step | | Pending manual execution |
| WEB-06 | Checkout | Placing an order shows the server-computed total, not a client guess | Logged in, cart has items | 1. Submit order on `CartOrdersPage` | Confirmation shows totals returned by the API response, matching backend calculation | | Pending manual execution |
| WEB-07 | Order tracking | Customer sees their order's status update after an admin changes it | Order placed, admin updates its status in another session | 1. Refresh/poll `CartOrdersPage`'s order view | New status (e.g. PREPARING) appears | | Pending manual execution |
| WEB-08 | Admin CRUD | Admin can create/edit/delete a category | Logged in as ADMIN | 1. On `AdminPage`, create a category, edit its name, delete it | Each action succeeds and list refreshes | | Pending manual execution |
| WEB-09 | Admin CRUD | Admin can create/edit a product and toggle availability | Logged in as ADMIN | 1. Create a product, edit its price, toggle SOLD_OUT | UI reflects each change; price shown as currency-formatted | | Pending manual execution |
| WEB-10 | Admin — tables | Admin can create a table and see its QR value | Logged in as ADMIN | 1. Create table #5 on `AdminPage` | Table appears with a unique QR value/code | | Pending manual execution |
| WEB-11 | Role restriction | Non-admin cannot see or reach the Admin page | Logged in as CUSTOMER | 1. Navigate directly to the admin route URL | Blocked/redirected — UI-level hiding of the nav link is not relied on as the actual boundary (server still enforces it) | | Pending manual execution |
| WEB-12 | Reports | Admin sees sales and top-products reports render as expected | Orders exist, logged in as ADMIN | 1. Open the reports section of `AdminPage` | Figures match backend `/admin/reports/*` responses | | Pending manual execution |
| WEB-13 | Responsive layout | Layout adapts from desktop to narrow/mobile-web width | none | 1. Resize viewport from 1440px down to 375px on Home, Menu, Cart, Admin pages | No horizontal scroll, nav collapses sensibly, touch targets remain usable | | Pending manual execution |
| WEB-14 | Accessibility | Keyboard-only navigation reaches all primary actions | none | 1. Tab through login form, menu "add to cart" buttons, checkout button | Visible focus states, logical tab order, no keyboard trap | | Pending manual execution |
| WEB-15 | Accessibility | Images and icon-only buttons have text alternatives | none | 1. Inspect product images and icon buttons (cart, nav) with a screen reader / devtools accessibility tree | `alt` text and `aria-label`s present and meaningful | | Pending manual execution |
| WEB-16 | Navigation | Header/Footer links route correctly across all pages | none | 1. Click each nav link from `Header.jsx` | Correct page loads, active state indicates current page | | Pending manual execution |
| WEB-17 | Error handling | API/network failure surfaces a user-facing message, not a blank screen | Backend stopped | 1. Attempt any API-backed action while backend is down | `ApiError`'s "Unable to reach the server" message shown, no unhandled crash | | Pending manual execution |
| WEB-18 | Validation | Product form rejects a negative price client-side and server-side | Logged in as ADMIN | 1. Enter `-5` as price and submit | Client shows validation error; if bypassed, server 400 with `fieldErrors` is surfaced | | Pending manual execution |

## Mobile app test cases (Flutter, Android)

| Test ID | Feature | Test Case | Precondition | Steps | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|---|
| MOB-01 | Login | User logs in and lands on Home with role-correct UI | Backend reachable at `API_BASE_URL` | 1. Enter credentials on `auth_screen.dart`, submit | JWT stored via `session_service.dart`; Home shown; Admin tab visible only for ADMIN | | Pending manual execution |
| MOB-02 | Guest browsing | Guest mode allows menu browsing without login | App launched fresh, "Continue as guest" chosen | 1. Browse `menu_screen.dart` as guest | Products load from public endpoint; cart/order actions prompt login | | Pending manual execution |
| MOB-03 | Table QR scan | Scanning a valid table QR resolves the table and opens the menu | Camera permission grantable, a printed/displayed table QR available | 1. Tap "Scan table QR", point camera at a valid code | `mobile_scanner` decodes it, `GET /tables/lookup` resolves, menu opens with table context set | | Pending manual execution |
| MOB-04 | Table QR scan | Manual table-number entry works as a fallback | Camera unavailable or user opts out | 1. Tap "Enter table number", type a valid number, submit | Same result as a successful scan | | Pending manual execution |
| MOB-05 | Table QR scan | Scanning/entering an invalid table code fails gracefully | none | 1. Enter a table number that doesn't exist | Clear "table not found" message, no crash | | Pending manual execution |
| MOB-06 | Cart | Adding items updates `cart_provider.dart` state and badge count | Logged in or guest | 1. Add 3 different products, adjust quantities | Cart screen and nav badge reflect correct totals | | Pending manual execution |
| MOB-07 | Order placement | Placing a dine-in order (post-QR-scan) carries the correct tableId | Table resolved via MOB-03 | 1. Add items, place order | `order_confirmation_screen.dart` shows the correct table number; order visible in `orders_screen.dart` | | Pending manual execution |
| MOB-08 | Order placement | Placing a pickup order (no table) succeeds with tableId null | Not scanned any table | 1. From Home, choose "Pickup", add items, place order | Order created without a table reference; pickup fee applied | | Pending manual execution |
| MOB-09 | Order tracking | Order status updates are reflected after admin changes them elsewhere | Order placed; admin updates status via web/mobile admin screen | 1. Return to `order_detail_screen.dart`, allow the poll interval to elapse or pull-to-refresh | Status badge updates (e.g. PENDING → PREPARING) | | Pending manual execution |
| MOB-10 | Offline mode | Menu falls back to cached data with a visible banner when offline | Menu previously loaded once online | 1. Enable airplane mode. 2. Reopen `menu_screen.dart` | `offline_banner.dart` shows "offline — showing cached data"; products still render from `sqflite` | | Pending manual execution |
| MOB-11 | Offline mode | Placing an order while offline is blocked with a clear message | Airplane mode on, cart has items | 1. Attempt to place order | Rejected client-side with an explanation (requires connectivity), no silent failure | | Pending manual execution |
| MOB-12 | Offline mode | Connectivity restoration clears the offline banner and refreshes live data | Was offline per MOB-10 | 1. Disable airplane mode, wait for `connectivity_provider.dart` to detect the change | Banner disappears; next fetch pulls live data | | Pending manual execution |
| MOB-13 | Theming | Light/dark mode toggle applies immediately and persists across restarts | none | 1. Toggle theme in Profile/settings. 2. Force-close and reopen the app | UI switches to Figma dark tokens instantly; theme choice persisted via `shared_preferences` (`theme_provider.dart`) and restored on relaunch | | Pending manual execution |
| MOB-14 | Orientation | Key screens remain usable in landscape | none | 1. Rotate device on Menu, Cart, Order Detail screens | Layout reflows without clipped content or unreachable controls | | Pending manual execution |
| MOB-15 | API failure handling | Backend downtime shows a friendly error, not a crash | Backend stopped | 1. Attempt to log in or load menu | `api_exception.dart`-driven message shown; app remains usable (falls back to cache where applicable) | | Pending manual execution |
| MOB-16 | Role restriction | Customer role cannot reach admin screens | Logged in as CUSTOMER | 1. Attempt to navigate to `admin_screen.dart` route directly | Route guarded/hidden; underlying API calls would 403 even if reached | | Pending manual execution |
| MOB-17 | Device feature — geolocation | Profile screen shows distance to the cafe after granting location permission | Location permission grantable | 1. Open Profile, grant permission when prompted | `location_service.dart`/`geolocator` returns a position; distance-to-cafe displays | | Pending manual execution |
| MOB-18 | Device feature — contacts | "Invite a friend" lets the user pick a contact after granting permission | Contacts permission grantable, ≥1 contact on device | 1. Tap "Invite a friend", grant permission, pick a contact | `flutter_contacts` picker opens; selected contact's name/number is used for the invite flow | | Pending manual execution |
| MOB-19 | Permissions | Denying camera permission is handled without crashing | none | 1. Deny camera permission when prompted for QR scan | Falls back to manual table-number entry with an explanatory message | | Pending manual execution |
| MOB-20 | Admin — mobile | Admin can view/generate a table's printable QR from the phone | Logged in as ADMIN | 1. Open `admin_scanner_screen.dart` / table admin view for a given table | QR renders via `qr_flutter`, matches the value stored server-side | | Pending manual execution |

**Total test cases: 34 (backend, BE-01…BE-34) + 18 (web, WEB-01…WEB-18) +
20 (mobile, MOB-01…MOB-20) = 72 test cases**, well above the assignment's
35-case minimum, spanning authentication, authorization-per-role,
validation, CRUD, multi-table order calculation, reporting aggregates,
browsing, cart/checkout, admin workflows, responsive/accessible layout,
navigation, error handling, QR scanning, offline mode, theming,
orientation, and device-permission handling.

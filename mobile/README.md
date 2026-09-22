# Caffora Mobile

A Flutter client for the Caffora coffee ordering app, built from the Figma mobile frames (`caffora-mobile-*-light`/`-dark`) and wired to the existing `caffora-backend` Spring Boot API. Same product, third client — after the React web app and the Spring Boot backend, this is the native mobile piece for the COMP70070/COMP70071 assignment.

## Setup

This is a plain Flutter project — nothing platform-specific has been pre-generated (no `android/`, `ios/`, etc.), because that scaffolding has to be produced by the Flutter tool itself for your machine/SDK version. To run it:

```bash
flutter create . --platforms=android,ios   # generates android/, ios/ around the existing lib/
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

`--dart-define=API_BASE_URL=...` points the app at your running `caffora-backend` (see that project's own README for `docker compose up`). The default in `lib/core/constants.dart` (`http://10.0.2.2:8080/api`) already targets an Android emulator's host loopback; override it for:

- **iOS simulator**: `http://localhost:8080/api`
- **Physical device**: `http://<your-machine's-LAN-IP>:8080/api` (device and backend must be on the same network)

> **Note on this deliverable:** this project was written in a sandboxed environment with no Flutter SDK installed and no network access to `pub.dev` / `storage.googleapis.com` (same egress policy that blocked Maven Central for the backend), so `flutter pub get` / `flutter analyze` / `flutter run` could not be executed here to produce a verified build. Every file was hand-reviewed for import correctness, enum/type consistency, provider wiring, route wiring, and package-API correctness against the exact versions pinned in `pubspec.yaml`. If `flutter pub get` or `flutter analyze` surfaces anything once you have normal internet access, paste the error back and I'll fix it directly.

## Architecture

```
lib/
  core/            app_router.dart (route table + role guards), constants.dart, theme/
  models/          plain Dart models mirroring the backend's JSON shapes
  services/        api_client.dart (http + JWT header) and one service per backend resource,
                    plus local_db_service.dart (sqflite offline cache), session_service.dart
                    (shared_preferences), connectivity_service.dart, location_service.dart,
                    contacts_service.dart
  providers/       ChangeNotifier state per feature (auth, theme, connectivity, products, cart,
                    orders, admin, table) — consumed via package:provider
  screens/         one folder per feature area (table/ holds the table-QR scan screen)
  widgets/         shared UI matching the Figma component patterns (bottom nav, cards, badges)
```

State flows the same way for every screen: a `Provider` calls a `Service`, a `Service` calls `ApiClient`, `ApiClient` calls the Spring Boot backend and translates non-2xx responses into `ApiException`/`NetworkUnavailableException`. On `NetworkUnavailableException`, `ProductProvider`/`OrderProvider` fall back to the sqflite cache (`LocalDbService`) so the Menu and Orders screens never go blank offline.

## Design fidelity

Colors, type scale, spacing and component structure were taken directly from the Figma file's mobile frames (light **and** dark), not guessed:

| Token | Light | Dark |
|---|---|---|
| Background | `#FAF6F0` | `#120A05` |
| Surface / card | `#FFFFFF` | `#1E140E` |
| Border | `#EAE3D9` | `#33251D` |
| Text primary | `#2E1E12` | `#F7EFE9` |
| Text secondary | `#8C7A6B` | `#B09F92` |
| Accent (brand) | `#C85C40` | `#D66C4D` |

Headings use **Outfit** (Bold/ExtraBold), body/UI text uses **Figtree** — both loaded via `google_fonts` (this needs normal internet on first run to fetch the font files; after that they're cached on-device).

## Mapping to the assignment brief

| Requirement | Where |
|---|---|
| 3 roles: Admin / Registered / Guest | `AuthProvider.status` (`guest`/`authenticated` + `isAdmin`); `AppRouter` guards Cart/Orders behind sign-in and Admin screens behind the ADMIN role |
| Login / register | `screens/auth/auth_screen.dart` |
| Admin-only CRUD | `screens/admin/admin_screen.dart` + `admin_product_form_screen.dart`, gated by `AuthProvider.isAdmin` |
| Registered-user-only parts | Cart & Orders routes redirect a guest to `/auth` (`AppRouter.guardAuthenticated`) |
| Guest general access | Home, Table Scan & Menu are open to everyone; `CafforaBottomNav` intercepts Cart/Orders taps for guests |
| Remote data store | Every screen talks to `caffora-backend` over HTTP/JSON — no fake/local-only data |
| Data-input screen | `admin_product_form_screen.dart` (structured form: name, description, price, category, image URL) and the auth form |
| Data-view screen | `menu_screen.dart`, `orders_screen.dart` |
| Cross-table calculation reflected in-app | `AdminProvider.loadAll()` → `GET /api/admin/dashboard` (a server-side join across orders/order_items/products) rendered as the 3 metric cards on the Admin screen |
| Update by one user reflected in another's view | Admin advances an order's status from the queue (`admin_screen.dart`); `OrderProvider` polls `GET /api/orders/my` every 8s so the customer's Orders screen picks up the change automatically |
| ≥4 well-designed screens, no Lorem ipsum | Splash, Auth, Home, Table Scan, Menu, Cart, Order Confirmation, Orders, Order Detail, Admin, Admin Categories, Admin Tables, Profile — all real Caffora copy |
| Light + dark mode | `core/theme/app_theme.dart`; toggle in Profile, persisted via `shared_preferences` |
| Responsive to orientation/size | Scroll views + `Expanded`/`Flexible` layouts throughout, no hardcoded screen-filling heights |
| Offline capability with alternative content | `LocalDbService` (sqflite) caches the last-fetched product catalog and orders; `ProductProvider`/`OrderProvider` fall back to it automatically, with an "offline — showing cached data" banner (matches the Figma orders-dark frame) |
| Device sensor feature | Geolocation (`geolocator`) — "distance to the Caffora counter" on Profile — **and** camera (`mobile_scanner`) for table-QR scanning (`screens/table/table_scan_screen.dart`), the primary dine-in ordering entry point |
| Table-QR dine-in ordering | Customer scans a table's QR (`cafe://table/{tableNumber}`) or types the number in manually; `TableService.lookupByCode` resolves it against `GET /api/tables/lookup`, `TableProvider` holds the selection, and `CartScreen` passes its `tableId` into `POST /api/orders` so the order is tied to that physical table. Admin prints each table's QR from `admin_tables_screen.dart` (`qr_flutter`) |
| Simulated payment | `PaymentService.recordPayment` (`POST /api/payments`) is called right after an order is placed; the result (always `PAID`, clearly labelled "simulated — no real charge") is shown on Order Confirmation and Order Detail |
| Explicit stored-contacts access | Profile → "Invite a friend" (`flutter_contacts`, real permission prompt + system contact list) |
| Input-source requirement | Satisfied multiple ways: user input (all forms), external API/JSON (the entire backend integration), local read/write (sqflite cache) |

## What's not included

Platform folders (`android/`, `ios/`) are generated by `flutter create`, not hand-written, since they're SDK/toolchain-specific. App icons and a couple of Figma-referenced food photos are left as network image URLs with a graceful fallback glyph when unreachable (`widgets/network_food_image.dart`) — swap in bundled assets under `assets/images/` (already wired into `pubspec.yaml`) whenever you have final production photography.

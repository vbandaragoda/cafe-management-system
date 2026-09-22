# Component Diagrams

This document breaks each of the three codebases into its internal layers /
modules. Package and folder names below match the real repository layout
under `backend/src/main/java/com/caffora/backend/`, `web/src/`, and
`mobile/lib/`. Where the authoritative spec calls for entities that are
being added as part of the in-progress work (`Category`, `Product`,
`CafeTable`, `Payment`, the `/admin/reports/*` endpoints), they are shown in
their target/final location, since that is what all three clients are
built against.

## Backend — Spring Boot layered architecture

```mermaid
flowchart TB
    subgraph config["config/"]
        SecurityConfig
        CorsProperties
        PricingProperties
        AdminSeedProperties
        DataSeeder
    end

    subgraph security["security/"]
        JwtAuthFilter["JwtAuthenticationFilter"]
        JwtService
        JwtProperties
        UserDetailsSvc["CustomUserDetailsService"]
        UserPrincipal
    end

    subgraph controller["controller/"]
        AuthController
        CategoryController
        ProductController
        TableController
        OrderController
        PaymentController
        AdminController
    end

    subgraph service["service/"]
        AuthService
        CategoryService
        ProductService
        TableService
        OrderService
        PaymentService
        AdminService["AdminService\n(dashboard + reports)"]
    end

    subgraph repository["repository/"]
        UserRepo["UserRepository"]
        CategoryRepo["CategoryRepository"]
        ProductRepo["ProductRepository"]
        TableRepo["CafeTableRepository"]
        OrderRepo["OrderRepository"]
        OrderItemRepo["OrderItemRepository"]
        PaymentRepo["PaymentRepository"]
    end

    subgraph model["model/ (JPA entities)"]
        User
        Category
        Product
        CafeTable
        Order
        OrderItem
        Payment
        Role["Role (enum)"]
        ProductStatus["ProductStatus (enum)"]
        OrderStatus["OrderStatus (enum)"]
        PaymentMethod["PaymentMethod (enum)"]
        PaymentStatus["PaymentStatus (enum)"]
    end

    subgraph dto["dto/ (request/response records)"]
        AuthDtos["auth/*"]
        ProductDtos["product/*"]
        OrderDtos["order/*"]
        PaymentDtos["payment/*"]
        AdminDtos["admin/DashboardResponse, SalesReportResponse, TopProductResponse"]
    end

    subgraph exception["exception/"]
        GlobalExceptionHandler
        ResourceNotFoundException
        BadRequestException
        EmailAlreadyInUseException
    end

    controller --> service
    controller -. "reads/writes" .-> dto
    service --> repository
    service -. "maps to/from" .-> dto
    repository --> model
    security --> controller
    config --> security
    controller --> exception
```

**Layer responsibilities:**

- **`config/`** — Spring `@Configuration` classes: `SecurityConfig` wires the
  JWT filter chain and per-route role rules; `CorsProperties` binds
  `CORS_ALLOWED_ORIGINS`; `PricingProperties` binds tax rate and pickup fee;
  `DataSeeder` creates the bootstrap `ADMIN_SEED_EMAIL` account on first
  startup if it does not already exist.
- **`security/`** — stateless JWT machinery: `JwtService` issues/validates
  tokens (jjwt 0.12), `JwtAuthenticationFilter` runs once per request to
  populate the Spring Security context from the `Authorization: Bearer`
  header, `CustomUserDetailsService` + `UserPrincipal` bridge the `User`
  entity into Spring Security's model.
- **`controller/`** — thin `@RestController` classes: parse/validate the
  HTTP request (via `@Valid` DTOs), delegate to a service, map the result to
  a response DTO. No business logic lives here.
- **`service/`** — business logic: password hashing and JWT issuance
  (`AuthService`), catalogue CRUD (`CategoryService`, `ProductService`),
  table/QR lookup (`TableService`), order placement and status transitions
  including **server-side total recomputation** (`OrderService`), simulated
  payment capture (`PaymentService`), and the aggregate queries behind the
  dashboard and reports (`AdminService`).
- **`repository/`** — Spring Data JPA interfaces over each entity; carry the
  `@Query`/derived-query methods used for the GROUP BY reporting queries
  (e.g. `OrderItemRepository.sumQuantityAndRevenueByProduct(...)`).
- **`model/`** — JPA `@Entity` classes mapping 1:1 to the seven database
  tables in `docs/database/erd.md`, plus enums for `Role`, `ProductStatus`,
  `OrderStatus`, `PaymentMethod`, `PaymentStatus`.
- **`dto/`** — request/response shapes exposed over HTTP; entities are never
  serialized directly, so internal fields (e.g. password hash) can never
  leak and API shape can evolve independently of the schema.
- **`exception/`** — `GlobalExceptionHandler` (`@RestControllerAdvice`)
  converts domain exceptions and validation failures into a consistent JSON
  error body (`status`, `message`, `fieldErrors`, `timestamp`, `path`) that
  every client (web `ApiError`, mobile `ApiException`) parses uniformly.

## Web — React component structure

```mermaid
flowchart TB
    subgraph entry["Entry"]
        main["main.jsx"]
        App["App.jsx\n(React Router routes)"]
    end

    subgraph context["context/"]
        AppContext["AppContext.jsx\nauth state, JWT, cart, theme"]
    end

    subgraph api["api/ — REST client layer"]
        client["client.js\napiRequest(), ApiError, VITE_API_URL"]
        authApi["auth.js"]
        categoriesApi["categories.js"]
        productsApi["products.js"]
        ordersApi["orders.js"]
        paymentsApi["payments.js"]
        adminApi["admin.js"]
    end

    subgraph pages["pages/ — routed screens"]
        HomePage
        AuthPage["AuthPage (login/register)"]
        MenuPage
        CartOrdersPage["CartOrdersPage (cart, checkout, order tracking)"]
        AdminPage["AdminPage (dashboard, catalogue CRUD, tables, reports, order mgmt)"]
    end

    subgraph components["components/ — shared UI"]
        Header
        Footer
    end

    main --> App
    App --> context
    App --> pages
    pages --> components
    pages --> api
    api --> client
    context -. "token, role" .-> api
```

- **`api/`** is the only layer that knows about HTTP; every page calls a
  typed function (e.g. `products.list({ categoryId, search })`) instead of
  calling `fetch` directly, so the backend contract is centralized.
- **`context/AppContext.jsx`** holds the JWT, current user/role, cart
  contents, and light/dark theme, and is what makes role-based UI (e.g.
  hiding the Admin nav link from non-admins) and the shared cart state
  possible across pages — noting again that this is a UX convenience only;
  the real authorization boundary is server-side.
- **`pages/AdminPage.jsx`** is the admin console: category/product CRUD,
  table management (QR values), live order queue with status updates, and
  the sales/top-products reports.

## Mobile — Flutter structure

```mermaid
flowchart TB
    subgraph entry["Entry"]
        mainDart["main.dart"]
        router["core/app_router.dart"]
        theme["core/theme/ (app_colors.dart, app_theme.dart)"]
    end

    subgraph providers["providers/ — ChangeNotifier state"]
        authP["auth_provider.dart"]
        menuP["menu_provider.dart"]
        cartP["cart_provider.dart"]
        orderP["order_provider.dart"]
        adminP["admin_provider.dart"]
        connP["connectivity_provider.dart"]
        themeP["theme_provider.dart"]
    end

    subgraph services["services/ — API + device access"]
        apiClient["api_client.dart\nhttp + JWT header"]
        authSvc["auth_service.dart"]
        menuSvc["menu_service.dart"]
        orderSvc["order_service.dart"]
        adminSvc["admin_service.dart"]
        localDb["local_db_service.dart\nsqflite cache"]
        connSvc["connectivity_service.dart\nconnectivity_plus"]
        locationSvc["location_service.dart\ngeolocator"]
        contactsSvc["contacts_service.dart\nflutter_contacts"]
        sessionSvc["session_service.dart\nshared_preferences"]
    end

    subgraph models["models/"]
        userM["user.dart"]
        menuItemM["menu_item.dart (Product)"]
        cartItemM["cart_item.dart"]
        orderM["order.dart"]
        dashboardM["admin_dashboard.dart"]
    end

    subgraph screens["screens/ — UI, grouped by feature"]
        splash["splash/"]
        auth["auth/"]
        home["home/"]
        menu["menu/ + table QR scan entry"]
        cart["cart/"]
        orders["orders/ (list, detail, confirmation)"]
        profile["profile/ (geolocation, invite-a-friend)"]
        admin["admin/ (screen, menu form, table QR scanner)"]
    end

    subgraph widgets["widgets/ — shared components"]
        bottomNav["caffora_bottom_nav.dart"]
        offlineBanner["offline_banner.dart"]
        cards["menu_item_card.dart, order_card.dart, status_badge.dart, cart_item_row.dart"]
        netImage["network_food_image.dart\ncached_network_image"]
    end

    mainDart --> router
    router --> screens
    screens --> providers
    providers --> services
    services --> models
    services --> apiClient
    screens --> widgets
    widgets -. "reads" .-> connP
```

- **`providers/`** (using the `provider` package) hold UI-facing state and
  are the only layer screens talk to directly — mirroring the React app's
  `AppContext`, but split per concern (auth, menu, cart, orders, admin,
  connectivity, theme) rather than one monolithic context.
- **`services/`** do the actual work: `api_client.dart` is the shared HTTP
  wrapper (attaches the JWT, parses the backend's error JSON into
  `ApiException`, mirroring `web/src/api/client.js`'s `ApiError`);
  `local_db_service.dart` is the `sqflite` offline cache for menu/orders;
  `connectivity_service.dart`, `location_service.dart`, and
  `contacts_service.dart` wrap the three device-hardware features
  (network status, GPS, contacts) behind a testable interface.
- **`screens/admin/`** exists so the same admin role can manage the cafe
  from a phone — `admin_scanner_screen.dart` renders each table's QR (via
  `qr_flutter`) for printing, mirroring the equivalent CRUD available on
  the web `AdminPage`.

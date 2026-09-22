# Design Progression — Caffora

## Note on user testing

**Formal user testing was not conducted as part of this documentation
pass.** The design rationale below explains the reasoning behind choices
already made in the real Figma file and the implementation, not the
outcome of usability studies. If the team performs real user testing
(moderated walkthroughs, think-aloud sessions, a usability questionnaire)
before submission, its findings should be added to this document as a new
section — this is flagged as a genuine gap, not glossed over.

## 1. Initial concept

Caffora started from two combined needs identified in the brief: a
**customer-facing ordering experience** (browse a menu, order, pay, track
status) and an **admin-facing management experience** (control the
catalogue, see and progress orders, understand sales) — deliberately built
as one system with two audiences rather than two separate products,
because both sides operate on the exact same underlying data (see
`docs/architecture/system-context.md` for why one shared backend matters
here specifically).

## 2. Wireframe / prototype stage

Before high-fidelity visuals, the core screen inventory and flow were
blocked out at a structural level:

- Guest/auth entry → Home → Menu (browse/filter/search) → Product detail →
  Cart → Checkout/payment → Order confirmation → Order tracking.
- A parallel Admin flow: Admin login → Dashboard → Catalogue (categories +
  products) CRUD → Tables (create + view QR) → Order queue (status
  transitions) → Reports.
- On mobile specifically, an additional entry point was designed in from
  the start: **scan table QR → resolves table → menu, pre-attached to that
  table** — this was treated as a primary navigation path, not an
  afterthought bolted onto a generic menu screen, because it is how a
  real dine-in customer is expected to begin their session.

This stage established the low-fidelity layout and navigation structure
that the high-fidelity Figma frames and the actual `mobile/lib/screens/`
and `web/src/pages/` folder structures both follow directly.

## 3. High-fidelity Figma design

The real Figma file defines both **light and dark** themes across
**desktop (web)** and **mobile** frames. Screens designed at high fidelity
include:

| Screen | Web frame | Mobile frame |
|---|---|---|
| Home / landing | Yes | Yes |
| Auth (login/register) | Yes | Yes |
| Menu (browse, filter by category, search) | Yes | Yes |
| Product detail / add-to-cart | Yes | Yes |
| Cart / checkout / simulated payment | Yes | Yes |
| Order confirmation / order tracking | Yes | Yes |
| Table QR scan | — (web has no camera) | Yes, mobile-only |
| Profile (geolocation, invite-a-friend) | — | Yes, mobile-only |
| Admin dashboard | Yes | Yes (condensed) |
| Admin catalogue CRUD (categories, products) | Yes | Yes |
| Admin tables + QR display | Yes | Yes |
| Admin order queue + status update | Yes | Yes |
| Admin reports (sales, top products) | Yes | Condensed/summary view |

Both **mobile-light** and **mobile-dark** variants exist for every mobile
frame, matching the token sets implemented in
`mobile/lib/core/theme/app_colors.dart` (see below) — dark mode is a
first-class design target, not a CSS filter applied after the fact.

### Design tokens (from the real Figma file)

| Token | Light | Dark |
|---|---|---|
| Accent (rust) | `#C85C40` | `#D66C4D` |
| Background | cream `#FAF6F0` | `#120A05` |
| Surface | white/cream-adjacent | `#1E140E` |
| Border | latte `#EAE3D9` | `#33251D` |
| Text primary | espresso `#2E1E12` | `#F7EFE9` |
| Text secondary | mocha `#8C7A6B` | `#B09F92` |

Typography: **Outfit** (Bold/ExtraBold) for headings, **Figtree** for
body/UI text — both loaded via Google Fonts (`google_fonts` on mobile;
a `<link>`/`@font-face` equivalent on web), reinforcing a warm, editorial,
"artisanal coffee shop" feel rather than a generic corporate SaaS look.

## 4. Reasoning behind key UI/UX choices

- **Warm rust/espresso palette.** A cafe brand benefits from a palette that
  reads as warm and food-adjacent rather than cold/corporate — rust and
  espresso browns against a cream background evoke coffee, roasted beans,
  and a physical cafe interior, which a generic blue/gray SaaS palette
  would not. The dark theme keeps the same hue relationships (rust accent
  against near-black espresso) rather than inverting to a cold dark-blue
  theme, so the brand stays recognizable in both modes.
- **Bottom-tab mobile navigation.** The mobile app uses a bottom tab bar
  (`caffora_bottom_nav.dart`) rather than a hamburger/drawer menu, because
  the primary mobile use case is **one-handed dine-in use**: a customer
  seated at a table, phone in one hand, needs to reach Home/Menu/Cart/
  Orders/Profile with a thumb, not open a drawer that requires a second
  hand or a stretch to the top-left corner.
- **Table-QR as the primary mobile entry point.** Rather than treating QR
  scanning as a secondary/hidden feature, it is surfaced prominently from
  Home, because it is the fastest path from "just sat down" to "menu
  open, table already linked" — collapsing what would otherwise be several
  steps (open app → search for cafe → find "which table am I at" input)
  into one scan. The manual table-number fallback exists specifically so
  this design choice doesn't strand a customer whose camera/permissions
  aren't cooperating.
- **Snapshot-based order history (design consequence of a data decision).**
  Because `order_items` stores a name/price snapshot (see
  `docs/database/erd.md`), the Order Detail screen can always show exactly
  what a customer was charged at the time, even after a later menu price
  change — the UI never needs a disclaimer like "price may have changed
  since this order."
- **Status badges over free-text status.** Order status is shown as a
  small colored badge (`status_badge.dart` on mobile; equivalent styling
  on web) driven directly by the `orders.status` enum, so status is
  scannable at a glance in a busy order queue rather than requiring the
  admin to read a sentence per row.
- **Offline banner as a distinct, persistent UI element** rather than a
  toast/snackbar that disappears — because offline state can last for the
  whole time a customer is browsing, a transient notification would be
  missed; a persistent banner (`offline_banner.dart`) keeps the user aware
  that what they're seeing is cached, for as long as it's true.

## 5. From design to implementation — mapping

Every high-fidelity frame above maps to a real, working screen:

- Web: `web/src/pages/HomePage.jsx`, `AuthPage.jsx`, `MenuPage.jsx`,
  `CartOrdersPage.jsx`, `AdminPage.jsx`, plus shared `Header.jsx`/
  `Footer.jsx` matching the Figma nav/footer frames.
- Mobile: `mobile/lib/screens/{splash,auth,home,menu,cart,orders,profile,
  admin}/` — one folder per major Figma flow, plus `widgets/` for the
  cross-screen components (`menu_item_card.dart`, `order_card.dart`,
  `status_badge.dart`, `offline_banner.dart`) that appear repeatedly across
  Figma frames as reusable components.

This 1:1 mapping from Figma frame → implemented screen is also the basis
for the "≥4 well-designed screens" and "accessibility/W3C-readiness"
requirement evidence in `docs/requirement-traceability-matrix.md`.

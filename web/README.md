# Caffora — coffee ordering app

Generated from the Figma file **"Caffora - Assignment"** (desktop, light theme) using React + Vite + Tailwind CSS.

## Screens included

- **Home** (`/`) — marketing landing page, hero, benefits, featured menu preview
- **Auth** (`/auth`) — sign in / create account, guest checkout option
- **Menu** (`/menu`) — full menu with search, category filters, add to cart
- **Cart & Orders** (`/cart`) — active cart with quantity controls, order summary, checkout, live order-status tracker, order history tab
- **Admin** (`/admin`, also linked from the footer as "Cafe Admin Portal") — dashboard metrics, menu management table (toggle availability / delete / add), live kitchen order queue with cycling status

## Getting started

```bash
npm install
npm run dev      # start local dev server
npm run build    # production build to dist/
```

## What's wired up (not just static markup)

- Global app state (`src/context/AppContext.jsx`) for guest/auth session, cart contents, totals (subtotal + pickup fee + 8% tax), and the live order tracker.
- Cart and session persist to `localStorage` so a page refresh doesn't lose your bag.
- Menu search + category filtering, "Sold Out" items are disabled.
- Guest users are prompted to sign in before checkout; guest checkout banner appears on the menu page.
- Admin menu table: toggle Available/Sold Out, delete items, add a placeholder item. Kitchen queue ticket status cycles Pending → Preparing → Ready → Completed on click.

## Important: image assets are temporary

The images and icons currently reference Figma's temporary export URLs
(`https://www.figma.com/api/mcp/asset/...`), which **expire after about 7 days**.
They're centralized in `src/assets/images.js` and `src/data/menuData.js` (menu item photos).

Before shipping this to production:
1. Download each image (open the URL, save the file).
2. Put them in `src/assets/` (or wherever you keep static assets).
3. Update the URL strings in `src/assets/images.js` / `src/data/menuData.js` to point at your local/CDN copies.

This project's sandbox couldn't reach `figma.com` to pre-download them for you (network policy), so this step is left for you to do locally — it's a find-and-replace, not a rebuild.

## Design tokens

Pulled from the Figma file's raw hex values (no published Figma variables existed) and mapped to Tailwind theme colors in `tailwind.config.js`: `rust` (#c85c40, primary/CTA), `espresso` (#2e1e12), `cream` (#faf6f0, page bg), `latte` (#eae3d9, borders), `mocha` (#8c7a6b, muted text). Fonts: Outfit (headings) + Figtree (body), loaded from Google Fonts.

# Intellectual Property Policy — Caffora

This document distinguishes between **planned protection** (what a
production version of this policy would eventually cover) and **completed
protection** (what has actually been done as of this coursework
submission). As a coursework project, **nothing described below has
actually been registered, trademarked, or filed** — this is a policy
statement, not a legal filing.

## Source code ownership

The backend (`backend/`), web app (`web/`), and mobile app (`mobile/`) are
all team-authored code written specifically for this coursework. The
default position taken here is that **copyright in team-authored work
vests in the student authors**, consistent with how most university group
coursework treats originally created work — but this is a **reasonable
default assumption for the purposes of this document, not a legal
certainty**: the team should check the actual IP/assessment policy of
their specific institution and module (COMP70070/COMP70071), since some
institutions retain rights to coursework submissions or apply different
rules for work built on institution-provided starting material. Where any
part of the codebase originated from lecture/lab scaffolding provided by
the module, that provenance should be credited and is not claimed as
original student work.

**Completed:** the code as it stands is original, team-written work (no
copied proprietary codebase). **Planned, not completed:** no formal
copyright registration exists or is needed for coursework — copyright in
original work arises automatically on creation in most jurisdictions and
registration is not a normal step for a project at this stage.

## Design ownership (Figma)

The Figma file backing both the web and mobile UI (light/dark, desktop and
mobile frames — see `docs/design/design-progression.md`) is treated as
team-originated design work. Any assets pulled from the Figma Community
(icon sets, illustration packs, plugin-generated assets) should be checked
individually for their license terms before the project is submitted or
published — Figma Community assets carry a range of licenses (some MIT/CC,
some more restrictive "use within Figma only" terms), and this document
does not assert that such a check has been performed; it flags it as
something the team must do, not something already verified.

**Completed:** the overall visual design (palette, layout, screen
composition) is the team's own work. **Planned, not completed:** a
line-by-line audit of every icon/asset source and its license.

## Open-source license compliance — third-party packages actually used

Every package below is genuinely integrated into one of the three
codebases (see `backend/pom.xml`, `web/package.json`,
`mobile/pubspec.yaml`), not a hypothetical dependency list. All are
open-source with permissive, commercially-usable licenses:

### Backend (Java/Maven)

| Package | License family | Notes |
|---|---|---|
| Spring Boot / Spring Framework / Spring Security / Spring Data JPA | Apache License 2.0 | Apache-2.0-family; permissive, allows commercial and derivative use |
| jjwt (io.jsonwebtoken, 0.12.x) | Apache License 2.0 | JWT issuing/validation |
| MySQL Connector/J | GPL v2 with the FOSS/commercial exception used by MySQL's driver | Standard for connecting to MySQL from an open-source app; team should confirm the exact connector artifact's license terms in `pom.xml` before any commercial redistribution |
| Hibernate (via Spring Data JPA) | LGPL v2.1 | Standard, widely used under LGPL terms |

### Web (npm)

| Package | License | Notes |
|---|---|---|
| react, react-dom | MIT | |
| react-router-dom | MIT | |
| vite, @vitejs/plugin-react | MIT | |
| tailwindcss, postcss, autoprefixer | MIT | |

### Mobile (pub.dev, from `mobile/pubspec.yaml`)

| Package | License | Used for |
|---|---|---|
| provider | MIT | State management |
| http | BSD-3-Clause | REST client |
| sqflite, path, path_provider | MIT/BSD-style | Offline local database cache |
| shared_preferences | BSD-3-Clause | Theme + session persistence |
| connectivity_plus | BSD-3-Clause | Offline/online detection |
| geolocator | MIT | Distance-to-cafe device feature |
| qr_flutter | BSD-3-Clause | Admin QR code rendering for tables |
| mobile_scanner | Apache License 2.0 | Camera-based QR scanning |
| flutter_contacts | MIT | Invite-a-friend contact picker |
| permission_handler | MIT | Runtime permission prompts |
| google_fonts | BSD-3-Clause | Outfit/Figtree typography loading |
| intl | BSD-3-Clause | Date/time formatting |
| cached_network_image | MIT | Product image caching with offline fallback |

All of the above are open-source, MIT/BSD/Apache-2.0-style permissive
licenses that allow use in a project like this without royalty and without
requiring Caffora's own code to be open-sourced in turn (unlike a
copyleft license such as GPL). **This table reflects what was actually
integrated during development, not a formal legal audit** — the team
should re-verify current license terms for each package (via `pom.xml`,
`package.json`, and `pubspec.yaml`/`pubspec.lock`) before submission, since
license terms and even the specific transitive dependencies pulled in can
change between versions.

### Fonts

**Outfit** and **Figtree** (used for headings and body/UI text
respectively, per the Figma design tokens) are Google Fonts, distributed
under the **SIL Open Font License (OFL) 1.1** — free to use, embed, and
redistribute, including in commercial products, without royalty.

## Planned vs completed protection — summary

| Item | Planned | Completed |
|---|---|---|
| Copyright in source code | N/A — arises automatically | Yes, by virtue of original authorship (see caveat above re: institutional policy) |
| Trademark on "Caffora" name/logo | Not planned for coursework; would require a real registration process if ever commercialized | Not done — no trademark filed |
| Figma asset license audit | Should be done before any real-world reuse/publication | Not done as part of this documentation pass |
| Open-source license compliance check | Should be re-verified against actual lockfiles before submission | Table above compiled from what is genuinely integrated, not independently legally audited |
| Formal IP registration of any kind | None planned — this is a coursework project | None completed |

In short: Caffora's code and design are genuinely original team work with
a reasonable, standard open-source dependency footprint, but **no IP
protection has been formally registered or filed**, and the license/asset
checks above are flagged as team follow-up items rather than claimed as
already verified.

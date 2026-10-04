# Design: Landing page redesign + live product showcase

## Context

The landing page is currently one hand-authored static HTML file with inline `<style>`, no backend calls, and pricing numbers that were never wired to the real catalog. This change turns it into a small but real site with one dynamic section, without introducing a build pipeline or a new backend service. It touches three codebases (a new static site, `arunika-backend`, `arunika-backoffice`) that must stay decoupled: the landing page must degrade gracefully if the backend is slow, down, or the catalog is empty.

## Goals / Non-Goals

**Goals**
- Visually align the landing page with the app's design language, with more polish than the current draft.
- Show real, live membership/bundle data (name, description, price, image) sourced from the same catalog the app and backoffice already use.
- Let backoffice admins maintain the description/image that the landing page shows, without a separate CMS.

**Non-Goals**
- No purchase, cart, or payment flow on the web — explicitly out of scope per the request.
- No SSR, framework, or build step — this stays a static deliverable.
- No changes to how the app or backoffice compute pricing/entitlements; `description`/`image_url` are purely presentational additions to `premium_packages`.

## Decisions

### 1. Plain static site, no framework or build step
The project has an existing precedent for a single-file static deliverable (`reset_password.html` at the workspace root) that's hosted independently of the three app repos. `arunika-landing` follows the same pattern — `index.html` + `styles.css` + `script.js`, deployable to any static host (Vercel/Netlify/S3/GitHub Pages) with zero CI. A framework/build step would add tooling cost the request didn't ask for.

**Alternative considered**: putting the page inside `arunika-backend` as a Go-served static folder. Rejected — it would couple the marketing site's release cadence to backend deploys and pull unrelated static assets into the API service's image.

### 2. Data fetch: client-side `fetch()` against the existing public endpoint
`GET /premium/packs` already exists, is unauthenticated, and CORS already allows all origins (`AllowOrigins: []string{"*"}` in `routes/router.go`) — no backend routing or CORS change is needed. `script.js` defines one `const API_BASE_URL` constant at the top of the file (documented as "set this before deploying") and calls `fetch(`${API_BASE_URL}/premium/packs`)` on `DOMContentLoaded`.

### 3. Graceful degradation, always
Because the page is static and publicly reachable, the product section must never show a broken or blank state:
- **Fetch fails or times out** → section renders a static "Paket tersedia di aplikasi — buka aplikasi untuk melihat pilihan lengkap." fallback card instead of an empty section.
- **Empty array returned** → same fallback as above.
- **A package has `image_url = null`** → render a themed placeholder (reuse the existing gradient `.hero-image`/`.flashcard` treatment) instead of a broken `<img>`.
- **A package has `description = null`** → fall back to displaying `subtitle` (already required, short) so older packages created before this change still show something.

### 4. Card content mapping
Per package: image (or placeholder), `name`, `description` (or `subtitle` fallback), price formatted as `Rp {price_idr.toLocaleString('id-ID')}`, and a badge: `type === 'subscription'` → "Langganan", `type === 'content'` → "Paket Konten"; `is_best_value === true` adds a highlighted border + "Best Value" ribbon (mirrors the existing `border:2px solid var(--orange)` treatment already in the draft). Cards are sorted by the order the API returns them in (`sort_order ASC`, already enforced server-side) — no client-side re-sorting.

Every card ends with a neutral "Tersedia di aplikasi" label, not a buy button. The page's one purchase-adjacent action — the WhatsApp/Play Store CTA — stays at the bottom of the page, unchanged, and is about getting the app, not buying a specific package.

### 5. `description`/`image_url` are nullable, additive columns
Existing `premium_packages` rows predate these columns. Making them `NULL`-able TEXT columns means:
- The migration needs no backfill.
- `CreatePremiumPackInput`/`UpdatePremiumPackInput` treat both as optional (`*string`, no `binding:"required"`), so the existing backoffice create/edit flow keeps working even before an admin fills them in.
- `GetActivePacks`/`AdminListPacks` need no changes — they already `SELECT *`/return the full model, so the new fields flow through for free.

## Risks / Trade-offs

- **Stale `API_BASE_URL` at deploy time**: since there's no build-time env injection, whoever deploys the site must remember to point it at the right backend URL. Documented as a comment at the top of `script.js`; acceptable given the no-build-tooling constraint.
- **Public endpoint exposes package data to anyone**: already true today (`GET /premium/packs` has no auth) — this change doesn't widen that exposure, it just consumes it from a new client.

## Migration Plan

1. Ship backend migration `V49` + model/service/handler changes, deploy backend.
2. Ship backoffice form fields; admins backfill `description`/`image_url` for existing packages.
3. Ship `arunika-landing` pointed at the deployed backend's `API_BASE_URL`.

Steps are independently deployable and backward compatible at every stage (nullable columns, additive API fields, landing page tolerates nulls).

## Open Questions

None — resolved during proposal clarification: the site lives in its own repo/folder, and `description`/`image_url` are new backoffice-managed fields rather than reusing `subtitle` alone.

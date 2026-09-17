# Change: Redesign landing page and show live membership/bundle products

## Why

- `arunika_landing_page.html` is a rough draft: flat pricing cards with numbers that don't match what's actually sold in the app (`Rp 29.000` / `Rp 49.000` static AR objects vs. the real `premium_packages` catalog), a generic "Preorder Flashcard" CTA, and a visual style that only loosely echoes the app.
- A parent visiting the site has no way to see what memberships or content bundles are actually available in the app — what they contain, what they cost, what they look like — before deciding to download it.
- `premium_packages` (the backend's real product catalog, added by `add-monetization-entitlements`) has no image or long-form description today, only a short `subtitle`, so it can't be shown as an attractive product card anywhere yet.

## What Changes

- **New `arunika-landing` static site** (plain HTML/CSS/JS, no build tooling — same single-deliverable spirit as the existing `reset_password.html`), redesigned to match the app's visual theme (orange `#F59E0B` primary, cream `#FFFBF5` background, rounded 20-32px cards, Poppins) with more elegant spacing, imagery and motion than the current draft. Hero, app-preview and feature sections are restyled; content and Indonesian copy carry over.
- **New "Membership & Bundles" section** replaces the static pricing cards. It fetches the existing public `GET /premium/packs` endpoint at page load and renders one card per active package: sample image, name, description, formatted price (`Rp`), and a type/best-value badge. Cards are informational only — no price selection, cart or checkout — the page keeps its single Play Store / WhatsApp CTA. This satisfies "user can not buy product on the web."
- **Backend (`premium-package-cms`)**: `premium_packages` gains nullable `description` (TEXT) and `image_url` (TEXT) columns (migration `V49`), settable via the existing admin create/update endpoints and returned by the existing public and admin list endpoints — no new endpoints needed.
- **Backoffice (`premium-package-backoffice`)**: the package create/edit modal gains optional "Description" and "Image URL" fields so admins can populate what the landing page displays.

## Capabilities

### New Capabilities
- `landing-page`

### Modified Capabilities
- `premium-package-cms`
- `premium-package-backoffice`

## Impact

- New project: `arunika-landing/` (own git repo, sibling to `arunika_app`/`arunika-backend`/`arunika-backoffice`) — `index.html`, `styles.css`, `script.js`, `assets/`.
- Backend: `db/migrations/V49__add_description_image_to_premium_packages.sql`, `models/premium_package.go`, `services/premium_pack_service.go` (`CreatePremiumPackInput`, `UpdatePremiumPackInput`), `handlers/premium_pack_handler_test.go`, `services/premium_pack_service_test.go`.
- Backoffice: `src/pages/packages/PremiumPackagesPage.tsx`, `src/api/admin.ts`, `src/test/pages/PremiumPackagesPage.test.tsx`.
- No changes to `arunika_app` (mobile app) or to the payment/checkout flow — the landing page is read-only and unauthenticated, exactly like the `GET /premium/packs` endpoint it calls.

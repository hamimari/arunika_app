# Tasks: Redesign landing page and show live membership/bundle products

## 1. Backend — premium_packages description & image fields
- [x] 1.1 Add migration `db/migrations/V49__add_description_image_to_premium_packages.sql`: nullable `description TEXT`, nullable `image_url TEXT` on `premium_packages`
- [x] 1.2 Add `Description *string` and `ImageURL *string` to `models.PremiumPackage` (json `description`, `image_url`)
- [x] 1.3 Add optional `Description *string` / `ImageURL *string` to `CreatePremiumPackInput` and `UpdatePremiumPackInput` in `services/premium_pack_service.go`; wire into `CreatePack`/`UpdatePack`
- [x] 1.4 Update `handlers/premium_pack_handler_test.go` and `services/premium_pack_service_test.go` fixtures/columns for the new fields (also fixed `entitlement_service_test.go`, `payment_service_test.go`, `order_service_test.go`, which share the same `premium_packages` row fixtures)
- [x] 1.5 Run `go build ./...` and `go test ./...`

## 2. Backoffice — package Description & Image URL fields
- [x] 2.1 Add `description`/`image_url` to `PremiumPackage` and `PremiumPackageInput` types in `src/api/admin.ts`
- [x] 2.2 Add "Description" (`Input.TextArea`, optional) and "Image URL" (`Input`, optional) fields to the create/edit modal form in `src/pages/packages/PremiumPackagesPage.tsx`
- [x] 2.3 Update `src/test/pages/PremiumPackagesPage.test.tsx` for the new fields (create with/without them, edit pre-fill)
- [x] 2.4 Run `nvm use 22 && npx vitest run` and `npx tsc --noEmit`

## 3. New arunika-landing static site
- [x] 3.1 Scaffold `arunika-landing/` as its own git repo (sibling to the existing three projects): `index.html`, `styles.css`, `script.js`, `assets/`
- [x] 3.2 Redesign hero, app-preview and features sections to match the app's theme (color tokens, typography, spacing) with more elegant visual polish than the current draft; carry over existing Indonesian copy
- [x] 3.3 Replace the static "Pilihan Paket" pricing section with a "Membership & Bundles" section that fetches `GET {API_BASE_URL}/premium/packs` on `DOMContentLoaded` and renders one card per package (image, name, description, formatted price, type/best-value badge), per `design.md`
- [x] 3.4 Implement the empty-list / fetch-failure fallback state and the missing-image placeholder
- [x] 3.5 Confirm no card has a buy/checkout control; keep the single Play Store / WhatsApp CTA at the bottom of the page
- [x] 3.6 Manual QA: load the page against a local backend with a mix of packages (with/without image or description, best-value, both types) and against a backend returning an empty/failed response; check layout at ~360px and desktop widths (verified via a temporary mock API + static server in Chrome — real image, missing image/description fallback, subscription badge, best-value ribbon, empty-list fallback, 500-error fallback, and mobile/desktop stacking all confirmed with no console errors)

## 4. Validation
- [x] 4.1 `openspec validate add-landing-page-product-showcase --strict`

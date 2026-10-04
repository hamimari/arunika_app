## 1. Backend (`arunika-backend`)
- [x] 1.1 Migration: `ALTER TABLE ar_cards ADD COLUMN is_free BOOLEAN NOT NULL DEFAULT false` (shipped as `V61`; `V60` belongs to `add-uu-pdp-parental-consent`)
- [x] 1.2 Add `IsFree` to `models.ArCards`. Short-circuit `ArService.applyUnlocked` on `IsFree` (unlocked, no product/price)
- [x] 1.3 Accept `is_free` on admin AR card create, and add `PATCH .../ar-cards/:id/free` and `.../fairy-tales/:id/free` (update never writes the flag)
- [x] 1.4 Add the computed `access` field (`FREE` / `FREE_NO_PRODUCT` / `PAID` / `PAID_INACTIVE`) to the admin AR card and fairy-tale list/detail responses, and `content_is_free` to the admin products list
- [x] 1.5 Reject single-product orders (Midtrans product create, Play product create) when the linked content is free
- [x] 1.6 Update `openapi.yaml` and the app's `test/contract/openapi.yaml`
- [x] 1.7 Unit tests: `applyUnlocked` with `is_free` + product; `access` computation for all four states; free-content order rejected

## 2. Backoffice (`arunika-backoffice`)
- [x] 2.1 `api/admin.ts`: add `is_free` and `access` to the AR card and fairy-tale types, and `content_is_free` to products
- [x] 2.2 `ArCardsPage.tsx`: Access field (Free/Premium, default Free) in create/edit, Access column, and a "Make free" / "Make premium" row action
- [x] 2.3 `FairyTalesPage.tsx`: relabel the existing `is_free` field to Access (default Free), use the `access` column, and add the same row action
- [x] 2.4 `ProductsPage.tsx`: "Free override" tag for products whose content is free
- [x] 2.5 Packages "Manage Items": warning when the selected product's content is free
- [x] 2.6 Unit tests (Vitest) for the Access column rendering and the toggle mutation. Add an e2e flow: make a paid AR card free, then check the public `/ar/cards` shows `is_unlocked: true`

## 3. Validation
- [x] 3.1 `openspec validate add-free-content-toggle --strict`
- [x] 3.2 Backend `go test ./...` and backoffice `npm test`
- [ ] 3.3 Manual: flip a paid AR card and a paid dongeng to free in the backoffice, then confirm they unlock in the Flutter app for a user with no entitlement (the browser e2e already checks the public API side)

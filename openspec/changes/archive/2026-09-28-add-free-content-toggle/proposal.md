# Change: Let admins create free content and make paid content free

## Why
Admins want to publish free AR cards and dongeng, and to turn an existing paid item free, for example as a promotion or a sample. Today that is only implicit or impossible:
- A piece of content is free only if it has **no linked product**, and the backoffice never shows this.
- Dongeng has an `is_free` flag. AR cards don't.
- A paid item can't be made free by deleting its product once it has been sold or bundled. Orders, entitlements and package items all reference the product (FK RESTRICT/NO ACTION). Deleting it would also lose the price and the Play SKU.

## What Changes
- **Backend:** add `ar_cards.is_free BOOLEAN NOT NULL DEFAULT false`, mirroring `dongengs.is_free`. Access resolution treats content as free when it is flagged `is_free` **or** has no linked product. The product, orders, entitlements and package items stay untouched, so the change can be reversed by clearing the flag.
- **Backend:** the admin AR card create and update endpoints accept `is_free`. The admin content lists for AR cards and dongeng return a computed `access` value: `FREE` (flag set), `PAID` (active product), `PAID_INACTIVE` (product withdrawn from sale) or `FREE_NO_PRODUCT` (no product).
- **Backend:** single-product order creation (Midtrans and Google Play) rejects products whose content is flagged free.
- **Backoffice:** the AR card and dongeng forms get an **Access** field (Free / Premium) that defaults to Free on create. The lists show an Access column and a one-click "Make free" / "Make premium" action. The Products page tags products whose content is free ("Free override"). The package item picker warns when a free item is added to a bundle.
- **App:** no change. Free content already comes back as `is_unlocked = true` with no product, so the lock and buy UI disappears.

## Impact
- Affected specs:
  - `user-entitlements`: access resolution is modified.
  - `monetization-catalog`: adds an explicit free flag.
  - `monetization-orders-payments`: rejects orders for free content.
  - `free-content-backoffice`: new capability.
- Affected code:
  - `arunika-backend`: new migration `V61__add_is_free_to_ar_cards.sql` (numbered after V60 from `add-uu-pdp-parental-consent`; use V60 if this ships first), `models/ar_cards.go`, `services/ar_service.go` (`applyUnlocked`), `services/admin_content_service.go`, `services/product_service.go` (`ListEnriched`), `handlers/payment_handler.go` (product order creation), and `openapi.yaml`.
  - `arunika-backoffice`: `src/pages/content/ArCardsPage.tsx`, `FairyTalesPage.tsx`, `src/pages/products/ProductsPage.tsx`, the packages "Manage Items" view, and `src/api/admin.ts`.
- Existing owners keep their entitlements. If an item is made premium again, previous buyers still have access.

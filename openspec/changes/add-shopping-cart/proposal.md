## Why
Every paid Kartu AR card and Dongeng is bought on its own today: one parental gate, one Google Play sheet and one wait per item. A parent who wants five cards repeats that flow five times. The PRD "Keranjang Belanja" (Oct 2, 2026) adds a per-account cart so several items are paid in one payment, and the RFC of the same date describes the server design. The "Kartu AR Redesign" canvas (pages 46-53) holds the screens: the card list with "Beli" + cart icon, Keranjang, empty state, "Ada perubahan", Ringkasan pembayaran, Berhasil, Dibatalkan and Sedang diproses.

Google Play Billing sells one registered product per purchase and has no cart. The PRD's decision is a *cart total product*: the server freezes the cart into an order, picks the consumable store product whose price equals the total (`arunika.cart.t<rupiah>`), the app buys that one product, and the server grants every item of the order in one transaction.

## What Changes
- **Backend (`arunika-backend`)**
  - New tables `cart_items`, `order_items`, `store_products`. Extend `orders` with `is_cart`, `charge_idr`, `subtotal_idr`, `price_locked_until`, `store_product_id`, `idempotency_key`, `granted_at` and `consumed_at`. Refunds reuse the existing entitlement revocation (`expires_at`).
  - New cart API (`GET/POST/DELETE /cart`, `/cart/items`) with the PRD rules: owned, free, not-for-sale and Premium-covered items are refused, with a 20-item and Rp 500.000 limit.
  - New `POST /orders` freezes a cart or an explicit item list into an order, re-checks every item, locks prices for 30 minutes, and answers `409 CART_CHANGED` with the new cart when anything moved. `POST /orders/:id/verify`, the Play RTDN handler and a retry worker all settle through the existing, idempotent Play verify path extended for cart orders. A refund revokes every item of the order.
  - `cmd/storeprices` tool creates the consumable Play products (Rp 1.000 to Rp 500.000 in Rp 1.000 steps) and fills `store_products`.
  - Item prices must be whole Rp 1.000, enforced by a DB `CHECK` and by the admin API.
- **Backoffice (`arunika-backoffice`)**: "Pesanan" list and detail with item lists and "Berikan ulang"; "Produk toko" page; the price field on Kartu AR and Dongeng accepts only whole Rp 1.000 and shows the Rp 500.000 maximum cart total.
- **App (`arunika_app`)**: "Beli" + cart icon on Kartu AR and Dongeng cards, a cart badge in both list headers, the Keranjang screen with undo, the checkout flow (parental gate, Ringkasan, Play sheet) and the Berhasil / Dibatalkan / Sedang diproses screens. The cart sits behind a remote feature flag.
- **BREAKING (API shape, additive for old clients)**: an order can now hold many items, so `orders.product_id`/`package_id` are no longer the only way to identify what was bought. Old app builds keep working because the existing `/payment/play/*` single-product routes stay.

## Scope decisions
- **Google Play only in this change.** The app has no App Store billing code today and Midtrans is off. The RFC's Apple parts (StoreKit flow, App Store Server Notifications V2, Apple price points, "Potongan keranjang") are deferred to a follow-up change. `store_products.store` and `orders.store` keep an enum so Apple can be added without a migration of meaning.
- **Item identity is `products.id`**, not the RFC's `(item_type, item_id)`. The repo already models a sellable as a `products` row linked to an `ar_cards` or `dongengs` row, and `user_entitlements` is keyed by `product_id`. Cart and order items use the same key.
- **"Promo" means the existing strike price.** Strike prices are display-only (the charged price is `products.price_idr`; the strike price is the crossed-out "normal" price). "Hemat promo" in the cart is the sum of strike minus price. The 30-minute price lock therefore protects against `price_idr` edits and promo end, not against a different charge.
- The PRD's `accounts`, `/v1/` paths and `entitlements` names map to the repo's `parents`, unversioned routes and `user_entitlements`.

## Impact
- Affected specs (new): `cart-api`, `cart-checkout-orders`, `cart-store-products`, `cart-app`, `cart-backoffice`.
- Affected specs (modified): `monetization-orders-payments`.
- Affected code:
  - `arunika-backend`: migration `V68__create_cart_and_cart_orders.sql`; `models/cart.go`; `services/cart_service.go`, `cart_checkout.go`, `cart_settlement.go`, changes to `payment_service.go`, `entitlement_service.go`, `order_service.go`, `product_service.go`, `google_play_verifier.go`; `handlers/cart_handler.go`, order/admin order/user handler additions; `routes/router.go`; `main.go` (worker); `cmd/storeprices/`; `openapi.yaml`; `tests/api/cart_test.go`.
  - `arunika-backoffice`: `src/pages/orders/OrdersPage.tsx`, new `src/pages/store-products/StoreProductsPage.tsx`, `src/utils/priceStep.ts`, `ProductsPage.tsx` price validation, `src/api/admin.ts`, nav and route.
  - `arunika_app`: new `lib/data/api/cart_api.dart`, `lib/data/models/cart.dart`, `lib/core/cart/*`, `lib/presentation/screens/cart/*`; changes to the Kartu AR list (`collection_screen.dart`), Dongeng list (`new_dongeng_list_screen.dart`), `billing_service.dart`, `google_play_billing_service.dart`, `app_router.dart`, `locator.dart`, `profile_loader.dart`, `main.dart` and the feature flags.
- Out of scope: Akses Premium in the cart, bundle discounts or vouchers, gifting, a web checkout, Apple IAP (deferred), the Creator Program screens in the same design PDF.
- Open questions are listed at the end of `design.md`. The two console checks (lowest IDR price Play accepts, and whether the Rp 1.000 floor is allowed) block the build of `cart-store-products` but not the rest.

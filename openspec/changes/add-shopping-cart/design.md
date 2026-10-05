## Context
Source documents: PRD and RFC "Keranjang Belanja" (Oct 2, 2026) and the Kartu AR Redesign canvas. The RFC was written against an assumed schema. This design maps it onto what the repo has on `belajar-angka`:

| RFC assumption | Repo reality |
| --- | --- |
| `accounts` | `parents` |
| `/v1/...` routes | unversioned routes (`/orders`, `/payment/play/*`) |
| `entitlements(item_type, item_id)` | `user_entitlements(user_id, product_id)`, `UNIQUE(user_id, product_id)`, `source_order_id` |
| item tables carry price/promo | `products(feature_id, price_idr, is_active, strike_*)` linked by `product_ar_cards` / `product_dongengs`; global strike rules in `strike_price_rules` |
| one new `orders` table | `orders` exists: one `product_id` xor `package_id`, `status` PENDING/PAID/FAILED/EXPIRED/REFUNDED, `provider`, `purchase_token`; `payments` and `order_refunds` hang off it |
| Apple + Google | Google Play only; Midtrans checkout disabled behind `alternative_billing` |
| per-item SKU | each product has `play_product_id`; `POST /payment/play/create-product` + `/play/verify` handle one item |

This answers the RFC's first open question: ownership today is `user_entitlements` and price/promo already sit on `products`.

## Goals / Non-Goals
- Goals: one gate and one payment for up to 20 items; never charge for owned/free items; grant everything or refund; reuse existing order, refund and entitlement code.
- Non-goals: Apple IAP, Premium in the cart, vouchers, gifting, web checkout.

## Decisions

### 1. Cart and order items key on `products.id`
`cart_items(user_id, product_id, seen_price_idr, added_at, PK(user_id, product_id))`; `seen_price_idr` is the price the parent last confirmed, so a rise is reported once ("Harga naik dari ..."). Item type is derived through `product_ar_cards` / `product_dongengs`. `order_items(order_id, product_id, title, normal_idr, price_idr)` snapshots title and prices. Alternative considered: RFC's `(item_type, item_id)`. Rejected because it would need a join to find the entitlement key.

### 2. Reuse `orders`; add a cart shape
`orders` gains `is_cart`, `subtotal_idr`, `charge_idr`, `price_locked_until`, `store_product_id` (FK `store_products`), `idempotency_key` (unique per user), `granted_at`, `consumed_at`. The `CHECK` becomes: a cart order sets neither product nor package and has a store product; any other order sets exactly one of product or package. A single-product order created by the old path is unchanged.
Status stays `PENDING / PAID / FAILED / EXPIRED / REFUNDED`. The grant runs in the same transaction that sets `PAID` (and `granted_at`), so "paid in the store, not granted yet" is a `PENDING` order whose purchase token is on file (the token is stored before verification). The API exposes a derived `phase`: `menunggu`, `diproses` (pending + token), `diberikan`, `gagal`, `kedaluwarsa`, `dikembalikan`. Existing `PAID`/`REFUNDED` rows are backfilled with `granted_at = updated_at`.

### 3. One `settle()` for every trigger
Settlement is the existing `VerifyPlayPurchase`, extended for cart orders. It is called by `POST /orders/:id/verify`, the RTDN `oneTimeProductNotification` (the order id is read from the purchase's `obfuscatedExternalAccountId`), admin "Berikan ulang", and a one-minute worker over cart orders `PENDING` with a token on file. It: (1) verifies the purchase with Google (`purchases.products.get`); (2) checks that the product id equals `orders.store_product_id`'s Play SKU and that `obfuscatedExternalAccountId` carries the order id and the user matches; (3) stores `purchase_token` (already unique-by-index; a token linked to another order is rejected and alerted); (4) in one transaction, `SELECT ... FOR UPDATE` on the order, returns if already `PAID` (same token), upserts every `order_items` row into `user_entitlements` (restoring one a refund ended), deletes those products from `cart_items`, sets `status = PAID` and `granted_at`; (5) after commit, consumes the purchase server-side (retried until acknowledged; Play refunds un-acknowledged purchases after 3 days). The row lock plus the `granted_at` check makes repeats harmless.
Single-product and package orders keep their current path inside the same function. The worker also retries the consume step (`consumed_at`), closes orders Google reports as invalid, expires unpaid cart orders a day after their lock, and pushes "Item siap dibuka" when it grants an order the app stopped waiting for.

### 4. Store product per total
`store_products(id, store, play_product_id UNIQUE, price_idr, active, UNIQUE(store, price_idr))`. On Google the product is exact: `charge_idr = total_idr`, so `pickProduct` is an exact lookup and "Potongan keranjang" never appears in this phase. If the lookup misses, the order is refused with `AMOUNT_UNAVAILABLE`. Product ids are `arunika.cart.t<rupiah>`. The app never builds a product id.
The backend accepts a single "Beli" as an order of one (`POST /orders` with `items`, product `arunika.cart.t<price>`). The app keeps "Beli" on the existing per-item SKU path in this change, so single purchases do not depend on the 500 cart products or the `cart` flag; switching "Beli" over is a follow-up once the store products are live. Per-item `play_product_id` and the `/payment/play/*` product routes stay.

### 5. Price lock
`POST /orders` stores locked `price_idr` per item and `price_locked_until = now + 30 min`. `settle()` always uses the order's saved prices and total. After the lock expires and before payment starts, `POST /orders` rejects with `CART_CHANGED` if a price moved. A Google pending purchase (cash, delayed methods) that completes after the lock is still settled at the locked prices, because the parent had already started paying.

### 6. `CART_CHANGED` instead of silent change
`POST /orders` re-checks each item (on sale, price, owned, free, Premium). Items owned or free are removed from the cart and reported; price up or promo ended stays in the cart flagged `price_changed_from`; price down applies silently; off-sale rows are marked `unavailable` and excluded from the total. If anything other than a silent price drop happened, the response is `409 CART_CHANGED` with the full new cart and `notices[]`, and no order is created. The app shows "Ada perubahan"; "Bayar lagi" retries. A request with the same `Idempotency-Key` returns the same order.

### 7. Limits and price step
At most 20 items and Rp 500.000 total. Prices must be multiples of Rp 1.000 so only 500 totals exist. Enforced in `products`: `CHECK (price_idr % 1000 = 0)`. The migration first lists any offending rows and fails loudly instead of rounding. A price of 0 is allowed (V33 catalog placeholders) but is never for sale in the cart. Backoffice and the admin API reject non-multiples with a validation error.

### 8. Premium
`GET /cart` and `POST /orders` call `EntitlementService.HasActiveSubscription`. A subscriber gets an empty cart, `cart_enabled = false` on the profile, and a notice when items were dropped; `POST /cart/items` and `POST /orders` answer `409 SUBSCRIPTION_ACTIVE` (the same code the repo already uses). When a subscription is granted, `settle()` for a package order also deletes the user's `cart_items`.

### 9. Refunds
Voided-purchase polling and RTDN already reach `reconcileVoidedPurchase`. For a cart order it sets `status = REFUNDED` and, through the existing `RevokeEntitlementForOrder`, ends every entitlement with `source_order_id = order.id` (`expires_at = NOW()`); no new `revoked_at` column was needed. `order_refunds` is reused. A re-purchase restores the entitlement (`GrantOrRestoreEntitlement` clears `expires_at`).

### 10. Parental gate
Existing behaviour passes the gate once per app session. Payment is stricter: **Bayar always shows the gate**, even when already passed this session, because the PRD requires the gate to stop a child who picks up an unlocked phone. Browsing the cart needs no gate. This is a small deliberate deviation from the `parental-gate` spec; it only adds a requirement for the cart.

### 11. App architecture
A `CartNotifier` (ChangeNotifier singleton, like `FeatureFlagsNotifier`, shared by the list badges, card states and the cart screen) mirrors `GET /cart`; adds and removes are optimistic and roll back on error. Undo keeps the removed product in memory for 5 seconds and calls add again. `BillingService` gains `purchaseCart(order)`: it launches the consumable named by the order's `play_product_id` with the order id as `applicationUserName`, `autoConsume` off. The purchase-stream handler sends every purchase (including ones restored at start) to `/orders/:id/verify`; `syncPendingPurchases` continues to cover single-product recovery. Result screens: `diberikan` -> Berhasil; user cancel or error -> Dibatalkan; `diproses` -> Sedang diproses, polling `GET /orders/:id` every 5 s for 1 minute, then a push when granted (existing FCM service). The cart is behind an `app_feature_flags` key `cart` (fail-closed in the app), and it is hidden for subscribers (profile `is_subscribed`, or a `SUBSCRIPTION_ACTIVE` answer). go_router gets `/cart` and `/cart/result`; "Ringkasan pembayaran" is a bottom sheet. After a grant the lists reload through `CartNotifier.grants`.

### 12. Analytics
Events from the PRD (`cart_add`, `cart_remove`, `cart_undo`, `cart_view`, `checkout_start`, `parent_gate_pass`, `payment_success`, `payment_cancel`, `payment_fail`, `grant_complete`) are emitted with item ids, count and total through `CartEvents.sink`. The app has no analytics SDK, so the sink is the structured log for now.

## Risks / Trade-offs
- **500 consumable products to create and keep.** Mitigated by the tool and by `store_products`; a total with no active product returns `AMOUNT_UNAVAILABLE` and the backoffice flags it.
- **Play minimum price.** Kartu AR is sold at Rp 1.000. If Play will not list a Rp 1.000 product, the floor moves and the price step with it. Check in Play Console before build.
- **Legacy single-product path keeps existing until old builds age out**, so two purchase paths coexist for a while. Tests cover both.
- **Paid-but-not-granted** is the worst failure. Mitigations: idempotent `settle()`, minute worker, RTDN, and an alert at 10 minutes. An owner for the alert is still needed.
- **Existing prices that are not multiples of Rp 1.000** would break the `CHECK`; the migration reports them first.
- **Strike price is display-only**, so "promo savings" in the cart is informational. The charged price is always `price_idr`.

## Migration Plan
1. `V68__create_cart_and_cart_orders.sql` (one migration: price-step check, cart and order tables, order columns, backfill, `cart` flag off).
2. Create Play consumables with `cmd/storeprices`; verify with a license-tester account.
3. Release the app with the `cart` flag off; turn it on for staff accounts, then 10%, watch the paid-not-granted alert for a week, then 100%.
4. Later change: remove the per-product Play SKU purchase path and add Apple.
Rollback: turn off the `cart` flag. Orders and entitlements already granted stay valid; the new tables are additive.

## Open Questions
- Lowest IDR price Play accepts for a consumable, and whether `monetization.onetimeproducts` or legacy `inappproducts` is the API to script (Play Console check).
- Who owns the paid-not-granted alert and "Berikan ulang"? (Not decided in the RFC.)
- Is the existing FCM channel enough for the delayed-grant push ("item siap dibuka")? The repo has FCM tokens and notifications; the payload type still needs confirming.
- Parental gate on every Bayar (decision 10) versus once per session: confirm with product.
- Apple follow-up: timing, and the Apple IDR price-point list.

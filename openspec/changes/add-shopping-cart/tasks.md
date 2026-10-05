## 1. Console checks (blocks section 4.2 and rollout)
- [ ] 1.1 Confirm in Play Console the lowest IDR price for a consumable (Rp 1.000?) and whether the legacy `inappproducts` API used by `cmd/storeprices` is still accepted for this app (else switch it to `monetization.onetimeproducts`)
- [ ] 1.2 Decide the owner of the paid-not-granted alert and "Berikan ulang"
- [x] 1.3 Delayed-grant push uses the existing FCM `NotificationService` (type `cart_granted`)

## 2. Backend data (arunika-backend)
- [x] 2.1 `cart_items` (with `seen_price_idr`)
- [x] 2.2 `order_items`, cart columns on `orders`, relaxed CHECK, `granted_at` backfill, idempotency key
- [x] 2.3 `store_products`
- [x] 2.4 Price-step CHECK (lists offenders and fails); refunds reuse `expires_at`, no `revoked_at` needed
- [x] 2.5 Models; constraints and backfill exercised by the real-Postgres API tests (all in one migration, `V68__create_cart_and_cart_orders.sql`)

## 3. Backend cart and orders
- [x] 3.1 `CartService` rules: add, remove, clear, limits, owned/free/Premium checks, notices
- [x] 3.2 Cart handlers and routes, `cart` feature flag (off), `cart_enabled` on the profile
- [x] 3.3 Subscription grant clears the cart
- [x] 3.4 `POST /orders` with re-check, price lock, idempotency key, rate limit, `CART_CHANGED`
- [x] 3.5 Settlement: verify, product and order-id match, token uniqueness, transactional grant, server-side consume
- [x] 3.6 `/orders/:id/verify`, one-time-product RTDN and the minute worker; alert log at 10 minutes; push on delayed grant
- [x] 3.7 Refund ends every item of the order; re-purchase restores
- [x] 3.8 `GET /entitlements`, phase and items on `GET /orders/:id`
- [x] 3.9 `/payment/play/*` single-product routes unchanged; existing tests still pass
- [x] 3.10 `openapi.yaml` and contract tests
- [x] 3.11 Tests: 18 API tests against Postgres + fake Play (rules, limits, price rise/drop, idempotency, cheaper-receipt, wrong order, pending, concurrency, refund/restore); sqlmock tests updated

## 4. Store products
- [x] 4.1 `cmd/storeprices` with dry run and idempotence; credentials from the environment the deploy fills from the secret store
- [ ] 4.2 Run against Play (license tester account) and fill `store_products` — needs 1.1 and Play credentials
- [x] 4.3 Admin API validation for the Rp 1.000 step

## 5. Backoffice (arunika-backoffice)
- [x] 5.1 Orders list as Pesanan: cart items, paid-not-granted filter/tag, cart-only and date filters
- [x] 5.2 "Berikan ulang" (backend writes the audit log)
- [x] 5.3 Price field validation and the Rp 500.000 note
- [x] 5.4 "Produk toko" page with missing-total flags
- [x] 5.5 Vitest (orders, store products, price step, product form); contract fixture synced
- [ ] 5.6 Playwright e2e for the cart pages (needs the docker stack)

## 6. App (arunika_app)
- [x] 6.1 `CartApi`, `CartNotifier` (optimistic add/remove, 5 s undo)
- [x] 6.2 Beli + cart icon, in-cart state and toast on the Kartu AR and Dongeng lists (locked items have no detail screen to extend)
- [x] 6.3 Header badge on both lists
- [x] 6.4 Keranjang screen, empty state, "Hapus semua" confirmation, "Ada perubahan" state
- [x] 6.5 Checkout: parental gate on every Bayar, `POST /orders`, Ringkasan sheet
- [x] 6.6 `BillingService.purchaseCart` and recovery of interrupted cart purchases at start
- [x] 6.7 Berhasil, Dibatalkan and Sedang diproses screens with polling (push comes from the backend)
- [x] 6.8 Hidden for subscribers and while the flag is off (there is no "Pulihkan pembelian" screen in the app; ownership already comes from the server, and `CartApi.fetchEntitlements` is ready for one)
- [x] 6.9 Funnel events through `CartEvents` (log sink until an analytics SDK exists)
- [x] 6.10 Tests: model, notifier, cart screen and checkout flow, list integration, Play cart purchase; `FakeBilling` updated
- [ ] 6.11 Switch single "Beli" to an order of one through `POST /orders` (after 4.2)

## 7. Rollout and validation
- [ ] 7.1 End to end on Play license testers: success, cancel, pending payment, app killed after payment, refund
- [ ] 7.2 Release with the flag off; staff on; 10%; watch the alert a week; 100%
- [x] 7.3 `openspec validate add-shopping-cart --strict`

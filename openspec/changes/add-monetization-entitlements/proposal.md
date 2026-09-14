# Change: Entitlement-based monetization model (products, orders, payments, entitlements)

## Why

Today, access to paid content is not actually enforced anywhere. `ar_cards.is_unlocked` / `Animal.is_unlocked` are stored flags that no server-side code reads, and `dongengs.is_free` is likewise never checked before serving content — enforcement is entirely client-side and trivially bypassable. Worse, the Midtrans payment webhook grants every successful purchase a hardcoded "+1 month subscription", regardless of whether the user bought a one-time content bundle or an actual subscription plan, so there is no real mapping from *what was purchased* to *what the user can access*. On top of that, the Flutter payment screen navigates straight to the "unlocked" success screen from its own webview callback, without ever waiting for backend confirmation — a malicious client could reach it without paying. Separately, a live regression (`GET /premium/packs` currently returns zero rows due to a query-filter bug) is currently blocking the premium upgrade screen entirely.

This change implements the `arunika_design.md` gap analysis: a `products` → `orders`/`payments` → `user_entitlements` model, replacing the ad-hoc flags with real per-user, server-enforced ownership, across the backend, the Flutter app, and the backoffice admin UI — and removes the now-superseded dead schema/code along the way.

## What Changes

- **Backend catalog**: reuse the currently-dead `features` table as a taxonomy (`AR_CARD`, `DONGENG` — no `worksheets`, since that content type doesn't exist in the app); add `products`, `product_ar_cards`, `product_dongengs` mapping tables with real FKs (no polymorphic `resource_type`/`resource_id`).
- **Backend packages**: add `premium_package_items` (package → products) and a `duration_days` column on `premium_packages` so subscription plans can have distinct durations instead of a hardcoded 1 month. **BREAKING**: `premium_packages` no longer directly implies which content it unlocks — that now goes through `premium_package_items`.
- **Backend orders & payments**: add `orders` (PENDING/PAID/FAILED/EXPIRED, references exactly one of `product_id`/`package_id`); rename/extend `payment_transactions` → `payments` (adds `order_id`). `POST /payment/create` creates an order before creating the Midtrans transaction; the webhook drives order status and entitlement granting, never the client. Add authenticated `GET /orders/:id` for the app to poll. **BREAKING**: Midtrans `order_id` format changes from `sub-<userID>-<ts>` to one derived from the new `orders.id`.
- **Backend entitlements & access control**: add `user_entitlements` (unique per user+product, idempotent grant). AR card/dongeng read endpoints compute `is_unlocked` per request from entitlements/active subscription instead of a stored flag; drop the now-redundant `ar_cards.is_unlocked` / `Animal.is_unlocked` stored columns after cutover. **BREAKING**: content with no linked product is now implicitly free — previously-meaningless `is_unlocked=false` defaults no longer gate anything.
- **Backend subscriptions**: evolve `user_subscriptions` in place (add `package_id`, `start_date`, `auto_renew`, rename `midtrans_order_id`→`provider_order_id`) as the single source of truth; drop the already-dead `subscriptions`/`plans`/`plan_features`/`vouchers`/`voucher_redemption` tables and matching Go models.
- **Backend hotfix**: fix the live `GET /premium/packs` empty-result regression (pre-existing bug, unrelated to this redesign but blocking it).
- **Backend cleanup**: remove `models/plan.go`, `models/subscription.go` (old), `models/payment.go`, the fully-commented-out `V20__add_payment_transactions.sql` migration, and the unused `github.com/veritrans/go-midtrans` dependency.
- **Flutter app**: `PaymentScreen` no longer trusts its own webview `onSuccess` callback — it polls the new `GET /orders/:id` until the backend confirms `PAID` before navigating to `/unlock-success`, with waiting/retry states for pending/failed/timeout. `POST /payment/create` request/response includes the new `order_id`.
- **Backoffice**: extend `PremiumPackagesPage` (or a linked view) to manage `premium_package_items` (assign/remove products to a package); add read views for the new `products` catalog and `orders`; existing `PaymentsPage` and the admin manual-grant permission flow (`PATCH /admin/users/:id/permission`) keep working against the renamed/extended schema.
- **Tests**: fix the 3 currently-failing backend tests (symptom of the live bug above); add backend coverage for the previously-untested `PaymentService.CreateSnapTransaction`/`HandleWebhook` and all new services; add backoffice page-level tests (none exist today) for the new/changed admin pages and `premiumPackagesApi` (currently untested); add Flutter tests for the payment-polling flow.

## Capabilities

### New Capabilities
- `monetization-catalog`: backend `features`/`products`/`product_ar_cards`/`product_dongengs` schema and internal resolution APIs
- `monetization-orders-payments`: backend `orders`/`payments` tables, order-first payment creation, webhook-driven idempotent settlement, `GET /orders/:id`
- `user-entitlements`: backend `user_entitlements` table, transactional entitlement granting, per-request access resolution replacing stored unlock flags
- `backoffice-unit-tests`: page-level and API-layer test coverage conventions for the backoffice, starting from zero existing page tests

### Modified Capabilities
- `premium-package-cms`: adds `premium_package_items` admin CRUD and `duration_days` on packages
- `payment-screen`: replaces client-trusted success navigation with backend-polled confirmation
- `unlock-success-screen`: only reachable after backend-confirmed `PAID` order
- `premium-package-backoffice`: adds package-item assignment UI and read views for products/orders
- `dongeng-list-screen`: "requires premium access" is redefined from `is_free` alone to entitlement-aware, and locked-story tap now routes to the upgrade flow
- `backend-unit-tests`: extends required coverage to the new services and fixes the 3 pre-existing failing tests
- `flutter-unit-tests`: extends required coverage to the payment-polling flow

## Impact

- **New backend tables**: `products`, `product_ar_cards`, `product_dongengs`, `premium_package_items`, `orders`, `user_entitlements`
- **Renamed/altered backend tables**: `payment_transactions`→`payments` (+`order_id`), `premium_packages` (+`duration_days`), `user_subscriptions` (+`package_id`,+`start_date`,+`auto_renew`, rename `midtrans_order_id`→`provider_order_id`), `ar_cards`/`animals` (drop `is_unlocked` column post-cutover)
- **Dropped backend tables**: `subscriptions` (old), `plans`, `plan_features`, `vouchers`, `voucher_redemption`
- **New/changed backend routes**: `GET /orders/:id` (new); `POST /payment/create` response gains `order_id`; `POST /payment/webhook` internals rewritten; `GET /ar/cards*`, `GET /fairy-tales*` responses gain per-request-computed `is_unlocked`
- **Removed backend code**: `models/plan.go`, `models/subscription.go`, `models/payment.go`, `db/migrations/V20__add_payment_transactions.sql`, unused `go-midtrans` dependency
- **Flutter**: `lib/presentation/screens/payment/payment_screen.dart` (polling flow), `lib/data/api/*` (order status endpoint), `lib/presentation/screens/dongeng/*` (locked-tap navigation)
- **Backoffice**: `src/pages/packages/PremiumPackagesPage.tsx` (package items), new pages/views for products and orders, `src/api/admin.ts` additions, `src/api/auth.ts` (remove unused `refresh`)

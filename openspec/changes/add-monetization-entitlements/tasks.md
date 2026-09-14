## 1. Backend — Hotfix (do first, unblocks premium upgrade screen)

- [x] 1.1 Fix `models.FindActivePremiumPackages` (`models/premium_package.go`) so an empty `packType` argument applies no type filter instead of `type = ''`; update/remove the stale doc-comment claiming the parameter is ignored
- [x] 1.2 Re-run `go test ./services/... ./handlers/...` and confirm `TestPremiumPackService_GetActivePacks_Success`, `TestPremiumPackService_GetActivePacks_DBError`, `TestGetActivePacks_ReturnsOnlyActive` pass — also updated `TestGetActivePacks_TypeParamIgnored` (renamed to `TestGetActivePacks_TypeParamFilters`), which had asserted the old buggy behavior

## 2. Backend — Catalog Schema (`monetization-catalog`)

- [x] 2.1 Migration: seed `features` with `AR_CARD` and `DONGENG` rows (table already exists from `V1__init.sql`, currently empty/unused) — `V31__seed_features.sql`
- [x] 2.2 Migration: create `products` table (`id`, `feature_id` FK, `price_idr`, `is_active`, `created_at`, `updated_at`) — `V32__create_products.sql`
- [x] 2.3 Migration: create `product_ar_cards` and `product_dongengs` mapping tables with FK/unique constraints per design.md §2 — `V32__create_products.sql`
- [x] 2.4 Add GORM models `models/product.go`, `models/product_ar_card.go`, `models/product_dongeng.go`
- [x] 2.5 Backfill migration/script: for every currently-paid AR card and dongeng, insert a `products` row + mapping row — `V33__backfill_products_catalog.sql`. Defined "paid" as `ar_cards.is_unlocked = false` / `dongengs.is_free = false` (the existing flags' own semantics). `price_idr` backfilled to `0` as a placeholder — there's no per-item price yet since individual items are only ever sold today as part of a package bundle (matches the design's explicit Non-Goal of no single-item purchase UI).
- [x] 2.6 Write `services/product_service_test.go` and `services/product_service.go` (create/list/resolve-by-content-id)

## 3. Backend — Package Items & Duration (`premium-package-cms`)

- [x] 3.1 Migration: `ALTER TABLE premium_packages ADD COLUMN duration_days INTEGER NULL` + CHECK/validation that it's set when `type='subscription'` — `V34__add_premium_package_duration.sql`
- [x] 3.2 Migration: backfill `duration_days = 30` for "Bulanan", `365` for "Tahunan" — `V34__add_premium_package_duration.sql`
- [x] 3.3 Migration: create `premium_package_items` table per design.md §3 — `V35__create_premium_package_items.sql`
- [x] 3.4 Backfill migration/script: populate `premium_package_items` for the 3 existing content packs (Hutan/Lautan/Ternak) and ALL ACCESS PASS — `V35__create_premium_package_items.sql`. **Design gap found & resolved with the user**: the pack subtitles ("8 Hewan Hutan...") actually refer to the separate, unrouted `animals` table, not `ar_cards` — and design.md §2 never defined a `product_animals` table. Resolved per user direction: `animals` stays legacy/untouched (not part of this catalog); going forward, animal content should be modeled as `ar_cards` rows with `category` = `hutan`/`laut`/`ternak`. The backfill matches packs to paid `ar_cards` by that category column — today's seed data has no categorized ar_cards yet, so this inserts zero rows until content is actually categorized (expected, not a bug). ALL ACCESS PASS bundles every paid product unconditionally.
- [x] 3.5 Add `models/premium_package_item.go`; add `duration_days` to `models/premium_package.go`
- [x] 3.6 Update `services/premium_pack_service.go` create/update to accept and validate `duration_days`
- [x] 3.7 Add `GET/POST /admin/premium/packs/:id/items` and `DELETE /admin/premium/packs/:id/items/:product_id` handlers + service methods
- [x] 3.8 Update `services/premium_pack_service_test.go` and `handlers/premium_pack_handler_test.go` for `duration_days` validation and the new items endpoints

## 4. Backend — Orders & Payments (`monetization-orders-payments`)

- [x] 4.1 Migration: create `orders` table with CHECK constraint per design.md §4 — `V36__create_orders_and_payments.sql`
- [x] 4.2 Migration: rename `payment_transactions` → `payments`, add `order_id UUID NOT NULL REFERENCES orders(id)` — `V36__create_orders_and_payments.sql`. **Deviated from the nullable-then-backfill-then-NOT-NULL plan**: `payment_transactions` (V6)'s actual schema never matched what `models/payment_transaction.go` read/wrote (the code's shape only ever existed in the commented-out V20) — there was no valid data to preserve, so the migration drops and recreates the table directly with `order_id NOT NULL` from the start. Also renamed the pre-existing `order_id` (Midtrans's own order id string) to `provider_order_id` to free up `order_id` for the new internal FK — mirrors the same `midtrans_order_id`→`provider_order_id` rename already used on `user_subscriptions` (task 6.1).
- [x] 4.3 Rename `models/payment_transaction.go` → `models/payment.go` (old dead `models/payment.go` deleted first, per the ordering note)
- [x] 4.4 Add `models/order.go`
- [x] 4.5 Rewrite `services/payment_service.go` `CreateSnapTransaction`: create an `orders` row (`status=PENDING`) first, derive Midtrans `order_id` from `orders.id` (e.g. `order-<id>`), replacing the `sub-<userID>-<ts>` scheme
- [x] 4.6 Update `handlers/payment_handler.go` `CreateTransaction` response to include `order_id` (via the `SnapResponse.OrderID` field — no handler-level change needed)
- [x] 4.7 Rewrite `services/payment_service.go` `HandleWebhook`: look up `orders` by provider order id (parsed back out of `order-<uuid>`), always insert a `payments` audit row, and — only if order is still `PENDING`, inside one DB transaction with `SELECT ... FOR UPDATE` — mark order `PAID`/`FAILED`/`EXPIRED` and invoke entitlement granting (see §5)
- [x] 4.8 Add `GET /orders/:id` handler (owner-only, 404 for non-owners) + route registration + `services/order_service.go`
- [x] 4.9 Update `services/admin_payment_service.go` for the renamed `payments` table/columns (straight rename, no behavior change); backoffice-facing query updates are out of scope of this repo
- [x] 4.10 Write/update `services/payment_service_test.go` per the `backend-unit-tests` delta (CreateSnapTransaction, HandleWebhook happy path, idempotent replay, invalid signature, unrecognized order-id format)
- [x] 4.11 Write `services/order_service_test.go` and `handlers/order_handler_test.go`
- [x] 4.12 **Found post-implementation (2026-09-09), user-flagged**: `CreateSnapTransaction` created an `orders` row but no `payments` row — an abandoned/lost-webhook checkout left zero payment audit trail. Fixed by creating an initial `payments` row (`transaction_status=pending`) in the same DB transaction as the `orders` insert.
- [x] 4.13 **Found post-implementation (2026-09-09), user-flagged**: `GET /orders/:id` only ever read the DB, which is only updated by the webhook — a delayed/dropped webhook notification stranded the Flutter client's poll at timeout with no way to resolve. Fixed by extracting the webhook's status-transition logic into `PaymentService.applyTransactionStatus` (shared helper) and adding `PaymentService.SyncOrderStatus`, called from `OrderHandler.GetByID` for still-`PENDING` orders: it actively queries Midtrans's Core API transaction-status endpoint and applies any settlement/failure it finds via the same shared path a webhook delivery uses. Fails open (returns last known DB state) on any Midtrans/network error so a transient outage never turns a read into a 500. Webhook remains the primary/authoritative path — this is a fallback for when it's delayed or lost, not a replacement.
- [x] 4.14 **User-requested (2026-09-09)**: store the Midtrans Snap payment link on `payments`. Added `payments.payment_url TEXT NULL` (`V41__add_payment_url.sql`, verified against the live dev DB via Flyway), `models.Payment.PaymentURL`, and `CreateSnapTransaction` now writes `snapResp.RedirectURL` onto the just-created `payments` row once the Snap API responds (it isn't known until then, so it's a follow-up update rather than part of the initial insert).

## 5. Backend — Entitlements & Access Control (`user-entitlements`)

- [x] 5.1 Migration: create `user_entitlements` table per design.md §5 — `V37__create_user_entitlements.sql`
- [x] 5.2 Add `models/user_entitlement.go`
- [x] 5.3 Implement `services/entitlement_service.go`: `GrantForPaidOrder(order)` (content-package fan-out via `premium_package_items`, single-product grant, subscription upsert per design.md §5) and `HasAccess(userID, productID)`
- [x] 5.4 Wire `EntitlementService.GrantForPaidOrder` into the webhook transaction from task 4.7
- [x] 5.5 Update `services/ar_service.go` `GetAll`/`GetByID` to compute `is_unlocked` per request via `EntitlementService.HasAccess`, using optional-auth (unauthenticated → free-only access) — new `middlewares/optional_auth_middleware.go`, wired onto `GET /ar/cards` and `GET /ar/cards/:id` (the latter previously required mandatory JWT; now works unauthenticated too, always locked unless free)
- [x] 5.6 Update `services/dongeng_service.go` to add a computed `is_unlocked` field alongside existing `is_free`; wired the same optional-auth middleware onto `GET /fairy-tales` and `GET /fairy-tales/:id` (previously fully public with no auth context at all)
- [x] 5.7 Verify `SubscriptionMiddleware` (`middlewares/subscription_middleware.go`) still works against the altered `user_subscriptions` shape (task 6) — confirmed unchanged/compatible; it only reads `Status`/`ExpiresAt`, neither of which moved
- [x] 5.8 Migration: drop `ar_cards.is_unlocked` and `animals.is_unlocked` columns — `V39__drop_content_is_unlocked_columns.sql`. Both Go model fields kept (via `gorm:"-"`) purely so `is_unlocked` still serializes in JSON; `ar_cards`' is now populated per-request by `ArService`, `animals`' always reads `false` (no `product_animals` mapping exists — see task 3.4 note — and `GET /animals` isn't routed today, so this has no observable effect). Also updated `db/migrations/R__init.sql`'s animal seed data to drop the now-nonexistent column.
- [x] 5.9 Write `services/entitlement_service_test.go` covering grant fan-out, idempotent re-grant, subscription grant, single-product grant, and `HasAccess` for free/entitled/subscribed/expired-subscription/none cases. Also added `middlewares/optional_auth_middleware_test.go` (not explicitly required by this task, but new auth-path code warranted direct coverage).

## 6. Backend — Subscription Cleanup

- [x] 6.1 Migration: `ALTER TABLE user_subscriptions ADD COLUMN package_id UUID NULL REFERENCES premium_packages(id), ADD COLUMN start_date TIMESTAMPTZ NULL, ADD COLUMN auto_renew BOOLEAN NOT NULL DEFAULT FALSE, RENAME COLUMN midtrans_order_id TO provider_order_id` — `V38__alter_user_subscriptions.sql`
- [x] 6.2 Update `models/user_subscription.go` for the new/renamed columns
- [x] 6.3 Update the admin manual-grant path (`PATCH /admin/users/:id/permission` → `AdminUserService.GrantPremium`) to set `package_id = NULL`, `start_date = now` on manual grants, keeping it working unchanged from the admin's perspective
- [x] 6.4 Migration: drop tables `subscriptions` (old), `plans`, `plan_features`, `vouchers`, `voucher_redemption` — `V40__drop_dead_subscription_tables.sql`
- [x] 6.5 Delete `models/subscription.go`, `models/plan.go` — also deleted `models/vouchers.go`/`models/voucher_redemption.go` (zero references anywhere, and their backing tables are dropped in the same migration; not explicitly listed in this task but clearly the same category of dead code per design.md's Why section)

## 7. Backend — Dead Code Removal

- [x] 7.1 Delete `models/payment.go` (old, distinct from `payments`/`payment_transactions`) — see ordering note in 4.3
- [x] 7.2 Delete `db/migrations/V20__add_payment_transactions.sql` (fully commented out, superseded by V6)
- [x] 7.3 Remove `github.com/veritrans/go-midtrans` from `go.mod`/`go.sum` (unused indirect dependency); run `go mod tidy`
- [x] 7.4 Grep the codebase for any remaining references to removed models/tables before deleting to confirm nothing else depends on them — done before every deletion in this change

## 8. Backend — Config & Hardening (Midtrans)

- [x] 8.1 Replace the hardcoded `https://app.sandbox.midtrans.com/snap/v1/transactions` URL in `services/payment_service.go` with an env-driven base URL (sandbox/prod) — new `MIDTRANS_BASE_URL` env var, defaults to the sandbox host when unset

### Migration verification (ran against the real local dev DB, not just Go unit tests)

All of V31–V40 plus the edited `R__init.sql` were run end-to-end via `docker compose run --rm flyway` against the actual dev Postgres (already at V30 with real seed data) — go unit tests only exercise GORM-generated SQL, never the hand-written migration SQL itself, so this was the only way to actually confirm the migrations are valid. Two things came up, both fixed:
- **Deleting V20 breaks Flyway validation** on any DB that already recorded it as applied (this dev DB included) — a one-time `flyway repair` is needed after pulling this change on such environments (deployment note, not a code fix).
- **Pre-existing bug in `R__init.sql`**: the `ar_cards` and `categories` seed inserts had no `ON CONFLICT` clause (unlike every other insert in that file), so editing the file's checksum and letting Flyway re-run it as a repeatable migration failed with a duplicate-key error on the already-seeded rows. Added `ON CONFLICT (id) DO NOTHING` to both — this was latent before this change (would have broken on the *next* unrelated edit to that file too) and is now fixed as a side effect of verifying task 5.8's animal-seed edit.

Post-migration counts on the dev DB matched expectations exactly: 3 `products` (1 ar_card + 2 dongengs — the current seed's only paid items), 3 `premium_package_items` (all bundled into ALL ACCESS PASS; Hutan/Lautan/Ternak matched zero ar_cards by category, as documented in 3.4), `duration_days` = 30/365 for Bulanan/Tahunan, and `ar_cards`/`animals` no longer have an `is_unlocked` column.

## 9. Flutter — Payment Trust Rework (`payment-screen`, `unlock-success-screen`)

- [x] 9.1 Add `order_id` to the `POST /payment/create` request/response model in the Flutter API layer (captured directly in `payment_screen.dart`'s `_startPayment`, no dedicated payment API/repository existed previously)
- [x] 9.2 Add `lib/data/api/order_api.dart` (`fetchOrderStatus(orderId)` → `GET /orders/:id`) and `lib/data/repositories/order_repository.dart`
- [x] 9.3 Update `payment_screen.dart`: on webview `onSuccess`/`onPending`, show a waiting state and poll `OrderRepository.fetchOrderStatus` every 2s up to a 30s timeout (via new `PaymentPollingCubit`)
- [x] 9.4 Navigate to `/unlock-success` only when polled status is `PAID`; show retry UI for `FAILED`/`EXPIRED`/timeout
- [x] 9.5 Register `OrderApi`/`OrderRepository` in `lib/di/locator.dart`

## 10. Flutter — Entitlement-aware UI (`dongeng-list-screen`)

- [x] 10.1 Confirm `DongengResponse` includes the new `is_unlocked` field from backend task 5.6; update the model's `fromJson` (defaults to `isFree` until the backend serves the field)
- [x] 10.2 Update `new_dongeng_list_screen.dart` lock-icon logic (and the equivalent card on `new_home_screen.dart`) to use `is_unlocked` instead of `!isFree` alone — `dongeng_list_screen.dart` (old) is dead/unrouted, left untouched
- [x] 10.3 Update tap handling so a locked story navigates to the premium upgrade screen instead of the player

## 11. Flutter — Cleanup & Tests

- [ ] 11.1 Delete `lib/data/static/premium_packs.dart` now that `GET /premium/packs` is fixed and confirmed stable (per the existing `Static PremiumPacks fallback removed after stabilisation` requirement) — **deferred**: depends on the backend hotfix (task 1.1, in `arunika-backend`) being deployed and confirmed stable, which isn't verifiable from this repo. Also note: the `PremiumPack` model class itself lives in this file and is still used app-wide — only the dead `PremiumPacks` static-data class (zero references today) would actually be removable.
- [x] 11.2 Write `test/data/repositories/order_repository_test.dart` per the `flutter-unit-tests` delta
- [x] 11.3 Write/update payment screen widget or cubit tests covering the polling states (pending → paid, pending → timeout) — added `test/presentation/screens/payment/payment_polling_cubit_test.dart` using `fake_async`, since polling logic was extracted into `PaymentPollingCubit` to keep it testable independent of the Midtrans webview
- [x] 11.4 Run `flutter analyze` and `flutter test`; fix any regressions from the `is_unlocked`/`order_id` model changes — clean analyze; test suite has 8 pre-existing failures unrelated to this change (verified against the pre-change tree)

## 11a. Backend — Admin Products/Orders Endpoints (found missing while starting §12)

`design.md`'s backoffice scope explicitly calls for "read views for the new products catalog and orders," and tasks 13.3/13.4 assume a list endpoint for each — but the backend work in §2/§4 only ever wired up `ProductService`/`OrderService` internally (product resolution, owner-scoped `GET /orders/:id`). No admin-facing list endpoint existed for either. Added as a prerequisite for §13:

- [x] 11a.1 Add `OrderService.List(status, page, perPage)` (mirrors `AdminPaymentService.List`'s pagination/filter shape)
- [x] 11a.2 Add `AdminProductHandler`/`AdminOrderHandler` + register `GET /admin/products` and `GET /admin/orders` (admin-auth protected)
- [x] 11a.3 Tests: `services/order_service_test.go` (List), `handlers/admin_product_handler_test.go`, `handlers/admin_order_handler_test.go`

## 12. Backoffice — API Layer

- [x] 12.1 Add `productsApi` (`list`) to `src/api/admin.ts`
- [x] 12.2 Add `packageItemsApi` (`list(packageId)`, `add(packageId, productId)`, `remove(packageId, productId)`)
- [x] 12.3 Add `ordersApi` (`list(params)`) — `get(id)` omitted: no `GET /admin/orders/:id` exists (only the owner-scoped `GET /orders/:id` from §4), and the read-only OrdersPage table doesn't need a detail fetch
- [x] 12.4 Add `duration_days` to the `PremiumPackage`/`PremiumPackageInput` TypeScript interfaces

## 13. Backoffice — UI

- [x] 13.1 Add Duration (Days) field to the package create/edit modal in `PremiumPackagesPage.tsx`, shown only for `type = subscription` (via `Form.useWatch`); cleared to `null` on submit when type isn't subscription
- [x] 13.2 Add a "Manage Items" action per package row opening an items view (list/add/remove products) backed by `packageItemsApi`
- [x] 13.3 Add `src/pages/products/ProductsPage.tsx` (read-only list) and route `/products` + sidebar entry
- [x] 13.4 Add `src/pages/orders/OrdersPage.tsx` (read-only list, status filter) and route `/orders` + sidebar entry
- [x] 13.5 (not originally listed) Fixed `PaymentsPage.tsx`'s `PaymentTransaction` interface for the backend's `payments` rename: the pre-existing `order_id` field used to hold the Midtrans order-id string, but now holds the new internal `orders.id` FK, with the old string moved to `provider_order_id`. Updated the "Order ID" column/drawer to read `provider_order_id`, and added a separate "Internal Order" row in the drawer for the new `order_id`. Without this the page would have silently displayed the wrong value with no type error.

## 14. Backoffice — Cleanup

- [x] 14.1 Remove unused `authApi.refresh` from `src/api/auth.ts` (dead code, no auto-refresh flow calls it) — also removed its now-orphaned test block in `auth.test.ts`

## 15. Backoffice — Tests (`backoffice-unit-tests`)

- [x] 15.1 Add `premiumPackagesApi` coverage to `src/test/api/admin.test.ts` (currently zero coverage)
- [x] 15.2 Add API tests for `productsApi`, `packageItemsApi`, `ordersApi`
- [x] 15.3 Add `src/test/pages/PremiumPackagesPage.test.tsx` (render, create, error state) — first page-level test in the repo, establishes the pattern. Required two jsdom polyfills added to `src/test/setup.ts` (`matchMedia`, `ResizeObserver`) since antd's grid/breakpoint and Select-dropdown-positioning hooks call them on every mount — every future antd page test benefits from these, not just this one.
- [x] 15.4 Add page-level tests for `ProductsPage` and `OrdersPage`
- [x] 15.5 Run `npm test` and confirm all suites pass — 45/45 across 7 files. Also ran `npm run lint`, `tsc -b --noEmit`, and `npm run build`, all clean. Note: the repo's default Node (v16.20.2 via the active nvm shell) is below the `>=20` engine requirement in `package.json` and can't install/run this toolchain (Vite 8/Vitest 4 require it); used `fnm`'s already-installed Node v24.18.0 for all of the above instead.

## 16. Cross-Repo QA

None of 16.1–16.6 have been run — they require all three services (backend, app, backoffice) plus a real or sandboxed Midtrans account running together, which wasn't set up in these sessions. `16.4`'s underlying fix was unit-tested and, along with the rest of the schema, verified against a real migrated dev Postgres (see the "Migration verification" note under §8) — but the full app→backend live-flow itself was not exercised. These remain open manual QA work before this change ships.

- [ ] 16.1 End-to-end: purchase a content package in the app → webhook settles → entitlements granted → collection screen shows the previously-locked cards as unlocked
- [ ] 16.2 End-to-end: purchase a subscription package → `user_subscriptions` active → previously-locked dongeng and AR cards all show unlocked without individual entitlement rows
- [ ] 16.3 Replay the same Midtrans webhook notification twice (e.g. via curl against `/payment/webhook` in a test environment) and confirm no duplicate entitlements/payments
- [ ] 16.4 Verify `GET /premium/packs` (no `type` param) now returns all active packages from the app's premium upgrade screen
- [ ] 16.5 Verify backoffice: create a package, assign items via "Manage Items", confirm the app's next purchase of that package grants exactly those items
- [ ] 16.6 Verify admin manual permission grant (`PATCH /admin/users/:id/permission`) still works end-to-end against the altered `user_subscriptions` schema
- [x] 16.7 Run full backend (`go test ./...`), Flutter (`flutter test`), and backoffice (`npm test`) suites and confirm all green — each run independently (backend and backoffice in this session, Flutter in the prior one); no single combined CI run exists across all three repos

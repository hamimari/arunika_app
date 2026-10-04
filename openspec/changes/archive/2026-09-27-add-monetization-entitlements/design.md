## Context

`arunika_design.md` (external gap-analysis doc) proposes a products → entitlements monetization model to replace ad-hoc flags. Repo research (2026-09-07) confirms the gaps against the *actual* current state across all three repos:

**Backend** (`arunika-backend`, Go/Gin/GORM, Flyway SQL migrations in `db/migrations/`):
- `ar_cards.is_unlocked` (`V25`) and `Animal.is_unlocked` are stored booleans, default `false`, never read by any server-side gating logic (grep-confirmed), and not even in the admin update whitelist (`services/admin_content_service.go:96-105`) — so today they cannot be legitimately toggled at all. Enforcement is 100% client-side and trivially bypassable.
- `dongengs.is_free` is stored and returned but similarly never enforced server-side; `GET /fairy-tales` and `GET /fairy-tales/:id` are fully public regardless of `is_free`.
- The only server-side gate in the whole codebase is `middlewares.SubscriptionMiddleware`, applied to exactly one route (`POST /counting/progress`).
- `payment_service.go`'s Midtrans webhook handler grants access by setting `user_subscriptions.status = "premium"` with a **hardcoded `+1 month`** expiry, regardless of which `premium_packages.type` was purchased. A one-time content-pack purchase (e.g. "Paket Hutan", `type = content`) is therefore currently granted the exact same "1-month subscription" as a real subscription plan — there is no mechanism that ties a purchase to the specific AR cards/dongeng it should unlock.
- `features`, `plans`, `plan_features`, `subscriptions` (old), `vouchers`, `voucher_redemption`, and `models/payment.go` are fully dead (zero Go references outside their own file) — vestigial from `V1__init.sql`.
- `worksheets` does not exist as a content type anywhere in the backend (zero grep hits). The source design doc's `product_worksheets` is aspirational, not a real current requirement.
- **Live production bug** (unrelated to this redesign but blocking it): `models.FindActivePremiumPackages` was changed in commit `aa6439e` to `WHERE is_active = ? AND type = ?` but is always called with `packType = c.Query("type")`, which is `""` when the Flutter app calls `GET /premium/packs` without a `type` filter. This currently matches **zero rows**, so the premium upgrade screen shows an empty list in production today. 3 backend tests already fail because of this (`TestPremiumPackService_GetActivePacks_Success`, `TestPremiumPackService_GetActivePacks_DBError`, `TestGetActivePacks_ReturnsOnlyActive`).

**App** (`arunika_app`, Flutter): `PaymentScreen` (`lib/presentation/screens/payment/payment_screen.dart`) navigates straight to `/unlock-success` from the Midtrans Snap webview's JS `onSuccess` callback — the backend webhook is never consulted before the app shows "unlocked". A malicious or buggy client could reach the unlock-success screen without a real payment.

**Backoffice** (`arunika-backoffice`, React/AntD/React Query): no `products`, `orders`, or `entitlements` concept exists anywhere in `src/`. `PremiumPackagesPage.tsx` manages `premium_packages` rows only — it has no way to say *which* AR cards/dongeng a package unlocks. Zero page-level tests exist in the entire repo (only API-client tests under `src/test/api/`).

## Goals / Non-Goals

**Goals**
- Every paid content item (AR card, dongeng) is gated by a real, server-enforced, per-user entitlement — not a global flag.
- A purchase creates an `Order`, is settled via a `Payment` record driven by the Midtrans webhook (never by the Flutter client), and grants entitlements inside one DB transaction, idempotently.
- Content-type bundles (`premium_packages.type = content`) and subscription plans (`type = subscription`) both flow through the same order/payment pipeline but grant access differently (specific product entitlements vs. blanket subscription access).
- Remove dead schema/models/config identified above.
- Bring backend, app, and backoffice test suites up to date with the new logic, and fix the 3 currently-failing tests.

**Non-Goals**
- No `worksheets` content type or `product_worksheets` table — doesn't exist in the app; out of scope until a worksheet feature is actually built.
- No individual (non-bundle) purchase UI in the Flutter app — the schema supports `orders.product_id` for a single product, but no screen exercises it yet. Building that UI is a future change.
- No subscription auto-renewal / recurring billing — `premium_packages` subscription packs remain one-time charges for a fixed duration, same as today.
- No change to the visual design of payment/unlock-success/dongeng/collection screens beyond what's needed for correctness (loading/waiting/error states).

## Decisions

### 1. Reuse `features` as the product taxonomy; skip `product_worksheets`
`features` is currently dead but exactly matches the design doc's intent. Seed it with `AR_CARD` and `DONGENG` only (not `WORKSHEET`). `products.feature_id → features.id`.

### 2. New catalog tables (capability: `monetization-catalog`)
```sql
products (id UUID PK, feature_id UUID FK, price_idr BIGINT, is_active BOOLEAN, created_at, updated_at)
product_ar_cards (product_id UUID PK FK->products ON DELETE CASCADE, ar_card_id UUID UNIQUE FK->ar_cards ON DELETE RESTRICT)
product_dongengs (product_id UUID PK FK->products ON DELETE CASCADE, dongeng_id UUID UNIQUE FK->dongengs ON DELETE RESTRICT)
```
A content item with **no row** in `product_ar_cards`/`product_dongengs` is implicitly free (no product = nothing to buy). This lets us drop `ar_cards.is_unlocked` as a stored column without adding a new `is_free` column to `ar_cards` — "free" is derived from "has no product", mirroring `dongengs.is_free` conceptually without a redundant field.

### 3. Package bundling (capability: `premium-package-cms`, MODIFIED)
```sql
ALTER TABLE premium_packages ADD COLUMN duration_days INTEGER NULL; -- required when type='subscription', NULL for type='content'
CREATE TABLE premium_package_items (
  package_id UUID NOT NULL REFERENCES premium_packages(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (package_id, product_id)
);
```
`duration_days` is the concrete fix for today's hardcoded `+1 month`: it lets "Bulanan" (30) and "Tahunan" (365) grant different durations, which the current code cannot do.

### 4. Orders & Payments (capability: `monetization-orders-payments`)
```sql
CREATE TABLE orders (
  id UUID PK, user_id UUID NOT NULL,
  product_id UUID NULL REFERENCES products(id),
  package_id UUID NULL REFERENCES premium_packages(id),
  amount_idr BIGINT NOT NULL, status VARCHAR(20) NOT NULL, -- PENDING|PAID|FAILED|EXPIRED
  created_at, updated_at,
  CHECK ((product_id IS NOT NULL)::int + (package_id IS NOT NULL)::int = 1)
);
```
`payment_transactions` (`V6`) is renamed/reshaped to `payments`, gaining `order_id UUID NOT NULL REFERENCES orders(id)`. It keeps its existing provider/status/raw-payload columns — it was already functioning as the payment-attempt audit log the design doc calls for, it just wasn't linked to an order.

**Flow**: `POST /payment/create` now creates an `Order` (status `PENDING`) *and* an initial `Payment` row (`transaction_status=pending`) together in one DB transaction, uses `order.id` to build the Midtrans `order_id` (replacing today's `sub-<userID>-<timestamp>` scheme), then creates the Snap transaction. Recording the `Payment` row at link-creation time (not only on webhook receipt) means an abandoned checkout or a lost webhook still leaves an audit trail instead of vanishing.

The webhook (`POST /payment/webhook`) looks up the `Order` by provider order id, always inserts a new `Payment` audit row for the callback, and — **only if the order is still `PENDING`** (idempotency guard, checked inside the same DB transaction that flips it to `PAID`) — grants access per Decision 5. Reprocessing the same webhook notification (Midtrans does resend) is a no-op once the order is no longer `PENDING`. This status-transition logic lives in a shared `PaymentService.applyTransactionStatus` helper.

A new authenticated `GET /orders/:id` (owner-only) lets the Flutter app poll for the backend-confirmed outcome instead of trusting its own webview callback. **Found post-implementation (2026-09-09)**: relying on the webhook alone means a delayed or dropped notification strands the client's poll at timeout with no way to resolve, even though Midtrans itself knows the true status. `GET /orders/:id` therefore also actively reconciles: for a still-`PENDING` order, `PaymentService.SyncOrderStatus` queries Midtrans's Core API transaction-status endpoint and applies any settlement/failure found via the same `applyTransactionStatus` path the webhook uses. It fails open (returns the last known DB row) on any Midtrans/network error, so this is a fallback for a slow/lost webhook, not a replacement for it — the webhook remains the primary, authoritative path.

### 5. Entitlement granting (capability: `user-entitlements`)
```sql
CREATE TABLE user_entitlements (
  id UUID PK, user_id UUID NOT NULL, product_id UUID NOT NULL REFERENCES products(id),
  starts_at TIMESTAMPTZ NOT NULL, expires_at TIMESTAMPTZ NULL,
  source_order_id UUID NULL REFERENCES orders(id), created_at TIMESTAMPTZ NOT NULL,
  UNIQUE (user_id, product_id)
);
```
On order → `PAID`:
- `package.type = 'content'`: resolve `premium_package_items` → `product_id`s, insert one `user_entitlements` row per product (`expires_at = NULL`, permanent), `ON CONFLICT (user_id, product_id) DO NOTHING` for idempotency.
- `package.type = 'subscription'`: upsert `user_subscriptions` (see Decision 6) with `end_date = now + package.duration_days`. Subscription access is **blanket**, not per-product — a user with an active subscription is treated as owning every paid AR card/dongeng system-wide, same as today's de facto behavior. This avoids materializing thousands of entitlement rows per subscriber and matches how "ALL ACCESS" style plans are marketed.
- `order.product_id` set directly (future single-item purchase): insert one `user_entitlements` row for that product.

**Access resolution** (used by AR card / dongeng read endpoints, computed per request, not stored):
```
has_access(user, content_item):
  if content_item has no linked product -> true                     # free content
  if user has active subscription (user_subscriptions.status='active' and not expired) -> true
  if user_entitlements row exists for (user, product) and not expired -> true
  else -> false
```
`ar_cards` API responses keep the `is_unlocked` JSON key (Flutter already reads it) but it becomes a per-request **computed** value instead of a stored column — no Flutter changes needed for that field. `dongengs` responses gain a new `is_unlocked` field (additive) computed the same way, alongside the existing `is_free`.

### 6. Subscription table cleanup
The design doc warns against having both `subscriptions` and `user_subscriptions` as ambiguous parallel sources of truth. Since `subscriptions` (`V1`, old `Subscription` model) is **already fully dead** and `user_subscriptions` (`V11`) is the one actually in use, we standardize on evolving `user_subscriptions` in place rather than introducing a third table:
```sql
ALTER TABLE user_subscriptions
  ADD COLUMN package_id UUID NULL REFERENCES premium_packages(id),
  ADD COLUMN start_date TIMESTAMPTZ NULL,
  ADD COLUMN auto_renew BOOLEAN NOT NULL DEFAULT FALSE,
  RENAME COLUMN midtrans_order_id TO provider_order_id;
```
`package_id` is nullable because the existing admin manual-grant path (`PATCH /admin/users/:id/permission` → `usersApi.updatePermission`) sets status/expiry without a purchase and must keep working unchanged.

### 7. Dead code removal
Drop (backend): `models/features.go`'s old dead-usage assumption is retired in favor of real use; drop `models/plan.go`, `models/subscription.go` (old), `models/payment.go`, tables `plans`, `plan_features`, `subscriptions` (old), `vouchers`, `voucher_redemption`, migration file `V20__add_payment_transactions.sql` (100% commented out), and the unused `github.com/veritrans/go-midtrans` indirect dependency from `go.mod`. Legacy `ar_cards.category`/`sub_category` free-text columns are left alone in this change (already flagged as backward-compat elsewhere) — removing them is unrelated to monetization and should be a separate change once all consumers are confirmed migrated to `category_id`/`sub_category_id`.

Drop (backoffice): `authApi.refresh` (`src/api/auth.ts:14-20`) — defined, never called, no auto-refresh flow exists to use it. Removing it is simpler than half-wiring a refresh flow nobody asked for.

### 8. Payment-trust fix (capability: `payment-screen`, `unlock-success-screen`)
`PaymentScreen`'s Midtrans webview `onSuccess` callback stops navigating directly to `/unlock-success`. Instead:
1. `POST /payment/create` returns `{ token, order_id }` (adds `order_id` to the existing response).
2. On webview `onSuccess`/`onPending`, the screen shows a "Menunggu konfirmasi..." waiting state and polls `GET /orders/:id` every 2s (max 30s) until `status` is `PAID`, `FAILED`, or `EXPIRED`, or the timeout elapses.
3. Only `PAID` navigates to `/unlock-success`. `FAILED`/`EXPIRED`/timeout show a retry affordance instead.

`UnlockSuccessScreen` is only ever reached after backend confirmation, so its existing celebratory content stays as-is — no visual change needed there beyond the entry-gating above.

## Risks / Trade-offs

- **Migration ordering risk**: `products`/`product_*` must be backfilled for every existing paid AR card/dongeng *before* the access-control switch goes live, or previously-visible paid content would suddenly appear free (no product row = free). Mitigated by sequencing in `tasks.md`: create schema → backfill products for currently-non-free content → switch access resolution → remove old flags, never combining backfill and cutover in one deploy.
- **Blanket subscription access** (Decision 5) is a simplification vs. the source doc's fully product-scoped model. Trade-off accepted because it matches current business reality (subscriptions are "all access" today) and avoids a fan-out entitlement-row-per-product-per-subscriber write on every purchase; revisit if subscriptions ever need partial-catalog scoping.
- **Renaming `payment_transactions` → `payments`** touches `admin_payment_service.go` and the backoffice `PaymentsPage`/`paymentsApi` response shape. Mitigated by keeping all existing columns and only adding `order_id`, so the admin payments list view needs no functional change, just a table/model rename.

## Migration Plan

Phased per `tasks.md`, mirroring the source design doc's phase structure but adapted to real current state:
1. Backend schema: `features` seed, `products`, `product_ar_cards`, `product_dongengs`, `premium_package_items`, `duration_days`, `orders`, `payments` (rename), `user_entitlements`, `user_subscriptions` alter — additive only, no behavior change yet.
2. Backfill: create `products` + mapping rows for every currently-paid AR card/dongeng (defined as: not free today under the old flags) and `premium_package_items` for existing packages' known content.
3. Orders/payments/webhook rewrite behind the same public routes; entitlement granting wired in.
4. Access-control cutover: AR card/dongeng endpoints compute `is_unlocked` from entitlements instead of the stored column; drop the stored `ar_cards.is_unlocked`/`Animal.is_unlocked` columns only after cutover is verified.
5. App: payment-trust polling, unlock-success gating.
6. Backoffice: Products/Package-Items/Orders admin UI.
7. Dead code removal (backend + backoffice) + fix the 3 pre-existing failing tests + new test coverage.
8. Cross-repo QA per `tasks.md` §12.

No rollback beyond standard migration `down` scripts is planned; this is pre-launch MVP work, not a live-traffic migration.

## Open Questions

- None blocking. Worksheets scope-out and blanket-subscription-access are documented decisions above, not open items.

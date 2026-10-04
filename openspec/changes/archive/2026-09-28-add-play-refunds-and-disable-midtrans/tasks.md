## 1. Backend: turn Midtrans off by default
- [x] 1.1 Migration (next free `V` number, after V57): seed `app_feature_flags` `alternative_billing` ("Midtrans (alternative billing)") with `is_enabled = false` *`V58__add_alternative_billing_flag.sql`.*
- [x] 1.2 Gate `POST /payment/create` and `POST /payment/create-product`: return 403 `{"code":"ALTERNATIVE_BILLING_DISABLED"}` while the flag is off. Leave the webhook, `SyncOrderStatus` and admin sync open. Tests: flag off gives 403 and no order is created; flag on keeps today's behaviour *The gate runs before any other checks and fails closed on a DB error. The existing renewal-window API test now turns the flag on first. `/user/:id` also reports `can_renew = false` for Midtrans subscriptions while the flag is off (see design §1).*
- [x] 1.3 Update `openapi.yaml` (the 403 on both endpoints)

## 2. Backend: Google Play refunds
- [x] 2.1 Migration: create `order_refunds` per design §3, including CHECK constraints and the partial unique index on active refunds per order *`V59__create_order_refunds.sql` (with the CHECK that an ADMIN refund has a reason and an admin).*
- [x] 2.2 `GooglePlayVerifier`: add `RefundOrder(playOrderID, revoke)`, `RevokeSubscription(token, prorated bool)` and `GetOrder(playOrderID)` (the fields in design §3). Add them to the verifier interface and the fake, and extend `fixtures.FakePlay` to serve them *Methods `RefundOrder`, `RevokeSubscriptionPurchase` and `GetOrder`. `fixtures.FakePlay` gained refund/revoke/orders.get handling, `RefuseRefund`, `AlreadyRefunded`, `OrderTotal`, and `AcceptPurchasesWithPrefix` (used by the held e2e stack).*
- [x] 2.3 `PaymentService.RefundPlayOrder(orderID, adminID, reason, refundType)` per design §2 (preconditions, REQUESTED → Google → transactional REFUNDED + revoke + SUCCEEDED, or FAILED), then fill amounts from `orders.get` (best effort). Add `SyncRefundDetails(refundID)` *In `services/refund_service.go`. **Bug found and fixed:** `RevokeEntitlementForOrder` stamped `expires_at` with the app server's clock while `HasEntitlement` compares against the database's `NOW()`, so a revoked entitlement stayed active whenever the app clock ran ahead. It now uses `NOW()`. `RevokeSubscription` keeps the app clock, because subscriptions are checked in Go and a revoked one is also `free`.*
- [x] 2.4 Record `GOOGLE_VOIDED` rows from `reconcileVoidedPurchase` (with voided source and reason) and `GOOGLE_RTDN` rows from `SUBSCRIPTION_REVOKED`, but only when the order actually moves to `REFUNDED` *A shared `revokeOrderAccess` helper. RTDN `SUBSCRIPTION_REVOKED` now also moves a still-PAID order to `REFUNDED` (EXPIRED only revokes).*
- [x] 2.5 Admin endpoints: `POST /admin/orders/:id/refund` `{reason, refund_type}` (400 missing or short reason or `PRORATED` on a one-time order; 409 not refundable or already refunded; 502 with Google's message on a Google failure), `GET /admin/orders/:id/refunds`, and `POST /admin/order-refunds/:id/sync`. Record `adminID` from the admin JWT. Add `refund_count` to the admin order list *The admin list also returns `package_type`, so the backoffice knows when to offer Prorated.*
- [x] 2.6 Tests:
  - unit: each branch of the refund service (one-time vs subscription, full vs prorated, Google failure leaves the order `PAID`, Google says "already refunded", concurrent refund blocked, orders.get failure still succeeds)
  - handler: status codes
  - API: refunding a Play order revokes access and records the refund, against FakePlay
  - DB: constraints and the unique index
  - e2e: admin refunds a Play purchase, the user loses access, and a refund row exists *Covered through the real router and DB (`tests/api/refund_test.go`) rather than sqlmock, plus DB constraint tests and 2 e2e flows. The existing sqlmock tests now assert the refund-record inserts.*
- [x] 2.7 Update `openapi.yaml`. Run gofmt, golangci-lint, `go test -race` with coverage, and the ratchet

## 3. Backoffice
- [x] 3.1 API client: `ordersApi.refund(id, {reason, refund_type})`, `ordersApi.refunds(id)`, `orderRefundsApi.sync(id)`, plus `OrderRefund` types and `refund_count` on `Order`. Sync the vendored `openapi.yaml`
- [x] 3.2 Orders page: the "Refund" button (only on PAID Google Play orders with a token), and the modal per design §4 (summary, Full/Prorated for subscriptions, required reason at least 10 characters, required confirmation checkbox, Google's error message on failure)
- [x] 3.3 Orders page: a "Refunds" link and drawer listing every refund row, with the "Sync refund details" action
- [x] 3.4 Tests: page tests (button visibility rules, validation, payload, error display, history drawer) and API client tests. Add a Playwright spec that refunds a seeded Play order against the e2e stack's FakePlay. Run lint, typecheck, tests and the ratchet *Playwright `e2e/order-refunds.spec.ts` buys a card through the held stack (any `e2e-hold-` token counts as a Play purchase), refunds it in the UI, and checks that access is removed and the history is recorded. All 6 specs pass.*

## 4. App: no Midtrans while the flag is off
- [x] 4.1 Feature flags: treat `alternative_billing` as off when it's missing or the backend is unreachable (fail closed, unlike the other flags)
- [x] 4.2 `GooglePlayBillingService`: enable User Choice Billing only when the flag is on
- [x] 4.3 Payment screen and `PaymentOptionsCubit`, while the flag is off:
  - hide packages without `playProductId`
  - show "Belum tersedia di perangkat ini" and no Bayar button for a single product without one
  - on iOS and web, show the purchase-unavailable state
  - never call `/payment/create*` or open the Midtrans webview
  - map a 403 `ALTERNATIVE_BILLING_DISABLED` to the unavailable state *Stricter than planned (design §1): only Play-mapped items are purchasable regardless of the flag, and Midtrans is only reachable through Google Play's choice screen. The summary also drops the promo line for an item that can't be bought.*

  With the flag on, today's behaviour is kept (Midtrans on Android only).
- [x] 4.4 Tests: cubit and widget tests (flag off: unmapped options hidden, unavailable state, no Midtrans request; flag on: current behaviour), billing service (no `setBillingChoice` while off), and the feature-flag default. Update `purchase_flow_test.dart` if needed. Run analyze, tests and the ratchet, then run the integration flows on the emulator

## 5. Validation
- [x] 5.1 On the emulator against the e2e stack, with the flag off: a Play-mapped item buys through Play only, an unmapped item isn't offered, and no Midtrans screen appears. In the backoffice, refund that purchase: the order becomes REFUNDED, the app loses access, and the refund appears in the history with its amount *On the Pixel 9a emulator against the e2e stack: all 5 flow files (11 tests) pass with the flag off. The screenshots show the unmapped card marked "Belum tersedia", only Play-mapped packages listed, and Bayar only for a mapped package. The refund half was verified through Playwright plus the backend e2e flow (access removed, refund recorded), not tapped on the device, because FakeBilling can't create a backend Play order.*
- [x] 5.2 `openspec validate add-play-refunds-and-disable-midtrans --strict`

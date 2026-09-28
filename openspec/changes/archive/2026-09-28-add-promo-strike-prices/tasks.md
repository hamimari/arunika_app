## 1. Backend: rules and computation (`promo-strike-price`), do first
- [x] 1.1 Migration `V56__add_strike_price_rules.sql`: create `strike_price_rules` (seeded with `AR_CARD`/`DONGENG`/`PACKAGE` = `NONE`/0) and `starts_at`/`ends_at` columns, and add nullable `strike_mode`/`strike_value`/`strike_starts_at`/`strike_ends_at` to `products` and `premium_packages`, with CHECK constraints (valid mode, end date required unless `NONE`)
- [x] 1.2 Add a `models/strike_price_rule.go` model, and add the override fields to `models/product.go` and `models/premium_package.go`
- [x] 1.3 Add `services/strike_price_service.go` with the pure `ComputeStrikePrice` function and a per-request rule loader/resolver. Unit tests cover the percent rounding (39000 at 20% → 49000), fixed amounts, `NONE`, price 0, override precedence, override `NONE` opting out, the period window (not started, active, ended at exactly `ends_at`), and an expired override falling back to the global rule
- [x] 1.4 Add `strike_price_idr`/`discount_percent`/`promo_ends_at` to the AR card responses (`ar_service.go`, `models/ar_cards.go`), the dongeng responses (`dongeng_service.go`) and `GET /premium/packs` (`premium_pack_service.go`), loading rules once per request
- [x] 1.5 Add admin endpoints `GET /admin/strike-price-rules` and `PUT /admin/strike-price-rules/:scope` (handler, service, routes, validation: 404 for an unknown scope; 400 for an out-of-range value, a missing or past end date, an end before the start, or a period over 90 days; response includes the status ACTIVE/SCHEDULED/ENDED/OFF)
- [x] 1.6 Extend `PUT /admin/products/:id` and `PUT /admin/premium/packs/:id` (plus package create) with `strike_mode`/`strike_value`/`strike_starts_at`/`strike_ends_at` (same validation), and include the override, effective strike price and `promo_ends_at` in admin list responses
- [x] 1.7 Update `openapi.yaml`. Add handler/API tests and contract tests for the new fields and endpoints. Add a test that the order amount is still `price_idr` when a strike price exists
- [x] 1.8 Migration: add `provider` (`midtrans` | `google_play`) to `user_subscriptions`. Backfill `provider = 'google_play'` and `auto_renew = true` for subscriptions whose latest PAID subscription order is a Play order; everything else gets `midtrans`
- [x] 1.9 `entitlement_service.go`: set `provider` in `upsertSubscription` (from the order) and in `SyncSubscriptionExpiry` (`google_play`). Add tests that the existing stacking (`computeSubscriptionExpiry`) behaves as specified: stacks from a future expiry, restarts from now when lapsed, and switches `package_id` on a plan change
- [x] 1.10 Play auto-renew tracking: set `auto_renew` from `autoRenewing` on subscription verification; handle RTDN `SUBSCRIPTION_CANCELED` (set to false, keep access) and set it to true on RESTARTED/RENEWED/RECOVERED. Tests for each notification
- [x] 1.11 Add `RenewalWindowDays = 7`, a `CanRenew`/`RenewableFrom` helper, and `provider`/`auto_renew`/`renewable_from`/`can_renew` on the profile `subscription` object (`handlers/user_handler.go`). Tests at the window boundary (day −8, −7, −1) and for auto-renewing subscriptions
- [x] 1.12 Active-subscription guard (`monetization-orders-payments`): return 409 `SUBSCRIPTION_ACTIVE` from `POST /payment/create`, `POST /payment/create-product` and the Play Billing order/verify entry before any order is created. The exception is a subscription-package order via `/payment/create` when `can_renew` is true and `provider ≠ google_play`. Tests: product → 409; too-early renewal → 409; renewal in the window → 201; content package in the window → 409; Play-provider subscription → 409; expired → 201; RTDN renewal unaffected. *Done as a check the handlers call before any order is created, on `/payment/create`, `/payment/create-product`, `/payment/play/create` and `/payment/play/create-product`. `/payment/play/verify` needs no guard because it only settles an order one of those created. The decision table is tested in `services/subscription_renewal_test.go` and `tests/db/strike_price_test.go`.*
- [x] 1.13 Run `go test ./...`

## 2. Backoffice (depends on 1.5–1.6)
- [x] 2.1 API clients for the strike-price rules. Extend the product and package client types
- [x] 2.2 `pages/settings/StrikePricePage.tsx` ("Harga Coret") with three scope cards, a mode select, a value input, a WIB promo period `RangePicker` (end required, capped at 90 days), a status tag and a preview. Add the route and sidebar entry under Settings. *The sidebar has no Settings group, so "Harga Coret" sits next to "App Features". The picker uses `needConfirm={false}` so a typed date commits without an extra OK click (found by the e2e test).*
- [x] 2.3 Add a "Harga coret" selector, value input, period picker and live preview to the Product edit modal and the Package modal. Add a "Harga coret" column (strike price + end date) to both tables
- [x] 2.4 Unit tests for the preview formula and form validation (end date required, 90-day cap). Add an e2e test that saves a global rule and a package override. *`e2e/strike-prices.spec.ts` passes against the e2e stack's API.*

## 3. App: models and shared widget (can start in parallel with 2 once 1.4's contract is fixed)
- [x] 3.1 Add nullable `strikePriceIdr`/`discountPercent`/`promoEndsAt` to `ArCardResponse`, `DongengResponse`, `PremiumPack.fromJson` and `PurchasableItem`, including the `fromPackage`/`fromProduct` factories and `goToProductPurchase`
- [x] 3.2 Add a shared `PriceTag` widget (price, crossed-out strike price, optional `-N%` pill, optional "Promo s/d …" caption), with widget tests
- [x] 3.3 Unit tests for the model JSON mapping with and without the strike fields

## 4. App: list screens
- [x] 4.1 Koleksi (`collection_screen.dart`): show the `PriceTag` on locked cards that have a price
- [x] 4.2 Dongeng list (`new_dongeng_list_screen.dart`): show the `PriceTag` on locked paid dongeng
- [x] 4.3 Premium upgrade screen: use the `PriceTag` with the discount badge and the promo end caption on package cards

## 5. App: payment page redesign
- [x] 5.1 Remove the Midtrans / Google Play info note and the "Ingin lebih hemat?" link-out
- [x] 5.2 Add a "Pilih paket" option list: the entry product (when it's a product) plus all active packages via `PremiumPackRepository.fetchPacks()`, with the entry item preselected, a loading skeleton and a failed-load retry row
- [x] 5.3 Add a sticky bottom summary (name, crossed-out strike price, "Hemat Rp X · Promo s/d …", Total, Bayar Sekarang; no "Harga normal" label) driven by the selected option
- [x] 5.4 Route `_onPayPressed`, `_startPayment` and the Play Billing path, plus the `/unlock-success` extra, through the selected `PurchasableItem`. Lock selection while loading
- [x] 5.5 Widget tests: switching the option updates the total; pay uses the selected package; the package load failure fallback works; no "Midtrans" text is rendered
- [x] 5.6 Update the Patrol/integration payment flow tests that referenced the old layout. Run `flutter analyze` and `flutter test`. *`purchase_flow_test.dart` now taps the pay button by its label. Added `integration_test/flows/pricing_flow_test.dart`, plus opt-in screenshots via `--dart-define=SAVE_SCREENSHOTS=true`.*

## 6. App: active subscribers and renewal (depends on 1.11–1.12)
- [x] 6.1 Add `provider`, `autoRenew`, `renewableFrom` and `canRenew` to `SubscriptionInfo`, with JSON tests
- [x] 6.2 Add a shared `ActiveSubscriptionView` ("Langganan aktif", plan name, "Berlaku sampai …" or "Diperpanjang otomatis pada …", Kembali)
- [x] 6.3 `/premium`: show `ActiveSubscriptionView` when subscribed and `!canRenew`. Keep `subscriptionOnly` mode as the renewal entry, and add the banner "Masa aktif baru ditambahkan mulai {expiry}"
- [x] 6.4 Profile membership card: show "Perpanjang" only when `canRenew`. For a Midtrans subscription it opens `/premium` (subscription only); for a Play subscription it opens the Google Play subscription page via `url_launcher`
- [x] 6.5 Payment page: show `ActiveSubscriptionView` when subscribed and `!canRenew`. In the renewal window, show only subscription packages with the current plan preselected, and a summary line "Aktif sampai {old} → {old + duration}" that updates when the plan changes. Map a 409 `SUBSCRIPTION_ACTIVE` to `ActiveSubscriptionView`
- [x] 6.6 Widget tests: outside the window, no packages or prices; an auto-renewing Play subscriber sees the auto-renew text; inside the window, subscription packages only and a correct stacked end date that updates on plan switch; a Play subscriber in the window opens Play instead of paying; a 409 shows the subscriber state; an expired subscriber sees packages

## 7. Validation
- [x] 7.1 Manual check on an Android emulator: set rules in the backoffice and confirm the lists, the premium screen and the payment page reflect them. Confirm the charged amount is unchanged, and that the strike price disappears after the promo end time. Log in as a subscriber: outside the window, no prices, packages or Bayar button appear; with `expires_at` moved to 5 days out, renewing adds the period from the old expiry date. *Done as an automated run on the Pixel 9a emulator against the e2e stack instead of by hand. `pricing_flow_test.dart` sets a rule through the admin API and confirms the Koleksi price chip, the payment options, the total changing on switch, and the subscriber state, with screenshots reviewed. All 5 integration flow files pass. Not re-checked on the emulator: a promo expiring (covered by backend period tests), the charged amount (covered by `tests/db` and the payment screen test's request body), and a 5-days-out renewal (covered by backend stacking tests plus the cubit and widget tests).*
- [x] 7.2 `openspec validate add-promo-strike-prices --strict`

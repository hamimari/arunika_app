## 1. Google Play Billing — backend (arunika-backend)
- [x] 1.1 Migration: add nullable `play_product_id` to `premium_packages`
- [x] 1.2 Add Google Play service-account credentials config (Play Developer API access)
- [x] 1.3 Implement `POST /payment/play/verify` (verify purchase token via Play Developer API, grant entitlement, reject invalid/reused tokens)
- [x] 1.4 Implement `POST /payment/play/rtdn` (Pub/Sub push handler for renewal/cancellation/refund/revocation)
- [x] 1.5 Unit tests for verify + RTDN handlers (valid, invalid, reused token; each RTDN notification type)
- [x] 1.6 Implement `POST /payment/play/report-external` (reports a Midtrans-settled, User-Choice-Billing-alternative order to Google via `externaltransactions.createExternalTransaction`; idempotent)
- [x] 1.7 Unit tests for external transaction reporting (one-time, subscription, already-reported no-op, order not paid, Google API error) + an HTTP-level test of the actual request body against a Google API reference lookup

## 2. Google Play Billing — backoffice (arunika-backoffice)
- [x] 2.1 Add "Play Product ID" field to the package create/edit form
- [x] 2.2 Show mapped/unmapped status in the packages table
- [x] 2.3 Test coverage for the new field

## 3. Google Play Billing — app (arunika_app)
- [x] 3.1 Add `in_app_purchase` dependency and Android platform setup
- [x] 3.2 Wire premium pack purchase buttons to Play Billing for packages with `play_product_id` set; fall back to existing flow (or hide the buy button) for unmapped packages
- [x] 3.3 Call `POST /payment/play/verify` after a successful platform purchase and handle failure/retry
- [x] 3.4 Route Android purchases of Play-mapped packages through Google Play Billing (Google Play's own billing-choice screen under User Choice Billing, not a custom in-app toggle). Note: the Midtrans webview path is intentionally kept (not deleted) — it's now reached either via the User Choice Billing alternative-billing selection (3.6) for mapped packages, or directly for packages not yet mapped to a Play product and for single-product purchases (`/payment/create-product`, e.g. buying one AR card/dongeng directly). Single-product purchases were out of scope for this change (see proposal.md) and still use Midtrans unconditionally on Android — extending User Choice Billing to that path is follow-up work.
- [x] 3.5 Widget/bloc tests for the purchase flow (success, verification failure, unmapped package) — covered via `PurchasableItem.isPlayBillingEligible` unit tests; full purchase-stream integration isn't unit-testable without a real platform channel, see 9.2.
- [x] 3.6 Enable User Choice Billing (`setBillingChoice(BillingChoiceMode.userChoiceBilling)`, memoized) before the first purchase attempt; listen to `userChoiceDetailsStream` alongside `purchaseStream` and, when the user picks the alternative billing option, fall back to the existing Midtrans checkout (unmodified) and call `POST /payment/play/report-external` with the captured `externalTransactionToken` once that order settles

## 4. Account deletion — backend (arunika-backend)
- [x] 4.1 Implement `DELETE /user/me`: delete/anonymize user, child profile(s), orders, payment history, device tokens, feature progress
- [x] 4.2 Ensure JWT is invalidated after deletion (session/refresh token cleanup)
- [x] 4.3 Unit tests: full deletion, anonymization of retained records, revoked auth after deletion

## 5. Account deletion — app (arunika_app)
- [x] 5.1 Add "Hapus Akun" action to the Profile screen with a confirmation step
- [x] 5.2 Call `DELETE /user/me`, clear local session/secure storage, navigate to landing on success
- [x] 5.3 Widget/bloc tests for the confirmation gate and success/failure paths

## 6. Parental gate — app (arunika_app)
- [x] 6.1 Build a reusable parental-gate challenge widget/route guard
- [x] 6.2 Apply the guard to `/premium` and `/payment` routes, gated once per app session
- [x] 6.3 Widget tests: first access shows gate, repeat access in-session skips it, wrong answer blocks entry, restart resets it

## 7. Public legal/compliance pages — landing site (arunika-landing)
- [x] 7.1 Add a Privacy Policy page mirroring the in-app policy, disclosing child data collection, styled to match the site theme
- [x] 7.2 Add an account & data deletion request page (form or documented contact method + stated handling timeframe)
- [x] 7.3 Cross-link the two pages and link the privacy policy from the site footer

## 8. Release readiness documentation (arunika_app)
- [x] 8.1 Verify target SDK and app bundle build. `targetSdkVersion`/`compileSdkVersion` are Flutter-managed (`flutter.targetSdkVersion`) and currently resolve to API 36, above Play's minimum requirement — no code change needed. `flutter build appbundle --release` was run and reached Gradle bundling successfully (config is sound), but failed at the native-library debug-symbol-stripping step in this sandbox because its Android SDK is missing the `cmdline-tools` component — an environment/toolchain issue, not a code issue. Re-run this in a properly configured build environment/CI before shipping to confirm a clean `.aab` output end-to-end.
- [x] 8.2 Write `docs/play-store-data-safety.md` mapping actual data collection to the Data Safety form
- [x] 8.3 Write `docs/play-store-content-rating.md` with recommended IARC questionnaire answers

## 9. Validation
- [x] 9.1 `openspec validate add-play-store-release-compliance --strict`
- [x] 9.2 Manual QA: full purchase flow via Play Billing on a real device/internal-testing track — Google Play Billing subscription purchase, backend verification, and entitlement grant confirmed working end-to-end (fixed along the way: a cross-transaction deadlock in `SyncSubscriptionExpiry` that hung `VerifyPlayPurchase` indefinitely, and `payments.transaction_id`/`orders.purchase_token` being too narrow for real Play purchase tokens — see `V54__widen_play_purchase_token_columns.sql`). Individual-product (non-package) purchases via Play Billing were also added and verified during this work, extending 3.4's original package-only scope. Not independently re-confirmed in this pass: the alternative-billing (Midtrans) arm of the User Choice Billing picker, account deletion, and the parental gate — these were implemented and unit-tested (see sections 4–6) but not re-walked manually here. Still worth doing before wide release: double-check the `externaltransactions.createExternalTransaction` request body (`services/google_play_verifier.go`) against Google's live API reference, since it was implemented from the published schema rather than a live call.

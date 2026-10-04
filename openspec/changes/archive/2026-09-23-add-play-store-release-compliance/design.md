# Design

## Context
This change spans three repositories (`arunika_app`, `arunika-backend`, `arunika-landing`) and touches payments, account data, and store-listing content. Design decisions are grouped by concern below.

## Google Play Billing

**Client**: use the official `in_app_purchase` Flutter plugin (wraps the Play Billing Library) for Android. It covers both one-time ("content" pack) and auto-renewing ("subscription") products through one API.

**Product mapping**: add a nullable `play_product_id` column to `premium_packages` so each backend package can be mapped to a Play Console in-app product/subscription SKU from the backoffice. Packages without a mapping are simply not purchasable via Play Billing yet (backoffice-driven rollout, no big-bang cutover required).

**Purchase flow**:
1. App calls `InAppPurchase.instance.buyNonConsumable`/subscription purchase with the mapped `play_product_id`.
2. On completion, the app calls a new `POST /payment/play/verify` with `{purchase_token, product_id, order_id}`.
3. Backend verifies the token against the Google Play Developer API (`purchases.products.get` / `purchases.subscriptions.get`) using a service-account credential, then grants entitlement — mirroring how `/payment/webhook` grants entitlement today after Midtrans confirms.

**Renewals/cancellations**: subscribe to Real-time Developer Notifications (RTDN) via a Pub/Sub push endpoint (`POST /payment/play/rtdn`) so subscription state changes (renewal, cancellation, refund, revocation) update entitlements without requiring the app to be open.

**User Choice Billing**: Arunika is enrolled in Play Console's User Choice Billing program, so Midtrans is offered as a real alternative to Google Play Billing rather than being cut off from the app's own purchase buttons:
1. Before the first purchase attempt, the app switches the underlying `BillingClient` into User Choice Billing mode (`InAppPurchaseAndroidPlatformAddition.setBillingChoice(BillingChoiceMode.userChoiceBilling)`, memoized — reconnecting the client is slow enough that this is done once, not per purchase).
2. The purchase is launched exactly as before (`buyNonConsumable`). Google Play itself decides whether to show its own billing-choice selection screen; the app doesn't render or control it.
3. If the user picks **Google Play**, the existing `purchaseStream` → `POST /payment/play/verify` flow completes as designed above.
4. If the user picks **the alternative (Midtrans)**, the platform plugin's `userChoiceDetailsStream` fires instead, carrying an `externalTransactionToken` and the product being purchased — no Play purchase happens. The app then falls back to the **existing** Midtrans checkout (`POST /payment/create` → Snap webview → poll `GET /orders/:id`) completely unmodified; the only addition is that once the Midtrans order is confirmed `PAID`, the app calls a new `POST /payment/play/report-external` with the order id and the captured `externalTransactionToken`.
5. The backend reports that transaction to Google via the Android Publisher API's `externaltransactions.createExternalTransaction` (required under User Choice Billing so Play can compute its reduced service fee on alternative-billing transactions), using the order's package price/type to build the request (`oneTimeTransaction` for a content pack, `recurringTransaction` with `subscriptionType: RECURRING` for a subscription), and records an audit `Payment` row (`payment_type: google_play_external_report`) so a retried report is a no-op.

This means Midtrans is not "removed" from the Android purchase buttons at all — it is now reached exclusively through Google's own billing-choice screen rather than being the app's default/only path, which is what keeps it Play Payments Policy-compliant while still being a real, working alternative.

**Not implemented in this change**: reporting *refunds* of alternative-billing transactions to Google (a separate `externaltransactions.refundexternaltransaction` call) — Arunika has no refund flow today for any payment method, so there is nothing to wire this into yet; revisit if/when refunds are supported.

**iOS**: out of scope for this change; a StoreKit equivalent (with Apple's own external-payment rules) would be a separate future change if/when an App Store release is planned.

## Account Deletion

**Backend**: `DELETE /user/me` (JWT-authenticated). Deletes or anonymizes: the user row, child profile(s), order history, payment history, device/push tokens, and per-feature progress (tracing, counting, badges). Where legally-relevant transaction records must be retained (e.g. for accounting), they are anonymized (user reference removed) rather than deleted outright — this matches Play's "delete or anonymize" language for data without a legal retention requirement.

**App**: Profile screen gets a destructive "Hapus Akun" action, a confirmation step (re-enter password or typed confirmation, to avoid accidental deletion by a child), then calls the endpoint, clears local session/secure storage, and returns to the landing/signup screen.

**Web**: a new page on arunika-landing (e.g. `/hapus-akun`) that does not require installing the app or logging in. Play accepts a request-based (non-instant) deletion flow as long as it's honored, so the page can be a short form or a `mailto:` to a monitored support address, explaining the request will be processed and data deleted within a stated window. Linked from the privacy policy page.

## Parental Gate

A lightweight one-time-per-app-session challenge (e.g. "what is 4 × 3?" or a press-and-hold) shown before the premium/purchase screen is reachable. Implemented once as a reusable widget/route guard applied at the `/premium` and `/payment` route entry points, not per individual product — simplest implementation that satisfies the Families Policy requirement without repeated friction within the same session. Resets on app restart.

## Release Readiness Documentation

- `docs/play-store-data-safety.md`: maps every data type Arunika actually collects today (parent name/email, child name/birthdate, device identifiers via Firebase Messaging, crash diagnostics via Crashlytics, purchase history) to the Play Console Data Safety form's categories (collected vs. shared, purpose, optional vs. required, encrypted in transit, user-deletable), so the console form is filled from a verified source instead of guesswork.
- `docs/play-store-content-rating.md`: recommended IARC questionnaire answers based on actual app content (no violence, no user-generated content or chat, educational content for children).
- Target API level / App Bundle: verify `flutter build appbundle` succeeds and that the resulting `targetSdkVersion` meets Play's minimum target API requirement at the time of release (Play's minimum shifts roughly yearly, so this is a verification task at release time rather than a hardcoded version pinned in the spec).

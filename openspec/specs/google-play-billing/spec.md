# google-play-billing Specification

## Purpose
TBD - created by archiving change add-play-store-release-compliance. Update Purpose after archive.
## Requirements
### Requirement: Premium packages can be mapped to a Google Play product
The `premium_packages` table SHALL have a nullable `play_product_id` column. The backoffice package form SHALL let an admin set this value, mapping a backend package to a Google Play Console in-app product or subscription SKU. A package with no `play_product_id` set SHALL NOT be purchasable via Google Play Billing.

#### Scenario: Admin maps a package to a Play product
- **WHEN** an admin sets `play_product_id` on a package to `"pack_dongeng_bundle_1"` and saves
- **THEN** the package's stored `play_product_id` SHALL be `"pack_dongeng_bundle_1"` and it SHALL become purchasable via Google Play Billing in the app

#### Scenario: Unmapped package is not offered via Play Billing
- **WHEN** a package has `play_product_id = null`
- **THEN** the app's purchase button for that package SHALL NOT attempt a Google Play Billing purchase

### Requirement: Android app purchases premium packages through Google Play Billing with User Choice Billing
On Android, tapping "buy" on a mapped premium package SHALL initiate a purchase (via the platform in-app purchase API) for its `play_product_id` under Google Play's User Choice Billing program, which lets Google Play present the user a choice between paying with Google Play or with Arunika's alternative billing (Midtrans) in a Google-rendered selection screen, instead of unconditionally opening a Midtrans checkout webview.

#### Scenario: User buys a content pack via Google Play
- **WHEN** a user taps "buy" on a mapped `type: content` package and selects Google Play in the billing choice screen
- **THEN** the Google Play purchase sheet SHALL open for that package's `play_product_id`

#### Scenario: User buys a subscription via Google Play
- **WHEN** a user taps "buy" on a mapped `type: subscription` package and selects Google Play in the billing choice screen
- **THEN** the Google Play subscription purchase flow SHALL open for that package's `play_product_id`

#### Scenario: User picks the alternative billing option
- **WHEN** a user taps "buy" on a mapped package and selects the alternative billing option in the billing choice screen
- **THEN** the app SHALL fall back to the existing Midtrans checkout webview for that purchase, using the same order-confirmation flow as any other Midtrans purchase

### Requirement: Alternative billing purchases are reported to Google
When a user completes a purchase via the alternative (Midtrans) billing option under User Choice Billing, the backend SHALL report that transaction to Google via the Android Publisher API's external transaction reporting endpoint once the Midtrans order is confirmed paid, so Google can calculate its service fee. Reporting SHALL be idempotent — reporting the same order twice SHALL NOT create a duplicate report or error.

#### Scenario: Midtrans purchase is reported after settlement
- **WHEN** a Midtrans order originating from a user's alternative-billing choice is confirmed `PAID`
- **THEN** the backend SHALL report the transaction to Google, including the external transaction token captured from the billing choice screen

#### Scenario: Reporting a subscription package sets the recurring transaction type
- **WHEN** the paid order's package has `type: subscription`
- **THEN** the report to Google SHALL be submitted as a recurring transaction rather than a one-time transaction

#### Scenario: Re-reporting an already-reported order is a no-op
- **WHEN** the backend is asked to report an order that has already been successfully reported to Google
- **THEN** it SHALL NOT call the Google API again and SHALL return success

### Requirement: Backend verifies Google Play purchases before granting entitlement
The backend SHALL expose an authenticated `POST /payment/play/verify` endpoint accepting `{purchase_token, product_id, order_id}`. It SHALL verify the purchase against the Google Play Developer API before granting entitlement, and SHALL reject a purchase token that fails verification or was already consumed by a different order.

#### Scenario: Valid purchase grants entitlement
- **WHEN** `POST /payment/play/verify` is called with a purchase token that the Google Play Developer API confirms as purchased/active
- **THEN** the corresponding order SHALL be marked paid and the user SHALL be granted entitlement to the package

#### Scenario: Invalid or reused token is rejected
- **WHEN** `POST /payment/play/verify` is called with a purchase token that fails Play verification, or that has already been applied to a different order
- **THEN** the request SHALL be rejected and no entitlement SHALL be granted

### Requirement: Subscription state changes are reconciled via Real-time Developer Notifications
The backend SHALL expose a `POST /payment/play/rtdn` endpoint that accepts Google Play Real-time Developer Notifications (via Pub/Sub push) and updates the affected subscription's entitlement state on renewal, cancellation, refund, or revocation, without requiring the app to be open.

#### Scenario: Subscription renews
- **WHEN** an RTDN `SUBSCRIPTION_RENEWED` notification is received for an active subscription
- **THEN** the subscription's entitlement expiry SHALL be extended accordingly

#### Scenario: Subscription is revoked
- **WHEN** an RTDN `SUBSCRIPTION_REVOKED` notification is received
- **THEN** the user's entitlement for that subscription SHALL be revoked immediately

### Requirement: Subscription auto-renew state and provider are tracked
The backend SHALL record `user_subscriptions.provider = 'google_play'` whenever it grants or syncs access from a Google Play subscription. It SHALL maintain `user_subscriptions.auto_renew` as follows:
- set from Play's `autoRenewing` when a subscription purchase is verified
- set to false on RTDN `SUBSCRIPTION_CANCELED`
- set to true on `SUBSCRIPTION_RESTARTED`, `SUBSCRIPTION_RENEWED` and `SUBSCRIPTION_RECOVERED`

A cancellation SHALL NOT end access before `expires_at`. A one-off migration SHALL set `provider = 'google_play'` and `auto_renew = true` for existing subscriptions whose latest `PAID` subscription order has `provider = 'google_play'`.

#### Scenario: User cancels auto-renew in Google Play
- **WHEN** an RTDN `SUBSCRIPTION_CANCELED` notification is received for an active subscription
- **THEN** `auto_renew` SHALL become false, access SHALL continue until `expires_at`, and the subscription SHALL become renewable within 7 days of expiry

#### Scenario: User resubscribes in Google Play
- **WHEN** an RTDN `SUBSCRIPTION_RESTARTED` notification is received
- **THEN** `auto_renew` SHALL become true, and the current `expires_at` SHALL be kept


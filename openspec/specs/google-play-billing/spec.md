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
On Android, tapping "buy" on a mapped premium package SHALL initiate a purchase (via the platform in-app purchase API) for its `play_product_id` through Google Play Billing. Google Play's User Choice Billing, which presents a choice between Google Play and Arunika's alternative billing (Midtrans), SHALL be enabled only while the `alternative_billing` feature flag is on. While the flag is off, the app SHALL NOT enable User Choice Billing, so Google Play's own purchase sheet is the only payment path.

#### Scenario: User buys a content pack via Google Play
- **WHEN** a user taps "buy" on a mapped `type: content` package
- **THEN** the Google Play purchase sheet SHALL open for that package's `play_product_id`

#### Scenario: User buys a subscription via Google Play
- **WHEN** a user taps "buy" on a mapped `type: subscription` package
- **THEN** the Google Play subscription purchase flow SHALL open for that package's `play_product_id`

#### Scenario: No billing choice while alternative billing is off
- **WHEN** the `alternative_billing` flag is off and a user starts a purchase
- **THEN** the app SHALL NOT enable User Choice Billing, and no alternative billing option SHALL be offered

#### Scenario: User picks the alternative billing option
- **WHEN** the `alternative_billing` flag is on, and a user taps "buy" on a mapped package and selects the alternative billing option in the billing choice screen
- **THEN** the app SHALL fall back to the Midtrans checkout webview for that purchase, using the same order-confirmation flow as any other Midtrans purchase

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

### Requirement: Admins can refund a Google Play order
The backend SHALL expose `POST /admin/orders/:id/refund` with body `{reason, refund_type}` (admin JWT). It SHALL accept only a `PAID` order with `provider = google_play`, a purchase token and a creation date less than 3 years ago. `reason` SHALL be required and at least 10 characters.
- A one-time order (product or content package) SHALL be refunded with the Android Publisher `orders.refund` call on its Play order id, with `revoke=true`. `refund_type` SHALL be `FULL`.
- A subscription order SHALL be refunded with `purchases.subscriptionsv2.revoke` on its purchase token, using `fullRefund` for `FULL` or `proratedRefund` for `PRORATED`.

On success, the order SHALL become `REFUNDED` and the access it granted SHALL be revoked immediately. On a Google failure, the order SHALL stay `PAID` and the error SHALL be returned. A second refund of the same order SHALL be rejected.

#### Scenario: Refunding a one-time purchase
- **WHEN** an admin refunds a `PAID` Google Play order for a single AR card with a valid reason
- **THEN** `orders.refund` SHALL be called with `revoke=true`, the order SHALL become `REFUNDED`, and the user SHALL lose access to that card

#### Scenario: Prorated refund of a subscription
- **WHEN** an admin refunds a `PAID` Google Play subscription order with `refund_type = PRORATED`
- **THEN** `purchases.subscriptionsv2.revoke` SHALL be called with `proratedRefund`, the order SHALL become `REFUNDED`, and the subscription SHALL end immediately

#### Scenario: Google refuses the refund
- **WHEN** the Google API call fails
- **THEN** the order SHALL remain `PAID`, access SHALL be unchanged, and the refund SHALL be recorded as `FAILED` with Google's error

#### Scenario: Not refundable
- **WHEN** an admin tries to refund a Midtrans order, a non-`PAID` order, or an order that already has a refund in progress or completed
- **THEN** the server SHALL respond 409, and SHALL NOT call Google

#### Scenario: Reason required
- **WHEN** an admin submits a refund without a reason or with one shorter than 10 characters
- **THEN** the server SHALL respond 400 and SHALL NOT call Google

### Requirement: Every Google Play refund is recorded
The system SHALL keep an `order_refunds` record for every refund of a Google Play order: those issued by an admin (`source = ADMIN`), and those Google reports on its own through the voided-purchases API (`GOOGLE_VOIDED`) or an RTDN revocation (`GOOGLE_RTDN`). Each record SHALL hold:
- the order and the source
- the admin who issued it and the reason (for `ADMIN`)
- the refund type and whether access was revoked
- the Play order id and purchase token
- the order amount
- Google's refunded total, tax, currency, order state and refund reason (read with `orders.get`, where available)
- the voided source and reason (for `GOOGLE_VOIDED`)
- the status (`REQUESTED`, `SUCCEEDED`, `FAILED`), any error, the raw Google response, and the request and completion times

`GET /admin/orders/:id/refunds` SHALL list them. `POST /admin/order-refunds/:id/sync` SHALL re-read Google's refund details.

#### Scenario: Admin refund recorded with amounts
- **WHEN** an admin refund succeeds and `orders.get` reports the refunded total and tax
- **THEN** the order's refund record SHALL be `SUCCEEDED` with `source = ADMIN`, the admin id, the reason, and Google's refunded amounts

#### Scenario: User refunded by Google directly
- **WHEN** the voided-purchases reconcile moves a `PAID` Play order to `REFUNDED`
- **THEN** a `SUCCEEDED` refund record with `source = GOOGLE_VOIDED` and Google's voided source and reason SHALL be created

#### Scenario: No duplicate record for an admin refund Google also reports
- **WHEN** Google later reports, through the voided-purchases API, an order an admin already refunded
- **THEN** no second refund record SHALL be created

### Requirement: Single products are bought with their Google Play product id
The AR card list and detail responses and the dongeng list and detail responses SHALL include the linked product's `play_product_id` (omitted when unmapped). The app SHALL pass it to the payment screen, so a locked card or story mapped to a Google Play product can be bought through Google Play Billing. A single item without a `play_product_id` SHALL NOT be purchasable.

#### Scenario: Mapped card is purchasable
- **WHEN** an AR card's product has `play_product_id = "sku_frog"`
- **THEN** `GET /ar/cards` SHALL return `play_product_id: "sku_frog"` for that card, and the app SHALL offer "Bayar Sekarang" for it

#### Scenario: Unmapped card is not purchasable
- **WHEN** an AR card's product has no `play_product_id`
- **THEN** the response SHALL omit the field and the payment screen SHALL show "Belum tersedia di perangkat ini" for it

### Requirement: An interrupted single-product purchase is recovered
When the app reports a Google Play purchase without an order id (it was interrupted before it could), the backend SHALL find the user's most recent PENDING order for the package, or else the single product, mapped to that product id, and settle it.

#### Scenario: Recovering a single-product purchase
- **WHEN** a user's PENDING order is for a product mapped to `sku_frog`, and `POST /payment/play/verify` is called with `product_id = "sku_frog"`, a valid purchase token and no order id
- **THEN** that order SHALL be settled and the user granted the product


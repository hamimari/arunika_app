## MODIFIED Requirements

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

## ADDED Requirements

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

# monetization-orders-payments Specification

## Purpose
TBD - created by archiving change add-monetization-entitlements. Update Purpose after archive.
## Requirements
### Requirement: Orders represent purchase intent, separate from payment processing
The system SHALL have an `orders` table (`id` UUID PK, `user_id` UUID NOT NULL, `product_id` UUID NULL FK → `products.id`, `package_id` UUID NULL FK → `premium_packages.id`, `amount_idr` BIGINT NOT NULL, `status` VARCHAR NOT NULL IN `PENDING`/`PAID`/`FAILED`/`EXPIRED`, `created_at`, `updated_at`), with a `CHECK` constraint enforcing that exactly one of `product_id`/`package_id` is set.

#### Scenario: Order referencing both product and package rejected
- **WHEN** an order insert sets both `product_id` and `package_id`
- **THEN** the database SHALL reject the insert via the check constraint

#### Scenario: Order referencing neither product nor package rejected
- **WHEN** an order insert sets neither `product_id` nor `package_id`
- **THEN** the database SHALL reject the insert via the check constraint

#### Scenario: Order created in PENDING status
- **WHEN** `POST /payment/create` is called with a valid `package_id`
- **THEN** an `orders` row SHALL be created with `status = 'PENDING'` and `amount_idr` equal to the package's `price_idr`

### Requirement: Payment creation is order-first
`POST /payment/create` SHALL create an `orders` row before requesting a Midtrans Snap transaction, and SHALL derive the Midtrans `order_id` from the created order's `id`. The response SHALL include both the Midtrans `token` and the created `order_id`.

#### Scenario: Payment create returns order_id alongside token
- **WHEN** `POST /payment/create` succeeds
- **THEN** the response body SHALL contain both `token` and `order_id`, and `order_id` SHALL correspond to a `PENDING` row in `orders`

### Requirement: Payments record processing state, driven by the webhook
The system SHALL have a `payments` table (`id` UUID PK, `order_id` UUID NOT NULL FK → `orders.id`, `provider`, `provider_order_id`, `transaction_id`, `status`, `amount_idr`, `paid_at` NULL, `created_at`, `updated_at`). `POST /payment/webhook` SHALL be the only writer of payment settlement state; the Flutter client's own webview success callback SHALL NOT be trusted to grant access.

#### Scenario: Webhook creates a payment record
- **WHEN** `POST /payment/webhook` receives a valid, signature-verified Midtrans notification
- **THEN** a `payments` row SHALL be created or updated linked to the corresponding `orders` row via `provider_order_id`

#### Scenario: Invalid webhook signature rejected
- **WHEN** `POST /payment/webhook` receives a notification with an invalid signature
- **THEN** the request SHALL be rejected and no order/payment/entitlement state SHALL change

### Requirement: Settlement is idempotent
Processing the same Midtrans notification more than once SHALL NOT change order status, create duplicate payment rows, or grant duplicate entitlements. The webhook handler SHALL only transition an order from `PENDING` to `PAID` and grant entitlements once, checked within the same database transaction as the status update.

#### Scenario: Duplicate settlement notification is a no-op
- **WHEN** `POST /payment/webhook` receives a second `settlement` notification for an order that is already `PAID`
- **THEN** the order status SHALL remain `PAID`, no duplicate `payments` row SHALL be created, and no duplicate entitlement SHALL be granted

### Requirement: Order status is queryable by its owner
The system SHALL expose authenticated `GET /orders/:id`, returning the order's `id`, `status`, `product_id`/`package_id`, and `amount_idr`. The endpoint SHALL return the order only if it belongs to the requesting user, and 404 otherwise.

#### Scenario: Owner polls order status
- **WHEN** the authenticated user who created an order calls `GET /orders/:id`
- **THEN** the response SHALL include the current `status` of that order

#### Scenario: Non-owner cannot read another user's order
- **WHEN** an authenticated user calls `GET /orders/:id` for an order created by a different user
- **THEN** the response SHALL be 404

### Requirement: No new orders for active subscribers except renewals in the window
Every order-creating endpoint (`POST /payment/create`, `POST /payment/create-product`, and the Google Play Billing order/verification entry point) SHALL respond 409 with error code `SUBSCRIPTION_ACTIVE`, and SHALL NOT create an order or start a charge, when the requesting user has an active subscription (`status = 'premium'`, `expires_at` in the future). The only exception SHALL be a `subscription`-type package order via `POST /payment/create` when all of the following hold:
- the subscription is renewable (`auto_renew = false` and now ≥ `expires_at` − 7 days)
- its `provider` is not `google_play`

Google Play auto-renewals reconciled via Real-time Developer Notifications SHALL NOT be affected, because they do not create orders through these endpoints.

#### Scenario: Subscriber tries to buy a single product
- **WHEN** a user with an active subscription calls `POST /payment/create-product`
- **THEN** the server SHALL respond 409 `SUBSCRIPTION_ACTIVE` and no `orders` row SHALL be created

#### Scenario: Subscriber tries to renew too early
- **WHEN** a Midtrans subscriber whose subscription expires in 20 days calls `POST /payment/create` for a subscription package
- **THEN** the server SHALL respond 409 `SUBSCRIPTION_ACTIVE`

#### Scenario: Subscriber renews inside the window
- **WHEN** a Midtrans subscriber whose subscription expires in 5 days calls `POST /payment/create` for a subscription package
- **THEN** the order SHALL be created normally

#### Scenario: Subscriber tries to buy a content package inside the window
- **WHEN** a subscriber inside the renewal window calls `POST /payment/create` for a `content`-type package
- **THEN** the server SHALL respond 409 `SUBSCRIPTION_ACTIVE`

#### Scenario: Play subscriber cannot renew through a new order
- **WHEN** a subscriber whose subscription `provider = 'google_play'` is inside the window and attempts a new subscription order
- **THEN** the server SHALL respond 409 `SUBSCRIPTION_ACTIVE`

#### Scenario: Expired subscriber can buy
- **WHEN** a user's subscription `expires_at` is in the past and they call `POST /payment/create`
- **THEN** the order SHALL be created normally

### Requirement: Midtrans checkout is closed while alternative billing is off
While the `alternative_billing` feature flag is off, `POST /payment/create` and `POST /payment/create-product` SHALL respond 403 with code `ALTERNATIVE_BILLING_DISABLED`, and SHALL NOT create an order or a Midtrans transaction. The Midtrans webhook, order status sync and admin order sync SHALL keep working, so Midtrans orders created earlier still settle.

#### Scenario: Checkout refused while the flag is off
- **WHEN** the flag is off and a user calls `POST /payment/create-product`
- **THEN** the server SHALL respond 403 `ALTERNATIVE_BILLING_DISABLED`, and no `orders` row SHALL be created

#### Scenario: Earlier Midtrans order still settles
- **WHEN** the flag is off and a Midtrans settlement webhook arrives for an order created before
- **THEN** the order SHALL be processed as usual

### Requirement: Free content cannot be bought as a single product
The single-product order endpoints (Midtrans product checkout and Google Play product order creation) SHALL reject, with 400, a product whose linked AR card or dongeng has `is_free = true`. No order SHALL be created. Package orders are not affected.

#### Scenario: Stale client tries to buy a now-free card
- **WHEN** a client requests a Google Play product order for a product whose AR card is flagged `is_free`
- **THEN** the response SHALL be 400 with a "content is free" error, and no `orders` row SHALL be created

#### Scenario: Package containing a free item still sells
- **WHEN** a user buys a content package that includes a flagged-free item
- **THEN** the order SHALL proceed normally


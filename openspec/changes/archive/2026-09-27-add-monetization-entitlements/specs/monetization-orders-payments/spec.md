## ADDED Requirements

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

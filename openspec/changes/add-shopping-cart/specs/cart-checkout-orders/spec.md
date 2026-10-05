## ADDED Requirements

### Requirement: Orders can hold several items
The system SHALL have an `order_items` table (`order_id` FK → `orders.id`, `product_id` FK → `products.id`, `title` text, `item_type`, `normal_idr` BIGINT, `price_idr` BIGINT) with primary key `(order_id, product_id)`. `orders` SHALL gain `is_cart`, `subtotal_idr`, `charge_idr`, `price_locked_until`, `store_product_id` (FK → `store_products.id`), `idempotency_key`, `granted_at` and `consumed_at`. Order status values SHALL remain `PENDING`, `PAID`, `FAILED`, `EXPIRED` and `REFUNDED`. Because the grant runs in the same transaction that marks an order `PAID`, a cart order paid in the store but not yet granted SHALL be a `PENDING` order whose purchase token is on file; the API SHALL report it with phase `diproses`.

#### Scenario: Cart order stores items and totals
- **WHEN** an order is created from a cart of two items priced Rp 1.000 and Rp 5.000
- **THEN** the order SHALL have two `order_items` rows and `total` and `charge_idr` SHALL both be 6000

#### Scenario: Existing paid orders are backfilled
- **WHEN** the migration runs
- **THEN** every existing `PAID` or `REFUNDED` order SHALL have `granted_at` set to its `updated_at`

### Requirement: Checkout freezes the cart into an order
`POST /orders` with body `{store: "google"}` (cart) or `{store, items: [{product_id}]}` (single "Beli") and an `Idempotency-Key` header SHALL re-check every item, then create a `PENDING` order with `order_items`, locked prices, `price_locked_until = now + 30 minutes`, and the matching store product. It SHALL return `order_id`, `play_product_id`, `total_idr`, `charge_idr`, `price_locked_until` and the item list. A repeated key SHALL return the same order. A cart purchase SHALL NOT remove cart items until the order is granted. A single-item purchase SHALL skip the cart.

#### Scenario: Order created from cart
- **WHEN** a parent with a valid cart calls `POST /orders`
- **THEN** a `PENDING` order SHALL be created, the cart SHALL be unchanged, and the response SHALL include the `play_product_id` for the total

#### Scenario: Same idempotency key
- **WHEN** `POST /orders` is retried with the same `Idempotency-Key`
- **THEN** the original order SHALL be returned and no second order SHALL be created

#### Scenario: Single item order
- **WHEN** `POST /orders` is called with one `product_id` and no cart
- **THEN** an order of one item SHALL be created and the cart SHALL not be touched

#### Scenario: Rate limit
- **WHEN** one account calls `POST /orders` more than 10 times in a minute
- **THEN** further calls SHALL respond 429

### Requirement: Checkout re-checks the cart and reports changes
Before creating an order the server SHALL re-check each item for: still on sale, current price, not owned, not free, not Premium-covered. Owned and free items SHALL be removed from the cart. A price increase or ended promo SHALL keep the item with `price_changed_from`. A price decrease SHALL apply silently. Off-sale items SHALL be flagged `unavailable` and excluded. If anything other than a silent decrease changed, the server SHALL respond 409 `CART_CHANGED` with the new cart and `notices[]`, and SHALL NOT create an order.

#### Scenario: Owned item removed at checkout
- **WHEN** an item was bought on another device and the parent taps Bayar
- **THEN** the response SHALL be 409 `CART_CHANGED`, the item SHALL be gone from the cart and a notice SHALL say so

#### Scenario: Promo ended
- **WHEN** a promo ended after the item was added
- **THEN** the response SHALL be 409 `CART_CHANGED` and the item SHALL show the higher price with `price_changed_from`

#### Scenario: Price dropped
- **WHEN** an item price fell
- **THEN** the order SHALL be created at the lower price with no `CART_CHANGED`

#### Scenario: Retry after change accepted
- **WHEN** the app calls `POST /orders` again after a `CART_CHANGED` and nothing else moved
- **THEN** the order SHALL be created

### Requirement: Locked prices are honoured for 30 minutes
Once an order exists, its `order_items.price_idr`, `total` and store product SHALL NOT change. Settlement SHALL use them even after `price_locked_until` if the purchase was started before it, including Google pending purchases that complete later.

#### Scenario: Price raised mid-payment
- **WHEN** an item price is raised after the order is created and the parent pays within 30 minutes
- **THEN** the order SHALL be granted at the locked price

#### Scenario: Pending purchase completes after the lock
- **WHEN** a Google pending purchase completes 2 hours after the order was created
- **THEN** the order SHALL still be settled and granted at its locked prices

### Requirement: Limits and amounts are enforced on orders
An order SHALL be refused with 409 `CART_FULL`, `CART_TOTAL_LIMIT`, or `AMOUNT_UNAVAILABLE` (no active store product exists for the total) when it has more than 20 items, a total above Rp 500.000, or a total with no active product. Every order total SHALL be a whole multiple of Rp 1.000.

#### Scenario: No product for the total
- **WHEN** the total has no active row in `store_products`
- **THEN** the response SHALL be 409 `AMOUNT_UNAVAILABLE` and no order SHALL be created

### Requirement: Settlement is one idempotent function
`POST /orders/:id/verify`, the Play RTDN one-time-product notification and a worker running every minute over cart orders that are `PENDING` with a purchase token on file SHALL all settle through one function (the existing Google Play verify path, extended for cart orders). It SHALL verify the purchase with Google, check that the purchased product equals the order's store product, that the account id carried in the purchase equals the order id and that the user matches, store `purchase_token` (unique), then in one transaction lock the order row, skip if it is already `PAID`, insert or restore an entitlement for every item with `source_order_id`, delete those products from the user's cart, and set `status = PAID`, `paid_at` and `granted_at`. A purchase token already linked to another order SHALL be rejected and alerted. After commit the purchase SHALL be consumed server-side, with retries.

#### Scenario: All items granted together
- **WHEN** a valid purchase is verified for an order of three items
- **THEN** three entitlements SHALL exist with the order as source and those three items SHALL be removed from the cart

#### Scenario: Other cart items stay
- **WHEN** an order holds 2 of the 3 items in the cart and is granted
- **THEN** the third item SHALL remain in the cart

#### Scenario: Cheaper receipt cannot unlock bigger order
- **WHEN** a purchase for a Rp 1.000 product is sent to verify an order whose store product is Rp 106.000
- **THEN** verification SHALL fail and nothing SHALL be granted

#### Scenario: Concurrent settlement grants once
- **WHEN** verify, an RTDN and the worker settle the same order at the same time
- **THEN** each entitlement SHALL be created exactly once and the order SHALL be granted once

#### Scenario: Token reuse across orders
- **WHEN** a purchase token already stored on one order is submitted for another
- **THEN** the request SHALL be rejected and an alert SHALL be raised

#### Scenario: App killed after payment
- **WHEN** the parent paid and the app was closed before verify
- **THEN** the RTDN or the next app start verification SHALL still grant the order

### Requirement: Cancelled or failed payments change nothing
If the store reports a cancelled or failed purchase, or the order expires unpaid, the order SHALL move to `FAILED` or `EXPIRED`, nothing SHALL be granted and the cart SHALL be unchanged.

#### Scenario: Cancelled payment
- **WHEN** the parent cancels the Play sheet
- **THEN** no entitlement SHALL be created and the cart SHALL still hold every item

### Requirement: Paid-but-not-granted orders alert the team
A cart order paid in the store (purchase token on file) and still not granted more than 10 minutes after it was created SHALL trigger an alert, unless Google still reports the payment as pending. When the worker or the notification grants it after the app stopped waiting, the parent SHALL get a push "Item siap dibuka". Grant SHALL be retried by the worker until it succeeds. The app SHALL be able to read the state with `GET /orders/:id`, which returns `phase`, items, totals and, for the owner only, no other user's data.

#### Scenario: Stuck grant alerts
- **WHEN** an order stays paid but ungranted for 10 minutes
- **THEN** an alert SHALL be raised

#### Scenario: Delayed grant notifies the parent
- **WHEN** the worker grants an order the app was no longer waiting for
- **THEN** the parent SHALL receive a push notification that the items are ready

#### Scenario: Other user's order hidden
- **WHEN** a user requests another user's order
- **THEN** the response SHALL be 404

### Requirement: Refund takes back every item of the order
A refund or voided purchase of a cart order SHALL set the order to `REFUNDED` and end every entitlement with that `source_order_id` (`expires_at` set to now, the existing revocation used for single purchases). Access resolution SHALL ignore ended entitlements. A later re-purchase SHALL restore the entitlement (clear `expires_at`, point `source_order_id` at the new order). The refund SHALL be recorded in `order_refunds`.

#### Scenario: Refund revokes all items
- **WHEN** Google voids the purchase of an order of three items
- **THEN** all three entitlements SHALL be revoked

#### Scenario: Re-buy after refund
- **WHEN** a parent buys a refunded item again
- **THEN** its entitlement SHALL be active again

### Requirement: Owned items are listed for restore
`GET /entitlements` SHALL return the account's active owned items, so "Pulihkan pembelian" reads ownership from the server instead of the store, because consumables cannot be restored by the store.

#### Scenario: Restore on a new device
- **WHEN** a parent signs in on a new phone and restores purchases
- **THEN** the response SHALL list every active entitlement of the account

## MODIFIED Requirements

### Requirement: Orders represent purchase intent, separate from payment processing
The system SHALL have an `orders` table (`id` UUID PK, `user_id` UUID NOT NULL, `product_id` UUID NULL FK → `products.id`, `package_id` UUID NULL FK → `premium_packages.id`, `amount_idr` BIGINT NOT NULL, `status` VARCHAR NOT NULL IN `PENDING`/`PAID`/`FAILED`/`EXPIRED`/`REFUNDED`, `created_at`, `updated_at`), with a `CHECK` constraint enforcing that a non-cart order sets exactly one of `product_id`/`package_id`, and a cart order (`is_cart`) sets neither and references its store product. Cart orders SHALL carry their items in `order_items`.

#### Scenario: Order referencing both product and package rejected
- **WHEN** an order insert sets both `product_id` and `package_id`
- **THEN** the database SHALL reject the insert via the check constraint

#### Scenario: Non-cart order referencing neither product nor package rejected
- **WHEN** an order insert with `is_cart = false` sets neither `product_id` nor `package_id`
- **THEN** the database SHALL reject the insert via the check constraint

#### Scenario: Cart order has no product_id
- **WHEN** an order is created from a cart
- **THEN** `product_id` and `package_id` SHALL be null and `order_items` SHALL hold the items

#### Scenario: Order created in PENDING status
- **WHEN** `POST /payment/create` is called with a valid `package_id`
- **THEN** an `orders` row SHALL be created with `status = 'PENDING'` and `amount_idr` equal to the package's `price_idr`

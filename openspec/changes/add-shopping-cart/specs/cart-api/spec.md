## ADDED Requirements

### Requirement: One server-side cart per account
The system SHALL have a `cart_items` table (`user_id` UUID FK → `parents.id`, `product_id` UUID FK → `products.id`, `seen_price_idr` BIGINT — the price the parent last confirmed, `added_at` TIMESTAMPTZ) with primary key `(user_id, product_id)`, so an item appears in a cart at most once and has no quantity. Cart contents SHALL persist across log out, reinstall and devices, and SHALL be read per account.

#### Scenario: Cart shared across devices
- **WHEN** a parent adds an item on device A and calls `GET /cart` from device B
- **THEN** the response SHALL contain that item

#### Scenario: Item added twice stays once
- **WHEN** `POST /cart/items` is called twice with the same `product_id`
- **THEN** the cart SHALL contain one row for it and both calls SHALL return success

### Requirement: Only paid, unowned, single-sale items can be added
`POST /cart/items` with `{product_id}` SHALL accept only a product that is active, linked to a Kartu AR or Dongeng, has `price_idr > 0`, and is not owned by the user. Otherwise it SHALL respond 409 with one of `ALREADY_OWNED`, `NOT_FOR_SALE`, `FREE_ITEM` or `SUBSCRIPTION_ACTIVE`, and SHALL NOT change the cart. Akses Premium packages and Premium-only content SHALL never be accepted.

#### Scenario: Owned item refused
- **WHEN** a user who owns an AR card calls `POST /cart/items` for it
- **THEN** the response SHALL be 409 `ALREADY_OWNED`

#### Scenario: Free item refused
- **WHEN** a user adds a product whose content is marked free
- **THEN** the response SHALL be 409 `FREE_ITEM`

#### Scenario: Premium subscriber cannot add
- **WHEN** a user with an active Akses Premium subscription calls `POST /cart/items`
- **THEN** the response SHALL be 409 `SUBSCRIPTION_ACTIVE`

### Requirement: Cart size and value limits
A cart SHALL hold at most 20 items and its total at current prices SHALL NOT exceed Rp 500.000. An add that would break either limit SHALL respond 409 `CART_FULL` or `CART_TOTAL_LIMIT` and SHALL NOT change the cart.

#### Scenario: Twenty-first item refused
- **WHEN** a cart holds 20 items and the user adds another
- **THEN** the response SHALL be 409 `CART_FULL`

#### Scenario: Total over the maximum refused
- **WHEN** adding an item would take the cart total above Rp 500.000
- **THEN** the response SHALL be 409 `CART_TOTAL_LIMIT`

### Requirement: Cart read returns current prices and cleans stale items
`GET /cart` SHALL return each item with `product_id`, `item_type` (`ar_card` or `dongeng`), title, image URL, current `price_idr` and, when a promo is active, `strike_price_idr`; plus `item_count`, `subtotal_idr` (sum of normal prices, using the strike price when present), `promo_saving_idr` and `total_idr`. The app SHALL never send a price. Items that became owned, free or Premium-covered SHALL be removed from the cart and reported in `notices[]` with a reason. Items taken off sale SHALL be returned with `unavailable = true` and excluded from the total. Items whose price rose above `seen_price_idr` SHALL carry `price_changed_from`. Items untouched for 30 days SHALL stay in the cart.

#### Scenario: Owned item cleaned with notice
- **WHEN** an item in the cart was bought on another device and the user calls `GET /cart`
- **THEN** the item SHALL be removed and `notices[]` SHALL contain an `ALREADY_OWNED` notice naming it

#### Scenario: Promo shown as strike price
- **WHEN** an item has an active strike price Rp 2.000 and price Rp 1.000
- **THEN** the cart item SHALL show `price_idr = 1000` and `strike_price_idr = 2000`, and `promo_saving_idr` SHALL include 1000

#### Scenario: Off-sale item excluded
- **WHEN** a product in the cart becomes inactive
- **THEN** it SHALL be returned with `unavailable = true` and SHALL NOT count toward `total_idr`

#### Scenario: Old item keeps current price
- **WHEN** an item added 40 days ago changed price
- **THEN** `GET /cart` SHALL return the item with the current price

### Requirement: Items can be removed singly or all at once
`DELETE /cart/items/:product_id` SHALL remove one item and `DELETE /cart` SHALL remove all of them. Both SHALL be idempotent. Undo is performed by the client calling the add endpoint again.

#### Scenario: Remove then re-add
- **WHEN** an item is removed and `POST /cart/items` is called for it again
- **THEN** the cart SHALL contain it again

### Requirement: Subscribing clears the cart
When a premium subscription is granted to a user, the system SHALL delete that user's `cart_items`, and the next `GET /cart` SHALL return a notice that the items are included in Akses Premium. The user profile response SHALL include `cart_enabled`, false while a subscription is active.

#### Scenario: Subscription purchase empties the cart
- **WHEN** a user with 3 cart items buys Akses Premium
- **THEN** their cart SHALL be empty and `cart_enabled` SHALL be false

### Requirement: Cart is behind a feature flag
The `cart` key in `app_feature_flags` SHALL control whether cart and order endpoints work. While off, `POST /cart/items` and `POST /orders` with a cart SHALL respond 403 `CART_DISABLED`. A single-item order (`items` given) is not gated by the flag.

#### Scenario: Flag off
- **WHEN** the `cart` flag is off and a regular user calls `POST /cart/items`
- **THEN** the response SHALL be 403 `CART_DISABLED`

# premium-package-backoffice Specification

## Purpose
TBD - created by archiving change add-landing-page-product-showcase. Update Purpose after archive.
## Requirements
### Requirement: Backoffice has a Premium Packages management page
The system SHALL have a `/packages` route in the backoffice that renders a `PremiumPackagesPage` showing all packages (active and inactive) in an Ant Design `Table`. The page SHALL be accessible from the sidebar menu under a "Packages" item.

#### Scenario: Packages page accessible from menu
- **WHEN** an admin clicks "Packages" in the sidebar
- **THEN** the browser SHALL navigate to `/packages` and the table SHALL load all packages

#### Scenario: Table shows all packages including inactive
- **WHEN** the `PremiumPackagesPage` loads
- **THEN** the table SHALL display both active and inactive packages with a visual distinction (e.g., greyed-out row for inactive)

### Requirement: Admin can create a new premium package
The system SHALL provide an "Add Package" button on `PremiumPackagesPage` that opens a modal form with fields: Name, Subtitle, Price (IDR), Type (dropdown: Content / Subscription), Badge Label (optional), Is Best Value (checkbox), Sort Order, and Duration (Days) — shown only when Type is Subscription, and required in that case. Submitting the form SHALL call `POST /admin/premium/packs`.

#### Scenario: Modal opens on button click
- **WHEN** the admin clicks "Add Package"
- **THEN** a modal form SHALL appear with all required fields

#### Scenario: Package created on valid submit
- **WHEN** the admin fills all required fields and submits
- **THEN** `POST /admin/premium/packs` SHALL be called and the table SHALL refresh with the new package

#### Scenario: Validation prevents empty required fields
- **WHEN** the admin submits the form with an empty Name or Price field
- **THEN** the form SHALL show inline validation errors and NOT call the API

#### Scenario: Duration field shown only for subscription type
- **WHEN** the admin selects Type = Subscription in the create form
- **THEN** a required Duration (Days) field SHALL appear; selecting Type = Content SHALL hide it and clear its value

### Requirement: Admin can edit an existing package
The system SHALL provide an "Edit" action in each table row that opens the same modal form pre-filled with the package's current values, including Duration (Days) when the package is a subscription type. Submitting SHALL call `PUT /admin/premium/packs/:id`.

#### Scenario: Edit modal pre-filled with current values
- **WHEN** the admin clicks "Edit" on a package row
- **THEN** the modal SHALL open with all fields pre-populated from the selected package, including Duration (Days) if applicable

#### Scenario: Package updated on submit
- **WHEN** the admin modifies fields and submits
- **THEN** `PUT /admin/premium/packs/:id` SHALL be called and the table SHALL reflect the updated values

### Requirement: Admin can toggle package visibility
The system SHALL show an Ant Design `Switch` in the "Active" column of the table. Toggling the switch SHALL immediately call `PATCH /admin/premium/packs/:id/visibility` and update the UI optimistically.

#### Scenario: Switch reflects current is_active state
- **WHEN** the packages table renders
- **THEN** each row's switch SHALL be ON for `is_active = true` and OFF for `is_active = false`

#### Scenario: Toggle calls visibility endpoint
- **WHEN** the admin flips the switch on a package row
- **THEN** `PATCH /admin/premium/packs/:id/visibility` SHALL be called with the new `is_active` value

### Requirement: Admin can delete a package
The system SHALL provide a "Delete" action in each table row, protected by an Ant Design `Popconfirm` dialog asking for confirmation before calling `DELETE /admin/premium/packs/:id`.

#### Scenario: Confirmation shown before delete
- **WHEN** the admin clicks "Delete" on a package row
- **THEN** a confirmation dialog SHALL appear before any API call is made

#### Scenario: Package removed from table after delete
- **WHEN** the admin confirms the deletion
- **THEN** `DELETE /admin/premium/packs/:id` SHALL be called and the package SHALL disappear from the table

### Requirement: Admin can manage a package's content items
Each row in `PremiumPackagesPage` SHALL have a "Manage Items" action that opens a view listing the products currently assigned to that package (via `GET /admin/premium/packs/:id/items`), with the ability to add a product from a searchable list and remove an assigned product.

#### Scenario: Items view lists assigned products
- **WHEN** the admin opens "Manage Items" for a package
- **THEN** the products currently in `premium_package_items` for that package SHALL be listed

#### Scenario: Admin adds a product to the package
- **WHEN** the admin selects a product and confirms
- **THEN** `POST /admin/premium/packs/:id/items` SHALL be called and the product SHALL appear in the items list

#### Scenario: Admin removes a product from the package
- **WHEN** the admin removes an assigned product
- **THEN** `DELETE /admin/premium/packs/:id/items/:product_id` SHALL be called and the product SHALL disappear from the items list

### Requirement: Backoffice has a read-only Products catalog view
The system SHALL provide a "Products" view listing all `products` with their linked content (AR card or dongeng title), `feature`, `price_idr`, and `is_active` status.

#### Scenario: Products list shows linked content
- **WHEN** the admin opens the Products view
- **THEN** each product row SHALL display the title of the AR card or dongeng it is linked to

### Requirement: Backoffice has an Orders view with Google Play refunds
The system SHALL provide an "Orders" view listing `orders` with `user`, `product`/`package` reference, `amount_idr`, `status`, and `created_at`, filterable by `status`. Rows with `provider = google_play`, `status = PAID` and a purchase token SHALL have a "Refund" action. It SHALL open a modal with:
- the order summary (user, item, amount, Play order id)
- for subscriptions, a Full / Prorated choice
- a required reason of at least 10 characters
- a required confirmation that the money is returned and access removed

Submitting SHALL call `POST /admin/orders/:id/refund`, and SHALL show Google's error message if it fails. An order with refund records SHALL have a "Refunds" view listing each record (source, admin, time, type, amounts, Google state, status or error), with a "Sync refund details" action.

#### Scenario: Orders list is filterable by status
- **WHEN** the admin filters the Orders view by `status = PAID`
- **THEN** only orders with `status = 'PAID'` SHALL be shown

#### Scenario: Refund offered only for refundable Play orders
- **WHEN** the Orders view shows a `PAID` Google Play order with a purchase token, a Midtrans order, and a `REFUNDED` order
- **THEN** only the first SHALL have a "Refund" action

#### Scenario: Admin refunds a subscription with a prorated refund
- **WHEN** the admin opens Refund on a subscription order, chooses Prorated, enters a reason, ticks the confirmation and submits
- **THEN** `POST /admin/orders/:id/refund` SHALL be sent with `refund_type: "PRORATED"` and the reason, and the row SHALL show `REFUNDED` afterwards

#### Scenario: Submit blocked until reason and confirmation
- **WHEN** the reason is shorter than 10 characters or the confirmation is unticked
- **THEN** the modal SHALL NOT submit

### Requirement: Admin can map a product to a Google Play SKU
The Products page SHALL show a "Play Billing" column (Mapped with the SKU, or Unmapped) and a "Play Product ID" field on the Add and Edit product forms. `POST /admin/products` and `PUT /admin/products/:id` SHALL accept `play_product_id`.
- On update, an absent field SHALL leave the mapping unchanged, and `null` or a blank string SHALL clear it. Surrounding whitespace SHALL be trimmed.
- A SKU already used by another product or by a package SHALL be rejected with 400, and the page SHALL show the server's message.

#### Scenario: Mapping a product
- **WHEN** the admin enters `card_frog` in "Play Product ID" and saves
- **THEN** the product SHALL show "Mapped" with `card_frog`, and the public AR card list SHALL carry `play_product_id: "card_frog"`

#### Scenario: Editing the price keeps the mapping
- **WHEN** a client updates a product's price without sending `play_product_id`
- **THEN** the product's mapping SHALL be unchanged

#### Scenario: Clearing the mapping
- **WHEN** the admin empties the "Play Product ID" field and saves
- **THEN** the mapping SHALL be cleared and the product SHALL show "Unmapped"

#### Scenario: Duplicate SKU
- **WHEN** the admin enters a SKU that another product or package already uses
- **THEN** the save SHALL be rejected and the page SHALL show "already used by another product or package"


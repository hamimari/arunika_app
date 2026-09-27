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

### Requirement: Backoffice has a read-only Orders view
The system SHALL provide an "Orders" view listing `orders` with `user`, `product`/`package` reference, `amount_idr`, `status`, and `created_at`, filterable by `status`.

#### Scenario: Orders list is filterable by status
- **WHEN** the admin filters the Orders view by `status = PAID`
- **THEN** only orders with `status = 'PAID'` SHALL be shown


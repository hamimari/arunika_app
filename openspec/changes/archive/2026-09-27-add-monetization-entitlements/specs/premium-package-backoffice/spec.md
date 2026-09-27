## MODIFIED Requirements

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

## ADDED Requirements

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

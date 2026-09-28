## ADDED Requirements

### Requirement: Admin sets content access when creating or editing
The AR card and dongeng create/edit forms in the backoffice SHALL have an **Access** field with the options Free and Premium, mapped to `is_free`. It SHALL default to Free on create. When Premium is selected and the item has no product, the form SHALL show a hint that a product must be created on the Products page before the item can be sold.

#### Scenario: New AR card created as free
- **WHEN** an admin creates an AR card and leaves Access as Free
- **THEN** the card SHALL be saved with `is_free = true` and SHALL be unlocked for every user in the app

#### Scenario: Premium without a product
- **WHEN** an admin selects Premium for an AR card that has no product
- **THEN** the form SHALL show the "create a product" hint, and the list SHALL show the card as "Free (no product)"

### Requirement: Saving an item never changes its access
Editing an AR card or dongeng SHALL NOT change its access unless the admin changed the Access field. The backend SHALL apply a change of access only through `PATCH /admin/content/ar-cards/:id/free` or `PATCH /admin/content/fairy-tales/:id/free`, whose body SHALL include `is_free`; a request without it SHALL be rejected with 400 and an unknown item with 404. `PUT` on an AR card SHALL leave `is_free` unchanged.

#### Scenario: A client that does not know about the flag renames a free card
- **WHEN** a client sends `PUT /admin/content/ar-cards/:id` with a new title and no `is_free`
- **THEN** the title SHALL change and the card SHALL remain free

#### Scenario: Missing is_free is not treated as false
- **WHEN** a client sends `PATCH /admin/content/ar-cards/:id/free` with an empty body
- **THEN** the response SHALL be 400 and the card SHALL be unchanged

#### Scenario: Changing Access in the edit form
- **WHEN** an admin changes an AR card's Access from Premium to Free in the edit form and saves
- **THEN** the free endpoint SHALL be called first, then the card saved, and if the free call fails the card SHALL NOT be saved

### Requirement: Admin sees each item's effective access
The AR card and dongeng lists SHALL show an Access column from the backend-computed `access` value:
- `FREE` → "Free"
- `FREE_NO_PRODUCT` → "Free (no product)"
- `PAID` → "Paid" with its price
- `PAID_INACTIVE` → "Paid (withdrawn)"

#### Scenario: Paid card shows its price
- **WHEN** the AR cards list loads and a card has an active product priced Rp 15.000 with `is_free = false`
- **THEN** its Access column SHALL show "Paid" and Rp 15.000

### Requirement: Admin can make a paid item free and back
Each AR card and dongeng row SHALL have a "Make free" action when `is_free = false`, and a "Make premium" action when `is_free = true`. Each action SHALL be protected by a confirmation that explains the effect. On confirm, the action SHALL update `is_free` only, leaving the product, orders and entitlements untouched. The Products page SHALL tag products whose content is free with "Free override". The package "Manage Items" view SHALL warn when a free item is added to a bundle.

#### Scenario: Making a sold AR card free
- **WHEN** an admin confirms "Make free" on an AR card that has a product with existing orders
- **THEN** `is_free` SHALL become true, the product and orders SHALL remain, and the Products page SHALL show "Free override" on that product

#### Scenario: Reverting to premium
- **WHEN** an admin confirms "Make premium" on that card
- **THEN** `is_free` SHALL become false, previous buyers SHALL keep access, and other users SHALL see it locked again

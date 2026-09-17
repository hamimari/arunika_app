## MODIFIED Requirements

### Requirement: Admin can create a new premium package
The system SHALL provide an "Add Package" button on `PremiumPackagesPage` that opens a modal form with fields: Name, Subtitle, Description (optional, multi-line textarea), Image URL (optional, text input), Price (IDR), Type (dropdown: Content / Subscription), Badge Label (optional), Is Best Value (checkbox), Sort Order. Submitting the form SHALL call `POST /admin/premium/packs`.

#### Scenario: Modal opens on button click
- **WHEN** the admin clicks "Add Package"
- **THEN** a modal form SHALL appear with all fields including Description and Image URL

#### Scenario: Package created without description or image
- **WHEN** the admin fills all required fields but leaves Description and Image URL blank and submits
- **THEN** `POST /admin/premium/packs` SHALL be called successfully with `description` and `image_url` omitted or empty

#### Scenario: Package created with description and image
- **WHEN** the admin fills Description and Image URL along with the required fields and submits
- **THEN** `POST /admin/premium/packs` SHALL be called with those values and the table SHALL refresh with the new package

#### Scenario: Validation prevents empty required fields
- **WHEN** the admin submits the form with an empty Name or Price field
- **THEN** the form SHALL show inline validation errors and NOT call the API

### Requirement: Admin can edit an existing package
The system SHALL provide an "Edit" action in each table row that opens the same modal form pre-filled with the package's current values, including Description and Image URL. Submitting SHALL call `PUT /admin/premium/packs/:id`.

#### Scenario: Edit modal pre-filled with current values
- **WHEN** the admin clicks "Edit" on a package row
- **THEN** the modal SHALL open with all fields pre-populated from the selected package, including its current Description and Image URL (blank if previously unset)

#### Scenario: Package updated on submit
- **WHEN** the admin modifies fields (including Description or Image URL) and submits
- **THEN** `PUT /admin/premium/packs/:id` SHALL be called and the table SHALL reflect the updated values

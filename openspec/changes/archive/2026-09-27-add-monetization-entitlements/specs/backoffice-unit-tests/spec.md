## ADDED Requirements

### Requirement: API-layer test coverage for admin modules
Every module under `src/api/` SHALL have a corresponding test file using `axios-mock-adapter` against the shared client, asserting exact request method, URL, and body/param shapes. This requirement explicitly includes `premiumPackagesApi`, which previously had zero test coverage despite being fully implemented, plus the new `productsApi`, `packageItemsApi`, and `ordersApi` introduced by this change.

#### Scenario: premiumPackagesApi CRUD methods are tested
- **WHEN** the test suite runs
- **THEN** `src/test/api/admin.test.ts` (or a dedicated file) SHALL assert the request shape of `premiumPackagesApi.list/create/update/remove/toggleVisibility`

#### Scenario: New monetization API modules are tested
- **WHEN** the test suite runs
- **THEN** `productsApi`, `packageItemsApi`, and `ordersApi` SHALL each have tests covering their list/detail/mutation methods with mocked request/response assertions

### Requirement: Page-level test coverage for CRUD admin pages
Every page under `src/pages/` that renders a table-driven CRUD interface backed by React Query SHALL have a corresponding test file using React Testing Library, covering at minimum: initial data render, create/update submission triggering the expected API call, and an error state. This requirement explicitly includes `PremiumPackagesPage` and the new products/package-items/orders admin views, none of which have page-level tests today.

#### Scenario: PremiumPackagesPage renders fetched packages
- **WHEN** the page mounts and the mocked `premiumPackagesApi.list` resolves with package rows
- **THEN** the table SHALL render one row per package

#### Scenario: Create action calls the API and refreshes the list
- **WHEN** the create form is submitted with valid values
- **THEN** the mocked create API SHALL be called with the submitted values and the list SHALL re-render with the new row

#### Scenario: API error surfaces to the user
- **WHEN** the mocked list API call rejects
- **THEN** the page SHALL render a visible error state instead of an empty or crashed table

## ADDED Requirements

### Requirement: OpenAPI document is the single source of truth for the API contract
`arunika-backend` SHALL maintain an OpenAPI 3.1 document describing every route registered by the router, including each route's authentication requirement. The document SHALL be published as a release artifact so client repositories can consume it.

#### Scenario: Every route is described
- **WHEN** the contract suite runs
- **THEN** every route registered by the router has a corresponding entry in the OpenAPI document

#### Scenario: New route without a spec entry fails
- **WHEN** a route is added to the router but not to the OpenAPI document
- **THEN** the contract suite fails

#### Scenario: Authentication requirement is recorded
- **WHEN** a route is described in the document
- **THEN** its entry states whether it requires a user token, an admin token, an optional token, or no token

### Requirement: Backend responses are validated against the contract
API integration tests SHALL validate every response they receive against the OpenAPI document, so a change to a response shape cannot merge without the document being updated.

#### Scenario: Response shape change is caught
- **WHEN** a handler starts returning a field with a different type or drops a documented field
- **THEN** response validation fails against the OpenAPI document

#### Scenario: Undocumented response is rejected
- **WHEN** an API test receives a response for a status code the document does not describe
- **THEN** validation fails

### Requirement: Client repositories verify that every path they call exists
`arunika_app` and `arunika-backoffice` SHALL each hold a vendored copy of the OpenAPI document and a test asserting that every API path their client layer calls exists in it.

#### Scenario: Drifted client path is caught
- **WHEN** the Flutter client declares a path that the backend does not serve
- **THEN** the conformance test fails naming that path

#### Scenario: Backoffice call sites are covered
- **WHEN** the backoffice API modules call a path absent from the document
- **THEN** the conformance test fails naming that path

#### Scenario: Removing a backend route breaks its consumers visibly
- **WHEN** a route is removed from the backend and the updated document reaches the client repositories
- **THEN** any client still declaring that path fails its conformance test

### Requirement: Vendored contract staleness is visible
The vendored OpenAPI copies SHALL be refreshed by an automated job that opens a pull request when the upstream document changes, rather than updating silently.

#### Scenario: Upstream change raises a pull request
- **WHEN** the backend publishes a changed OpenAPI document
- **THEN** each client repository receives a pull request updating its vendored copy

#### Scenario: Stale copy is reviewable, not silent
- **WHEN** a client repository's vendored document lags behind the published one
- **THEN** the difference is visible as an open pull request rather than as a silently passing test

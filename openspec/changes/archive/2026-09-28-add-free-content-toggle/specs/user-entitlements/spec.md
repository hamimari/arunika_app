## MODIFIED Requirements

### Requirement: Access is resolved per request from entitlements, not a stored flag
The system SHALL compute content access (`is_unlocked` on AR cards, `is_unlocked` on dongeng) at request time as follows:
- content flagged `is_free` → allowed
- no linked product → allowed
- otherwise allowed if the requesting user has an active `user_entitlements` row for the linked product OR an active subscription
- otherwise denied

Free content (flagged or unlinked) SHALL be returned without a product id or price. Stored global unlock flags SHALL NOT be used for this determination.

#### Scenario: Free content always accessible
- **WHEN** a request is made for an AR card with no linked product
- **THEN** `is_unlocked` SHALL be `true` for every user, including unauthenticated requests

#### Scenario: Flagged-free content with a product is accessible
- **WHEN** a request is made for an AR card with a linked product and `is_free = true`, by a user with no entitlement
- **THEN** `is_unlocked` SHALL be `true`, and the response SHALL carry no product id or price

#### Scenario: Paid content accessible only with an entitlement
- **WHEN** a request is made for a paid AR card by a user with an active `user_entitlements` row for its product
- **THEN** `is_unlocked` SHALL be `true`

#### Scenario: Paid content inaccessible without an entitlement
- **WHEN** a request is made for a paid AR card by a user with no matching entitlement and no active subscription
- **THEN** `is_unlocked` SHALL be `false`

#### Scenario: Expired entitlement does not grant access
- **WHEN** a user's `user_entitlements` row for a product has `expires_at` in the past
- **THEN** `is_unlocked` SHALL be `false` for that product

## ADDED Requirements

### Requirement: Token rejection regression coverage
The backend SHALL have automated tests asserting that protected endpoints reject every invalid form of credential: missing, malformed, wrongly signed, expired, and revoked.

#### Scenario: Missing Authorization header is rejected
- **WHEN** a protected endpoint is called with no `Authorization` header
- **THEN** the response is unauthorised and no data is returned

#### Scenario: Malformed or wrongly signed token is rejected
- **WHEN** a token is malformed, or is correctly formed but signed with a different key
- **THEN** the response is unauthorised

#### Scenario: Expired access token is rejected
- **WHEN** an expired access token is presented
- **THEN** the response is unauthorised

#### Scenario: Revoked token is rejected after logout
- **WHEN** an access token is reused after the user has logged out
- **THEN** the response is unauthorised, because the token identifier is revoked

### Requirement: Refresh token abuse coverage
Automated tests SHALL assert that expired, revoked and replayed refresh tokens cannot yield a new access token.

#### Scenario: Revoked refresh token is rejected
- **WHEN** a refresh token that has been revoked is presented
- **THEN** the refresh is rejected

#### Scenario: Refresh token replay is rejected
- **WHEN** a refresh token is presented a second time after already being used or invalidated
- **THEN** the refresh is rejected and no new access token is issued

#### Scenario: Password reset revokes outstanding refresh tokens
- **WHEN** a user completes a password reset and then presents a refresh token issued before it
- **THEN** the refresh is rejected

### Requirement: Horizontal privilege escalation coverage
Automated tests SHALL assert that an authenticated user cannot read or modify another user's resources.

#### Scenario: User cannot read another user's order
- **WHEN** user A requests an order belonging to user B
- **THEN** the response denies access and reveals no order data

#### Scenario: User cannot read another user's personal records
- **WHEN** user A requests user B's growth records, notifications or play history
- **THEN** the response denies access

#### Scenario: User cannot modify another user's profile
- **WHEN** user A attempts to update or delete user B's account
- **THEN** the request is denied and user B's record is unchanged

### Requirement: Vertical privilege escalation coverage
Automated tests SHALL assert that every administrative endpoint rejects a valid non-admin user token, enumerated from the route table so that newly added admin routes are covered without a new test being written.

#### Scenario: Admin route rejects a user token
- **WHEN** any route under the administrative prefix is called with a valid ordinary user token
- **THEN** the response is forbidden

#### Scenario: New admin route is covered automatically
- **WHEN** a new administrative route is registered
- **THEN** the enumerated test covers it without modification

### Requirement: Purchase tampering coverage
Automated tests SHALL assert that the purchase verification path rejects tampered and reused inputs.

#### Scenario: Purchase token reused by a different user is rejected
- **WHEN** a purchase token already consumed by one user is submitted by another
- **THEN** verification is rejected and no entitlement is granted to the second user

#### Scenario: Product identifier tampering is rejected
- **WHEN** a verification request references a product that does not match the purchase reported by the store
- **THEN** verification is rejected

#### Scenario: Purchase token replayed against a different order is rejected
- **WHEN** a purchase token is submitted against an order it does not belong to
- **THEN** verification is rejected

### Requirement: Input validation and injection regression coverage
Automated tests SHALL assert that untrusted input cannot alter query semantics or crash the service.

#### Scenario: SQL metacharacters are treated as data
- **WHEN** filter, search or sort parameters contain SQL metacharacters
- **THEN** they are treated as literal values, the query returns a normal result or a validation error, and no unintended rows are returned or modified

#### Scenario: Oversized or wrongly typed payload is rejected
- **WHEN** a request body is far larger than expected or supplies the wrong types
- **THEN** the service rejects it with a client error rather than failing unexpectedly

### Requirement: Error responses do not leak sensitive information
Automated tests SHALL assert that error responses expose no stack traces, SQL fragments, internal file paths, dependency errors, or account-existence signals.

#### Scenario: Server error body is opaque
- **WHEN** an endpoint fails internally
- **THEN** the response body contains a generic message with no stack trace, SQL text or internal path

#### Scenario: Password reset does not enumerate accounts
- **WHEN** a password reset is requested for an unknown email and for a known email
- **THEN** the two responses are indistinguishable to the caller

#### Scenario: Login does not reveal which credential was wrong
- **WHEN** login fails because of an unknown email and because of a wrong password
- **THEN** the two responses are indistinguishable to the caller

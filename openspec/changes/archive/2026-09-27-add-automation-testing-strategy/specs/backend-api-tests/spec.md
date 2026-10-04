## ADDED Requirements

### Requirement: API tests exercise the real router end to end
API integration tests SHALL issue HTTP requests against the application's actual route table, so that middleware, handler, service and database layers are exercised together. Tests SHALL use the routes that exist in the repository rather than assumed paths.

#### Scenario: Request traverses the full stack
- **WHEN** an API test issues a request to a real route
- **THEN** the configured middleware chain, handler, service and database all execute, and the assertion covers status code, response body and resulting database state

#### Scenario: Unregistered route is not testable
- **WHEN** a test targets a path that the router does not register
- **THEN** the test fails with a not-found result rather than passing against a stub

#### Scenario: Database state is asserted alongside the response
- **WHEN** an API test performs a write
- **THEN** it asserts both the HTTP response and the rows actually persisted

### Requirement: Authentication lifecycle coverage
API tests SHALL cover the full authentication lifecycle — signup, OTP, login, authenticated access, token refresh and logout — including the failure and abuse paths.

#### Scenario: Happy path issues and accepts tokens
- **WHEN** a user signs up, confirms OTP and logs in
- **THEN** an access token and refresh token are issued, and the access token authorises a protected request

#### Scenario: Invalid credentials are rejected
- **WHEN** login is attempted with a wrong password or an unknown email
- **THEN** the response is unauthorised and no token is issued

#### Scenario: Refresh returns a new access token
- **WHEN** a valid refresh token is presented after the access token has expired
- **THEN** a new access token is issued and the subsequent request succeeds

#### Scenario: Logout revokes the access token
- **WHEN** a user logs out and then reuses the same access token
- **THEN** the request is rejected, because the token identifier is revoked in Redis

#### Scenario: Expired refresh token is rejected
- **WHEN** an expired refresh token is presented
- **THEN** the refresh is rejected and no new access token is issued

#### Scenario: OTP failures are handled
- **WHEN** an OTP is expired, incorrect, or replayed after successful use
- **THEN** the request is rejected

### Requirement: Purchase and entitlement API coverage without external credentials
API tests SHALL cover the Google Play purchase verification chain by directing the verifier at a fake Android Publisher server through the existing base-URL override. No Google Play service-account credential SHALL be stored in any repository.

#### Scenario: Valid purchase grants access
- **WHEN** a pending order is verified with a purchase token the fake Publisher reports as purchased
- **THEN** the order becomes paid, an entitlement is granted, and the corresponding content subsequently reports as unlocked for that user

#### Scenario: Duplicate purchase token grants nothing extra
- **WHEN** the same purchase token is verified twice
- **THEN** the second call is idempotent and no second entitlement row is created

#### Scenario: Invalid purchase token is rejected
- **WHEN** the fake Publisher reports the token as unknown or errored
- **THEN** verification is rejected, the order does not become paid, and no entitlement is granted

#### Scenario: Product mismatch is rejected
- **WHEN** the purchase token reports a product that differs from the one the order references
- **THEN** verification is rejected and no entitlement is granted

#### Scenario: Package name mismatch is rejected
- **WHEN** verification runs against a configured Android package name that does not match the purchase
- **THEN** verification is rejected and no entitlement is granted

#### Scenario: Bundle grants every item
- **WHEN** a content package containing several products is purchased and verified
- **THEN** an entitlement is granted for every product in that package

#### Scenario: Entitlements survive re-login
- **WHEN** a user who has purchased content logs in again from a new session
- **THEN** the previously purchased content reports as unlocked

#### Scenario: Renewal notification extends access
- **WHEN** a renewal developer notification is received for an active subscription
- **THEN** the subscription expiry is synchronised to the reported value

#### Scenario: Revocation notification ends access
- **WHEN** a revocation developer notification is received
- **THEN** the subscription is revoked and the previously unlocked content reports as locked

#### Scenario: Voided purchase revokes the entitlement
- **WHEN** reconciliation finds a purchase reported as voided
- **THEN** the entitlements granted by that order are expired

### Requirement: Request validation and error-handling coverage
API tests SHALL cover input validation and error handling for each write endpoint, asserting the status code and the shape of the error response.

#### Scenario: Malformed body is rejected
- **WHEN** a request body is missing a required field or supplies the wrong type
- **THEN** the response is a client error naming the validation problem, and nothing is persisted

#### Scenario: Unknown resource returns not found
- **WHEN** a request references an identifier that does not exist
- **THEN** the response is not found rather than a server error

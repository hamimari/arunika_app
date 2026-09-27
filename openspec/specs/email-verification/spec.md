# email-verification Specification

## Purpose
TBD - created by archiving change add-email-verification. Update Purpose after archive.
## Requirements
### Requirement: Registration is never blocked by email delivery
Account registration SHALL succeed and issue session tokens regardless of whether the verification email can be sent. The verification email SHALL be dispatched asynchronously and best-effort, and a delivery failure SHALL be logged with the user's identifier rather than returned to the caller.

#### Scenario: Registration succeeds when mail delivery fails
- **WHEN** a user registers and the mail transport is unavailable
- **THEN** the account is created, tokens are issued, the success response is unchanged, and the delivery failure is recorded in the logs

#### Scenario: Registration response shape is unchanged
- **WHEN** a user registers successfully
- **THEN** the response is identical in shape and status to the pre-change registration response

#### Scenario: Newly registered account starts unverified
- **WHEN** an account is created
- **THEN** its email verification state is false until a verification token is consumed

### Requirement: Verification tokens are single-use, expiring and stored hashed
The system SHALL issue opaque verification tokens that are stored only as a cryptographic hash, expire after a bounded lifetime, are consumable exactly once, and are invalidated when a newer token is issued for the same user.

#### Scenario: Only a hash is persisted
- **WHEN** a verification token is issued
- **THEN** the stored record contains a hash of the token and never the value that was emailed

#### Scenario: Token is consumed exactly once
- **WHEN** a valid verification token is used a second time
- **THEN** the second attempt is rejected and reports that the link is no longer valid

#### Scenario: Expired token is rejected
- **WHEN** a verification token is used after its expiry
- **THEN** it is rejected and the user is offered a way to request a new one

#### Scenario: Reissue invalidates the previous token
- **WHEN** a new verification token is issued for a user who already has an outstanding one
- **THEN** the earlier token no longer verifies the account

#### Scenario: Unknown token is rejected
- **WHEN** a token that was never issued is presented
- **THEN** it is rejected and no account changes state

### Requirement: Consuming a valid token marks the account verified
The system SHALL expose an endpoint that accepts a verification token and, when the token is valid, records the account as verified and presents a human-readable confirmation.

#### Scenario: Valid token verifies the account
- **WHEN** a user opens their verification link while the token is valid
- **THEN** the account is recorded as verified and a confirmation page is shown

#### Scenario: Already-verified account is handled gracefully
- **WHEN** a user opens a verification link for an account that is already verified
- **THEN** a page confirming the account is verified is shown rather than an error

#### Scenario: Expired link offers a way forward
- **WHEN** a user opens an expired verification link
- **THEN** the page explains that the link expired and offers to send a new one

#### Scenario: Confirmation page does not leak the token
- **WHEN** the confirmation page is rendered
- **THEN** it does not echo the token into the page and does not load third-party resources that could carry it in a referrer

### Requirement: Verification email can be resent, subject to rate limiting
The system SHALL provide an endpoint for an authenticated user to request a new verification email, and that endpoint SHALL be rate limited.

#### Scenario: Resend issues a new token
- **WHEN** an authenticated unverified user requests a resend
- **THEN** a new verification email is dispatched and the previously issued token stops working

#### Scenario: Excessive resend requests are limited
- **WHEN** resend is requested more times than the configured limit within the configured window
- **THEN** further requests are rejected until the window elapses

#### Scenario: Resend on a verified account changes nothing
- **WHEN** an already-verified user requests a resend
- **THEN** no new token is issued and the account remains verified

#### Scenario: Rate limiter outage does not disable resend
- **WHEN** the rate-limiting backend is unavailable
- **THEN** resend continues to function, with limiting temporarily not enforced

### Requirement: Password reset delivery requires a verified email
The system SHALL refuse to send a password reset link to an address that has not been verified. Verification state SHALL NOT be inferable from the response.

#### Scenario: Reset is sent to a verified address
- **WHEN** a password reset is requested for a verified account
- **THEN** the reset link is emailed as before

#### Scenario: Reset is withheld from an unverified address
- **WHEN** a password reset is requested for an unverified account
- **THEN** no reset link is sent and no reset token is created

#### Scenario: Responses do not reveal verification state
- **WHEN** a password reset is requested for an unverified account, for a verified account, and for an address with no account
- **THEN** all three responses are indistinguishable to the caller in status, body and timing characteristics the caller can observe

### Requirement: Verification state is exposed to clients
The authenticated user profile response SHALL include whether the account's email address has been verified, so clients can surface it.

#### Scenario: Profile reports verification state
- **WHEN** a client fetches the authenticated user's profile
- **THEN** the response includes the account's email verification state

### Requirement: Accounts created before this capability are treated as verified
Accounts that existed before email verification was introduced SHALL be recorded as verified, so that introducing the password-reset gate does not withdraw account recovery from the existing user base.

#### Scenario: Pre-existing accounts keep password recovery
- **WHEN** the verification capability is introduced
- **THEN** every account that already existed is recorded as verified and can still request a password reset

#### Scenario: Accounts created afterwards must verify
- **WHEN** an account is created after the capability is introduced
- **THEN** it begins unverified and must consume a verification token before password reset will be sent

### Requirement: No unreachable verification scaffolding remains
The codebase SHALL NOT retain a second, non-functional verification mechanism alongside this one.

#### Scenario: The superseded one-time-code path is gone
- **WHEN** the codebase is inspected after this change
- **THEN** the previous one-time-code generation, storage, sending, service method, handler and route are absent, along with their template

#### Scenario: Only one verification mechanism is discoverable
- **WHEN** a developer looks for how email verification works
- **THEN** exactly one mechanism exists, and it is the one that is actually wired up


# email-verification-app Specification

## Purpose
TBD - created by archiving change add-email-verification. Update Purpose after archive.
## Requirements
### Requirement: Unverified accounts are prompted without being obstructed
The app SHALL surface an unverified email address to the user through a dismissible, non-modal prompt. The prompt SHALL explain why verification matters and offer to resend the verification email.

#### Scenario: Prompt appears for an unverified account
- **WHEN** a signed-in user whose email is unverified opens the app
- **THEN** a dismissible prompt is shown offering to resend the verification email

#### Scenario: Prompt is absent for a verified account
- **WHEN** a signed-in user whose email is verified opens the app
- **THEN** no verification prompt is shown

#### Scenario: Prompt can be dismissed
- **WHEN** the user dismisses the prompt
- **THEN** it is hidden for that session and the user continues uninterrupted

#### Scenario: Prompt explains the consequence
- **WHEN** the prompt is shown
- **THEN** it states that password recovery requires a verified email address

### Requirement: Resend is available from the app and reports its outcome
The app SHALL let the user request a new verification email from the prompt, and SHALL report success, failure and rate-limiting distinctly.

#### Scenario: Successful resend is confirmed
- **WHEN** the user taps resend and the request succeeds
- **THEN** the app confirms that the email has been sent

#### Scenario: Rate-limited resend is explained
- **WHEN** the user taps resend and the backend reports the rate limit has been reached
- **THEN** the app explains that too many requests were made and to try again later, rather than showing a generic failure

#### Scenario: Failed resend does not misreport success
- **WHEN** the resend request fails
- **THEN** the app shows a failure state and leaves the resend action available

### Requirement: Verification state never gates app functionality
The app SHALL NOT restrict navigation, content, or purchase and entitlement flows based on email verification state.

#### Scenario: Unverified user reaches all content
- **WHEN** an unverified user browses AR cards, dongeng or any other content
- **THEN** access is determined solely by entitlements, exactly as for a verified user

#### Scenario: Unverified user can purchase
- **WHEN** an unverified user starts and completes a purchase
- **THEN** the purchase proceeds and the resulting entitlement is granted, unaffected by verification state

#### Scenario: Unverified user can sign in
- **WHEN** an unverified user signs in with valid credentials
- **THEN** sign-in succeeds

### Requirement: The app carries no unreachable verification screens
The app SHALL NOT retain screens, state management or routes for a verification mechanism that is not wired up.

#### Scenario: The superseded one-time-code screen is gone
- **WHEN** the app source is inspected after this change
- **THEN** the previous one-time-code screen, its state management and its route are absent

#### Scenario: No route points at a removed screen
- **WHEN** the router is inspected
- **THEN** every declared route resolves to a screen that exists and is reachable


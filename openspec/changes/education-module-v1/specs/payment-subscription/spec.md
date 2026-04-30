## ADDED Requirements

### Requirement: Subscription status stored per user
The backend SHALL maintain a `user_subscriptions` table with status (`free` or `premium`) and expiry timestamp. New users SHALL default to `free`.

#### Scenario: New user has free status
- **WHEN** a user completes sign-up
- **THEN** a `user_subscriptions` row with status `free` is created

### Requirement: Feature access control for premium content
A backend middleware SHALL return HTTP 403 for premium-only endpoints when the requesting user's subscription status is `free`.

#### Scenario: Free user accesses premium endpoint
- **WHEN** a free-tier user calls GET `/counting/questions?level=hard`
- **THEN** system returns HTTP 403 with message "Premium subscription required"

#### Scenario: Premium user accesses premium endpoint
- **WHEN** a premium user calls the same endpoint
- **THEN** system returns HTTP 200 with the question list

### Requirement: Midtrans Snap transaction creation
The backend SHALL create a Midtrans Snap transaction and return the `redirect_url` to the Flutter app.

#### Scenario: Create payment transaction
- **WHEN** client sends POST `/payment/create` with a valid user session
- **THEN** backend calls Midtrans Snap API, stores a pending order, and returns `{ redirect_url, order_id }`

#### Scenario: Midtrans API unreachable
- **WHEN** the Midtrans API returns an error
- **THEN** backend returns HTTP 502 with a user-friendly error message

### Requirement: Midtrans webhook handling
The backend SHALL expose POST `/payment/webhook` to receive Midtrans notifications, validate the `signature_key`, and update the user's subscription status on successful payment.

#### Scenario: Valid payment notification
- **WHEN** Midtrans sends a webhook with `transaction_status: settlement` and a valid signature
- **THEN** backend updates `user_subscriptions.status` to `premium` and sets `expires_at` to 30 days from now

#### Scenario: Invalid signature on webhook
- **WHEN** webhook arrives with a mismatched `signature_key`
- **THEN** backend returns HTTP 403 and does not update any record

### Requirement: Upgrade CTA in Flutter app
The Flutter app SHALL display a lock icon and "Upgrade" button on premium content. Tapping the button SHALL open the Midtrans payment WebView.

#### Scenario: Lock shown for free user
- **WHEN** a free user views the counting exercise list
- **THEN** Medium and Hard levels show a lock overlay with an "Upgrade" button

#### Scenario: Payment flow opened
- **WHEN** user taps "Upgrade"
- **THEN** app calls the backend, receives the redirect_url, and opens it in a WebView

## ADDED Requirements

### Requirement: FCM token registration
The Flutter app SHALL register the device's FCM token with the backend on login and on each app launch if the token has changed.

#### Scenario: Token registered on login
- **WHEN** user successfully signs in
- **THEN** app calls POST `/notifications/token` with the current FCM token
- **THEN** backend upserts the token in `fcm_tokens`

#### Scenario: Stale token on FCM side
- **WHEN** FCM returns a 404 for a stored token
- **THEN** backend deletes the stale token row

### Requirement: Push notification dispatch from backend
The backend SHALL send FCM push notifications for: badge earned, new content published, and payment success.

#### Scenario: Badge earned notification
- **WHEN** a badge is awarded to a user
- **THEN** backend sends a push notification with title "Badge Earned!" and the badge name

#### Scenario: Payment success notification
- **WHEN** Midtrans webhook confirms a settled payment
- **THEN** backend sends a push notification with title "Upgrade Successful!"

### Requirement: Notification persistence
The backend SHALL store every dispatched notification in the `notifications` table with `is_read: false`.

#### Scenario: Notification stored
- **WHEN** a notification is dispatched
- **THEN** a row is inserted in `notifications` with the user_id, title, body, type, and `is_read: false`

### Requirement: Notification list screen
The Flutter app SHALL provide a notification list screen showing all notifications for the logged-in user, with read/unread visual distinction and timestamps.

#### Scenario: Unread notification shown
- **WHEN** user opens the notification screen
- **THEN** unread notifications are displayed with a highlighted background

#### Scenario: Mark as read
- **WHEN** user taps a notification
- **THEN** app calls PATCH `/notifications/:id/read` and the item switches to read styling

### Requirement: Mark notification as read endpoint
The backend SHALL expose PATCH `/notifications/:id/read` to set `is_read: true` for a specific notification owned by the requesting user.

#### Scenario: Valid mark-as-read request
- **WHEN** authenticated user calls PATCH `/notifications/42/read`
- **THEN** system sets `is_read: true` and returns HTTP 200

#### Scenario: Notification belongs to different user
- **WHEN** user calls the endpoint for a notification they do not own
- **THEN** system returns HTTP 403

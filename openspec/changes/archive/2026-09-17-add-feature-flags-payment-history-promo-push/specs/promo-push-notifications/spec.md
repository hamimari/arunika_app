## ADDED Requirements

### Requirement: Background campaign delivery with history
`POST /admin/campaigns` SHALL validate the request, persist a `campaigns` row in `SENDING` state, respond 202 with it, and deliver in the background, updating `sent`/`failed` and finishing as `COMPLETED` or `FAILED` with an error message. `GET /admin/campaigns` SHALL list campaigns newest first. The subscribers segment SHALL exclude expired subscriptions.

#### Scenario: Large audience
- **WHEN** an admin sends a push campaign to all registered users
- **THEN** the request returns immediately and the backoffice history shows the campaign as SENDING until delivery completes

### Requirement: Device-wide promo topic
Every app install SHALL subscribe to FCM topic `arunika_promo`, including guests. Campaign segment `all_devices` SHALL send a single FCM message to that topic, SHALL only allow the push channel, and SHALL be marked FAILED when FCM is not configured or rejects the send.

#### Scenario: Guest receives new release promo
- **WHEN** an admin sends an `all_devices` campaign
- **THEN** a device that never logged in receives the notification

#### Scenario: Email with all devices
- **WHEN** an admin submits `segment: all_devices` with `channel: both`
- **THEN** the server responds 400

### Requirement: Campaign content links
A campaign MAY include an https `image_url` and a `link_type` of `ar_card` or `dongeng` with an existing `link_id`, delivered as FCM `data` (`type`, `campaign_id`, `link_type`, `link_id`). Unknown link targets or non-https images SHALL be rejected with 400. When a notification is tapped the app SHALL open the linked content using the same rules as an in-app tap: unlocked content opens directly, locked content prompts login for guests or opens the purchase flow for logged-in users; if the content can't be loaded the matching tab is shown.

#### Scenario: Tap opens new dongeng
- **WHEN** the user taps a notification linking to a free dongeng while the app is terminated
- **THEN** the app launches and, once the main shell is shown, opens that dongeng's player

### Requirement: Device token lifecycle
The app SHALL register its FCM token with `POST /notifications/token` when a user is logged in and when the token refreshes, and on logout SHALL delete the token and re-subscribe a fresh one to the promo topic so the previous account stops receiving user-targeted pushes. Foreground notifications SHALL be shown as a snackbar with a "Lihat" action when they carry a link.

#### Scenario: Logout
- **WHEN** a user logs out
- **THEN** the old device token is invalidated and the device keeps receiving `all_devices` campaigns

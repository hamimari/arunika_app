## ADDED Requirements

### Requirement: Subscription auto-renew state and provider are tracked
The backend SHALL record `user_subscriptions.provider = 'google_play'` whenever it grants or syncs access from a Google Play subscription. It SHALL maintain `user_subscriptions.auto_renew` as follows:
- set from Play's `autoRenewing` when a subscription purchase is verified
- set to false on RTDN `SUBSCRIPTION_CANCELED`
- set to true on `SUBSCRIPTION_RESTARTED`, `SUBSCRIPTION_RENEWED` and `SUBSCRIPTION_RECOVERED`

A cancellation SHALL NOT end access before `expires_at`. A one-off migration SHALL set `provider = 'google_play'` and `auto_renew = true` for existing subscriptions whose latest `PAID` subscription order has `provider = 'google_play'`.

#### Scenario: User cancels auto-renew in Google Play
- **WHEN** an RTDN `SUBSCRIPTION_CANCELED` notification is received for an active subscription
- **THEN** `auto_renew` SHALL become false, access SHALL continue until `expires_at`, and the subscription SHALL become renewable within 7 days of expiry

#### Scenario: User resubscribes in Google Play
- **WHEN** an RTDN `SUBSCRIPTION_RESTARTED` notification is received
- **THEN** `auto_renew` SHALL become true, and the current `expires_at` SHALL be kept

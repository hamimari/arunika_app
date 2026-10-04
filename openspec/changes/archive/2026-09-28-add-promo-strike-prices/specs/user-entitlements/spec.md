## MODIFIED Requirements

### Requirement: Successful subscription-package payment grants blanket subscription access
When an order referencing a `package_id` with `premium_packages.type = 'subscription'` transitions to `PAID`, the system SHALL upsert the user's `user_subscriptions` row with `status = 'premium'`, `package_id` set to the purchased package, and `provider` set to the order's provider. The new `expires_at` SHALL be computed from the previous expiry:
- if the user's current `expires_at` is still in the future, the new `expires_at` SHALL be that previous `expires_at` + `package.duration_days`, so days already paid for are never lost
- otherwise (no row, or a lapsed subscription), it SHALL be now + `package.duration_days`

A user with an active, unexpired subscription is granted access to all paid AR cards and dongeng, independent of individual `user_entitlements` rows.

#### Scenario: Subscription purchase grants access without per-product rows
- **WHEN** a user with no subscription purchases a `subscription`-type package and the order transitions to `PAID`
- **THEN** `user_subscriptions.status` SHALL be `premium` with `expires_at` equal to now + `package.duration_days`, and the user SHALL be granted access to every paid AR card and dongeng without individual `user_entitlements` rows being created

#### Scenario: Renewal stacks from the previous expiry
- **WHEN** a subscriber whose `expires_at` is 2026-10-31 renews with a 30-day package on 2026-10-26
- **THEN** the new `expires_at` SHALL be 2026-11-30, not 2026-11-25

#### Scenario: Lapsed subscription restarts from now
- **WHEN** a user whose `expires_at` was 2026-09-01 buys a 30-day package on 2026-10-01
- **THEN** the new `expires_at` SHALL be 2026-10-31

#### Scenario: Plan switch during renewal
- **WHEN** a Bulanan subscriber expiring 2026-10-31 renews with the 365-day Tahunan package inside the window
- **THEN** `expires_at` SHALL become 2027-10-31, and `package_id` SHALL be the Tahunan package

## ADDED Requirements

### Requirement: Renewal eligibility is exposed on the user profile
The user profile response's `subscription` object SHALL include:
- `provider` (`midtrans` | `google_play`)
- `auto_renew` (bool)
- `renewable_from` (`expires_at` − 7 days)
- `can_renew`: true only when the subscription is active, `auto_renew` is false, and now ≥ `renewable_from`

The 7-day window SHALL be a single backend constant.

#### Scenario: Inside the window
- **WHEN** a Midtrans subscription expires on 2026-10-31 and the profile is requested on 2026-10-25
- **THEN** `can_renew` SHALL be true and `renewable_from` SHALL be 2026-10-24

#### Scenario: Outside the window
- **WHEN** the same profile is requested on 2026-10-20
- **THEN** `can_renew` SHALL be false

#### Scenario: Auto-renewing subscription never renewable in-app
- **WHEN** a Google Play subscription with `auto_renew = true` is 3 days from expiry
- **THEN** `can_renew` SHALL be false

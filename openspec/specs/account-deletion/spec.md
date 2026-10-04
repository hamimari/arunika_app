# account-deletion Specification

## Purpose
TBD - created by archiving change add-play-store-release-compliance. Update Purpose after archive.
## Requirements
### Requirement: Backend deletes or anonymizes a user's data on request
The backend SHALL expose an authenticated `DELETE /user/me` endpoint. Calling it SHALL delete or anonymize the requesting user's data: the user row, their child profile(s), order history, payment history, device/push notification tokens, and per-feature progress (tracing, counting, badges). Records that must be retained for legal/accounting reasons SHALL be anonymized (user reference removed) rather than deleted outright.

#### Scenario: User deletes their account
- **WHEN** an authenticated user calls `DELETE /user/me`
- **THEN** their user row, child profile, and personal data SHALL no longer be retrievable via any authenticated endpoint, and their JWT SHALL no longer be valid for future requests

#### Scenario: Retained records are anonymized, not linked back to the user
- **WHEN** a deleted user previously had payment/order records that must be retained for accounting
- **THEN** those records SHALL be anonymized (no retrievable link to the deleted user's identity) rather than deleted

### Requirement: App provides an in-app account deletion flow
The Profile screen SHALL provide a "Hapus Akun" (Delete Account) action that requires a confirmation step (re-authentication or typed confirmation) before calling `DELETE /user/me`. On success, the app SHALL clear local session/secure storage and return the user to the landing/signup screen.

#### Scenario: User deletes account from Profile
- **WHEN** a user taps "Hapus Akun", confirms, and the deletion succeeds
- **THEN** the app SHALL clear stored credentials and navigate to the landing screen, with the user signed out

#### Scenario: Confirmation step prevents accidental deletion
- **WHEN** a user taps "Hapus Akun" but does not complete the confirmation step
- **THEN** `DELETE /user/me` SHALL NOT be called

### Requirement: Account deletion is also available without installing or logging into the app
In addition to the in-app option, users SHALL be able to request account deletion through a publicly accessible web page that does not require installing the app or being logged in (see the `landing-page` capability's account-deletion request page).

#### Scenario: Visitor requests deletion without the app
- **WHEN** someone who does not have the app installed visits the public account-deletion page
- **THEN** they SHALL be able to submit a deletion request without needing to log in or install anything


## MODIFIED Requirements

### Requirement: Popular stories list
The dongeng list screen SHALL display a "Cerita Populer — Lihat Semua" section with story rows showing cover thumbnail, title, description, and a lock/unlock icon. A story "requires premium access" (shows the lock icon) when it is not free (`is_free = false`) AND the current user's `is_unlocked` value for that story (computed from entitlements/subscription, see `user-entitlements`) is `false` — not from `is_free` alone. Tapping a locked story SHALL navigate to the premium upgrade screen instead of the dongeng player.

#### Scenario: Locked stories show lock icon
- **WHEN** a story is not free and the current user has no entitlement or active subscription covering it
- **THEN** a lock icon is displayed on the story row

#### Scenario: Unlocked stories are accessible
- **WHEN** the user taps an unlocked story row
- **THEN** the app navigates to the dongeng player screen for that story

#### Scenario: Tapping a locked story opens the upgrade flow
- **WHEN** the user taps a story row that is locked
- **THEN** the app navigates to the premium upgrade screen instead of the dongeng player

#### Scenario: Entitled story is not shown as locked even if not free
- **WHEN** a story is not free but the current user holds an active entitlement for it or an active subscription
- **THEN** no lock icon is displayed and tapping the row opens the dongeng player

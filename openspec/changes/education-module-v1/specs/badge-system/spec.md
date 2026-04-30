## ADDED Requirements

### Requirement: Badge definitions
The system SHALL maintain a static set of badge definitions seeded at startup: Beginner (5), Explorer (15), Master (30) per feature, and All-Rounder (all feature categories completed at Beginner level).

#### Scenario: Badge list is seeded
- **WHEN** the backend starts with an empty `badges` table
- **THEN** the table is populated with the defined badge rows

### Requirement: Automatic badge award on progress submission
The backend SHALL award a badge automatically when the user's cumulative progress for a feature crosses a threshold, evaluated inside the same DB transaction as the progress insert.

#### Scenario: First badge for tracing
- **WHEN** a user's tracing passed count reaches 5
- **THEN** the Beginner tracing badge is inserted into `user_badges` (idempotent — ON CONFLICT DO NOTHING)

#### Scenario: All-Rounder badge
- **WHEN** a user holds at least one Beginner badge for every feature category
- **THEN** the All-Rounder badge is awarded in the same transaction

### Requirement: User badge list endpoint
The backend SHALL expose GET `/badges` returning all badge definitions with the user's earned status and progress toward the next badge.

#### Scenario: Authenticated user fetches badges
- **WHEN** an authenticated user calls GET `/badges`
- **THEN** response includes each badge with `earned: true/false` and `progress: { current, threshold }`

#### Scenario: Unauthenticated request
- **WHEN** an unauthenticated request calls GET `/badges`
- **THEN** system returns HTTP 401

### Requirement: Badge display on profile page
The Flutter Profile page SHALL display a badge gallery showing all badges as locked (grey) or unlocked (coloured) with a progress bar toward the next badge.

#### Scenario: Unlocked badge shown
- **WHEN** user has earned the tracing Beginner badge
- **THEN** profile page shows the badge icon in full colour with "Beginner" label

#### Scenario: Locked badge shown
- **WHEN** user has not earned a badge
- **THEN** badge is shown in greyscale with progress text (e.g., "3 / 5")

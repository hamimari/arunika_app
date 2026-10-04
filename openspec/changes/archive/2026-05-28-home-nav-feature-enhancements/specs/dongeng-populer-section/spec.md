## ADDED Requirements

### Requirement: Dongeng section shows popular for new users
The system SHALL display the section "Dongeng Populer" on the home screen for guest users and logged-in users with no watch history. The section SHALL fetch data from `GET /dongeng/popular` and display the top-ranked dongeng by play count.

#### Scenario: Guest user sees popular dongeng
- **WHEN** a guest user opens the home screen
- **THEN** the section header SHALL read "Dongeng Populer" and show the most-watched dongeng

#### Scenario: Logged-in user with no history sees popular dongeng
- **WHEN** a logged-in user has no watch history (`GET /dongeng/history` returns empty)
- **THEN** the section SHALL show popular dongeng identical to the guest experience

### Requirement: Dongeng section shows continue + related for returning users
The system SHALL display incomplete dongeng (progress < 90%) at the top of the home section, followed by popular dongeng from the same category as the most recently watched. Data SHALL be fetched from `GET /dongeng/history` and `GET /dongeng/popular?category=<slug>`.

#### Scenario: Returning user sees incomplete dongeng
- **WHEN** a logged-in user has at least one dongeng with progress < 90%
- **THEN** those dongeng SHALL appear first in the home section with a progress indicator

#### Scenario: Related popular dongeng shown after incomplete items
- **WHEN** incomplete dongeng are displayed
- **THEN** popular dongeng from the same category SHALL be shown below them

### Requirement: Dongeng play event is recorded
The system SHALL call `POST /dongeng/:id/play` when a user starts playing a dongeng. The payload SHALL include `started_at` timestamp. Progress SHALL be updated via `PUT /dongeng/:id/play` with `progress_seconds` periodically during playback.

#### Scenario: Play event recorded on start
- **WHEN** a user taps to play a dongeng
- **THEN** `POST /dongeng/:id/play` SHALL be called before the player screen opens

#### Scenario: Dongeng marked complete at 90%
- **WHEN** the user's `progress_seconds / total_seconds >= 0.9`
- **THEN** the dongeng SHALL NOT appear in the incomplete list on next home screen load

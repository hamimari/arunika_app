## MODIFIED Requirements

### Requirement: Home screen limits categories to 5 with overflow link
The system SHALL display at most 5 category tiles on the home screen. If the backend returns more than 5 categories, a "Lihat Semua" text link SHALL be shown that opens Kartu AR inside the Belajar tab.

#### Scenario: 5 or fewer categories
- **WHEN** the backend returns 5 or fewer categories
- **THEN** all categories SHALL be shown without the "Lihat Semua" link

#### Scenario: More than 5 categories
- **WHEN** the backend returns more than 5 categories
- **THEN** only the first 5 SHALL be shown and a "Lihat Semua" link SHALL appear

#### Scenario: Lihat Semua navigates to Koleksi
- **WHEN** the user taps "Lihat Semua"
- **THEN** the app SHALL open the Belajar tab on Kartu AR

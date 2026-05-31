## ADDED Requirements

### Requirement: Animal categories fetched from backend
The system SHALL fetch animal categories from `GET /categories` and use the same data on both the home screen "Kategori Binatang" section and the Koleksi filter. A `CategoryRepository` with in-memory session cache SHALL be used to avoid redundant API calls.

#### Scenario: Categories load on home screen
- **WHEN** the home screen is opened
- **THEN** the "Kategori Binatang" section SHALL display categories fetched from the API

#### Scenario: Categories consistent with Koleksi
- **WHEN** a user navigates from home screen category to Koleksi
- **THEN** the same category names SHALL be present in the Koleksi dropdown filter

### Requirement: Home screen limits categories to 5 with overflow link
The system SHALL display at most 5 category tiles on the home screen. If the backend returns more than 5 categories, a "Lihat Semua" text link SHALL be shown that navigates to the Koleksi screen.

#### Scenario: 5 or fewer categories
- **WHEN** the backend returns 5 or fewer categories
- **THEN** all categories SHALL be shown without the "Lihat Semua" link

#### Scenario: More than 5 categories
- **WHEN** the backend returns more than 5 categories
- **THEN** only the first 5 SHALL be shown and a "Lihat Semua" link SHALL appear

#### Scenario: Lihat Semua navigates to Koleksi
- **WHEN** the user taps "Lihat Semua"
- **THEN** the app SHALL navigate to the Koleksi tab

### Requirement: Koleksi uses dropdown for category filter
The system SHALL replace the horizontal filter chips on the Koleksi screen with a bottom-sheet style dropdown picker. The dropdown SHALL list "Semua" plus each category from the `/categories` API.

#### Scenario: User opens category dropdown
- **WHEN** the user taps the category filter on the Koleksi screen
- **THEN** a bottom sheet SHALL appear with all available categories

#### Scenario: User selects a category
- **WHEN** the user selects a category from the bottom sheet
- **THEN** the grid SHALL filter to show only animals in that category and the bottom sheet SHALL close

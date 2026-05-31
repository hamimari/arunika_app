## ADDED Requirements

### Requirement: PremiumUpgradeScreen fetches packages from API
The system SHALL replace all usage of the static `PremiumPacks` class with a `PremiumPackRepository` that calls `GET /premium/packs?type=content` and `GET /premium/packs?type=subscription`. A `PremiumPackCubit` SHALL manage the loading, loaded, and error states for each tab.

#### Scenario: Packages load on screen open
- **WHEN** the `PremiumUpgradeScreen` is opened
- **THEN** both content and subscription package lists SHALL be fetched from the API and displayed

#### Scenario: Loading state shown while fetching
- **WHEN** the API call is in progress
- **THEN** the screen SHALL show a loading indicator instead of an empty list

#### Scenario: Error state shown on failure
- **WHEN** the API call fails (network error or non-2xx response)
- **THEN** the screen SHALL show an error message with a retry button

### Requirement: Static PremiumPacks fallback removed after stabilisation
The system SHALL remove the `lib/data/static/premium_packs.dart` file once the API is confirmed stable. Until then the file MAY remain as a reference but SHALL NOT be used by any screen.

#### Scenario: Static file not referenced by UI
- **WHEN** the Flutter app is built
- **THEN** no widget or screen SHALL import from `lib/data/static/premium_packs.dart`

### Requirement: PremiumPack model maps from API response
The existing `PremiumPack` data class SHALL be updated with a `fromJson` factory constructor. All fields (`id`, `name`, `subtitle`, `priceIdr`, `isBestValue`, `badgeLabel`) SHALL map directly from the API JSON keys (`id`, `name`, `subtitle`, `price_idr`, `is_best_value`, `badge_label`).

#### Scenario: JSON deserialised correctly
- **WHEN** the API returns a package JSON object
- **THEN** `PremiumPack.fromJson` SHALL produce a `PremiumPack` with all fields populated

#### Scenario: Nullable badge_label handled
- **WHEN** the API returns a package with `badge_label: null`
- **THEN** the resulting `PremiumPack.badgeLabel` SHALL be `null` and no badge SHALL be shown

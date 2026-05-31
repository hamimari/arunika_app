## MODIFIED Requirements

### Requirement: Category filter chips
The collection screen SHALL display a two-level dropdown selector for category filtering. The first dropdown SHALL list parent categories (plus "Semua"). The second dropdown SHALL list sub-categories for the selected parent (visible only when a parent is selected). The dropdowns replace the previous horizontal chip rows.

#### Scenario: Filtering by parent category via dropdown
- **WHEN** the user selects a parent category from the first dropdown
- **THEN** only cards in that category are shown in the grid and the sub-category dropdown becomes visible with options for that parent

#### Scenario: Filtering by sub-category via dropdown
- **WHEN** the user selects a sub-category from the second dropdown
- **THEN** only cards matching both the parent and sub-category are shown

#### Scenario: All animals shown by default
- **WHEN** the collection screen first loads
- **THEN** the first dropdown shows "Semua" selected and all animals are displayed

#### Scenario: Pre-filter applied on navigation from home
- **WHEN** the app navigates to the Koleksi screen with `categoryId` query parameter
- **THEN** the first dropdown is pre-selected with that category and the grid is filtered accordingly

## ADDED Requirements

### Requirement: Navigate to Koleksi with pre-applied category filter
When the user taps an AR card category on the home screen, the app SHALL navigate to the Koleksi screen passing the tapped category's ID as a query parameter, and the Koleksi screen SHALL apply that filter on load.

#### Scenario: Category tap on home opens filtered Koleksi
- **WHEN** the user taps an AR category chip/card on the home screen
- **THEN** the app navigates to the Koleksi tab and the grid is pre-filtered to show only cards in that category

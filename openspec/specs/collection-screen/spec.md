# collection-screen Specification

## Purpose
Defines the AR card collection ("Koleksi") screen's UI and behavior: category/sub-category filtering, and cross-screen navigation into it with a pre-applied category filter.
## Requirements
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

### Requirement: Navigate to Koleksi with pre-applied category filter
When the user taps an AR card category on the home screen, the app SHALL navigate to the Koleksi screen passing the tapped category's ID as a query parameter, and the Koleksi screen SHALL apply that filter on load.

#### Scenario: Category tap on home opens filtered Koleksi
- **WHEN** the user taps an AR category chip/card on the home screen
- **THEN** the app navigates to the Koleksi tab and the grid is pre-filtered to show only cards in that category

### Requirement: Filter bottom sheet replaces the ownership filter chip
The collection screen SHALL show a gear/settings icon button beside the category dropdown row. Tapping it SHALL open a "Filter" bottom sheet with a "Kepemilikan" section offering two radio options — "Semua" (default) and "Koleksiku" — and a "Terapkan" button. Applying SHALL filter the grid to owned-only cards when "Koleksiku" is chosen, or show all cards when "Semua" is chosen, and close the sheet. The previous "Sudah dibeli saja" filter chip SHALL be removed.

#### Scenario: Opening the filter sheet shows the current selection
- **WHEN** the user taps the gear icon
- **THEN** the "Filter" bottom sheet opens with "Kepemilikan" showing the currently active choice selected

#### Scenario: Applying "Koleksiku" filters to owned cards
- **WHEN** the user selects "Koleksiku" and taps "Terapkan"
- **THEN** the sheet closes and only unlocked/owned cards are shown

#### Scenario: Applying "Semua" shows every card
- **WHEN** the user selects "Semua" and taps "Terapkan"
- **THEN** the sheet closes and cards are shown regardless of ownership, still respecting the active category/sub-category dropdowns

#### Scenario: Old filter chip no longer present
- **WHEN** the collection screen renders
- **THEN** no "Sudah dibeli saja" chip is present anywhere on the screen

### Requirement: Locked AR cards show price and strike price
Each locked AR card in the Koleksi grid that has a `price_idr` SHALL show its price, formatted as "Rp 15.000", using the shared price tag. When `strike_price_idr` is non-null, the strike price SHALL be shown crossed out next to the price. Unlocked cards and cards without a price SHALL NOT show a price.

#### Scenario: Locked card with strike price
- **WHEN** a locked AR card has `price_idr = 15000` and `strike_price_idr = 19000`
- **THEN** the card SHALL show "Rp 15.000" and a crossed-out "Rp 19.000"

#### Scenario: Locked card without strike price
- **WHEN** a locked AR card has `price_idr = 15000` and `strike_price_idr = null`
- **THEN** the card SHALL show only "Rp 15.000"

#### Scenario: Unlocked card
- **WHEN** an AR card is unlocked for the user
- **THEN** no price SHALL be shown on it


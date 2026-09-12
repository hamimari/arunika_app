## ADDED Requirements

### Requirement: Category filter row on the dongeng screen
The dongeng list screen SHALL display a category filter row with a "Semua Kategori" dropdown (default: "Semua", showing all stories) listing top-level dongeng categories, and a second dropdown for sub-categories that appears only when the selected category has children — mirroring the collection screen's category dropdown pattern.

#### Scenario: All stories shown by default
- **WHEN** the dongeng screen first loads
- **THEN** the category dropdown shows "Semua" selected and stories from every category are displayed

#### Scenario: Filtering by category
- **WHEN** the user selects a category from the dropdown
- **THEN** only stories linked to that category (via `dongeng_category_id`) are shown

#### Scenario: Filtering by sub-category
- **WHEN** the user selects a sub-category from the second dropdown
- **THEN** only stories matching both the category and sub-category are shown

### Requirement: Filter bottom sheet replaces the ownership filter chip
The dongeng list screen SHALL show a gear/settings icon button beside the category dropdown row. Tapping it SHALL open a "Filter" bottom sheet with a "Kepemilikan" section offering two radio options — "Semua" (default) and "Koleksiku" — and a "Terapkan" button. Applying SHALL filter the list to owned-only stories when "Koleksiku" is chosen, or show all stories when "Semua" is chosen, and close the sheet. The previous "Sudah dibeli saja" filter chip SHALL be removed.

#### Scenario: Opening the filter sheet shows the current selection
- **WHEN** the user taps the gear icon
- **THEN** the "Filter" bottom sheet opens with "Kepemilikan" showing the currently active choice selected

#### Scenario: Applying "Koleksiku" filters to owned stories
- **WHEN** the user selects "Koleksiku" and taps "Terapkan"
- **THEN** the sheet closes and only unlocked/owned stories are shown

#### Scenario: Applying "Semua" shows every story
- **WHEN** the user selects "Semua" and taps "Terapkan"
- **THEN** the sheet closes and stories are shown regardless of ownership

#### Scenario: Old filter chip no longer present
- **WHEN** the dongeng screen renders
- **THEN** no "Sudah dibeli saja" chip is present anywhere on the screen

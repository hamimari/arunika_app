## ADDED Requirements

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

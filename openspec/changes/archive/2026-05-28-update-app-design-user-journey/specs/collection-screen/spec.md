## ADDED Requirements

### Requirement: Collection grid layout
The collection screen SHALL display animals in a scrollable 2-column grid. Each cell SHALL show a thumbnail, animal name, and lock/unlock state.

#### Scenario: Unlocked animal is shown in full colour
- **WHEN** an animal has been unlocked
- **THEN** its card displays a full-colour thumbnail with a green checkmark badge

#### Scenario: Locked animal is visually distinct
- **WHEN** an animal is locked
- **THEN** its card is blurred or greyed out with a lock icon overlay

### Requirement: Category filter chips
The collection screen SHALL display horizontal filter chips: Semua, Hewan Ternak, Hutan, Laut (and other relevant categories).

#### Scenario: Filtering by category
- **WHEN** the user taps a category chip (e.g., "Hutan")
- **THEN** only animals in that category are shown in the grid

#### Scenario: All animals shown by default
- **WHEN** the collection screen first loads
- **THEN** the "Semua" chip is selected and all animals are displayed

### Requirement: Star counter in header
The collection screen SHALL display a star/coin counter (e.g., ⭐ 24) in the top-right area of the header.

#### Scenario: Star count is visible
- **WHEN** the user opens the collection screen
- **THEN** the current star count is displayed with a star icon

### Requirement: Search and filter icons
The collection screen SHALL display search and filter icon buttons in the header row.

#### Scenario: Header icons are present
- **WHEN** the collection screen is displayed
- **THEN** search and filter icons are visible in the top-right area alongside the star counter

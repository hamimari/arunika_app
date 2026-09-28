# dongeng-list-screen Specification

## Purpose
Defines the dongeng (story) list screen's UI and behavior: the featured story card, the popular stories list, and the read-only player screen it links into.
## Requirements
### Requirement: Featured premium story card
The dongeng list screen SHALL display a featured story card at the top (e.g., "Petualangan Rusa") with a "Premium" badge, cover image, description, and "Baca Sekarang" button.

#### Scenario: Featured card is visible
- **WHEN** the user opens the Dongeng screen
- **THEN** a large featured story card with premium badge is displayed at the top

### Requirement: Popular stories list
The dongeng list screen SHALL display a "Cerita Populer — Lihat Semua" section with story rows showing cover thumbnail, title, description, and a lock/unlock icon. A story "requires premium access" (shows the lock icon) when it is not free (`is_free = false`) AND the current user's `is_unlocked` value for that story (computed from entitlements/subscription, see `user-entitlements`) is `false` — not from `is_free` alone. Tapping a locked story SHALL navigate to the premium upgrade screen instead of the dongeng player.

#### Scenario: Locked stories show lock icon
- **WHEN** a story is not free and the current user has no entitlement or active subscription covering it
- **THEN** a lock icon is displayed on the story row

#### Scenario: Unlocked stories are accessible
- **WHEN** the user taps an unlocked story row
- **THEN** the app navigates to the dongeng player screen for that story

#### Scenario: Tapping a locked story opens the upgrade flow
- **WHEN** the user taps a story row that is locked
- **THEN** the app navigates to the premium upgrade screen instead of the dongeng player

#### Scenario: Entitled story is not shown as locked even if not free
- **WHEN** a story is not free but the current user holds an active entitlement for it or an active subscription
- **THEN** no lock icon is displayed and tapping the row opens the dongeng player

### Requirement: Existing dongeng player preserved
The dongeng player screen (story reading/narration UI) SHALL remain visually unchanged.

#### Scenario: Player screen is not modified
- **WHEN** the user opens a story to read
- **THEN** the player screen renders identically to its pre-change state

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

### Requirement: Paid dongeng show price and strike price
Each dongeng in the dongeng list that is locked for the user and has a `price_idr` SHALL show its price, formatted as "Rp 39.000", using the shared price tag. When `strike_price_idr` is non-null, the strike price SHALL be shown crossed out next to the price. Free or already-owned dongeng SHALL NOT show a price.

#### Scenario: Locked dongeng with strike price
- **WHEN** a locked dongeng has `price_idr = 39000` and `strike_price_idr = 49000`
- **THEN** its list item SHALL show "Rp 39.000" and a crossed-out "Rp 49.000"

#### Scenario: Owned dongeng
- **WHEN** the user already owns a paid dongeng
- **THEN** its list item SHALL NOT show a price


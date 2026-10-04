# dongeng-list-screen Specification

## Purpose
Defines the dongeng (story) list screen's UI and behavior: the featured story card, the popular stories list, and the read-only player screen it links into.
## Requirements
### Requirement: Featured premium story card
The dongeng list screen SHALL display a featured story card at the top: a wide cover picture with a "Pilihan minggu ini" pill, and below it the story's title, its "{age start}–{age end} tahun · {duration}" line and a button. The button SHALL be "Baca" when the user can open the story, and "Beli" (with the price shown under the title) when the story is locked.

#### Scenario: Featured card is visible
- **WHEN** the user opens the Dongeng screen
- **THEN** a featured card with the "Pilihan minggu ini" pill, the story's title and age/duration, and a "Baca" button is displayed at the top

#### Scenario: Locked featured story
- **WHEN** the featured story is locked and has a price
- **THEN** the card SHALL show its price and a "Beli" button

### Requirement: Popular stories list
The dongeng list screen SHALL display a "Cerita Populer — Lihat Semua" section with one card per story. A story "requires premium access" when it is not free (`is_free = false`) AND the current user's `is_unlocked` value for that story (computed from entitlements/subscription, see `user-entitlements`) is `false` — not from `is_free` alone.
- A locked story with a price SHALL show its cover thumbnail with a lock badge, its title and age/duration, a "Hemat N%" pill when it is on promo, and — below a dashed rule — its price (with the crossed-out price above it when non-null) beside a "Beli" button.
- A story the user can open SHALL stay compact: thumbnail, title, age/duration and a "Baca" button. It SHALL NOT show a lock badge or a price.

Tapping a locked story or its "Beli" button SHALL open the purchase for that story, passing its product id, price, strike price and Google Play product id, or ask a signed-out user to sign in. Tapping a story the user can open SHALL open the dongeng player.

#### Scenario: Locked story on promo
- **WHEN** a story is locked, priced 100000 with strike price 112000 and `discount_percent` 11
- **THEN** its card SHALL show a lock badge, "Hemat 11%", a crossed-out "Rp 112.000", "Rp 100.000" and a "Beli" button

#### Scenario: Locked story without a promo
- **WHEN** a story is locked and priced 39000 with no strike price
- **THEN** its card SHALL show "Rp 39.000" and "Beli", and no "Hemat" pill

#### Scenario: Unlocked stories are accessible
- **WHEN** the user taps an unlocked story row or its "Baca" button
- **THEN** the app navigates to the dongeng player screen for that story

#### Scenario: Beli starts the purchase with the Play product id
- **WHEN** a signed-in user taps "Beli" on a locked story whose `play_product_id` is `sku_yunus`
- **THEN** the app SHALL open the payment screen for that story's product with `sku_yunus` set

#### Scenario: Entitled story is not shown as locked even if not free
- **WHEN** a story is not free but the current user holds an active entitlement for it or an active subscription
- **THEN** no lock badge or price is displayed and it shows "Baca"

#### Scenario: Narrow phone with enlarged text
- **WHEN** the list is shown on a 360-pixel-wide screen with 140% text
- **THEN** the header, section title and story cards SHALL NOT overflow

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
Each dongeng in the dongeng list that is locked for the user and has a `price_idr` SHALL show its price, formatted as "Rp 39.000", together with a "Beli" button. When `strike_price_idr` is non-null, the strike price SHALL be shown crossed out above the price. Free or already-owned dongeng SHALL NOT show a price.

#### Scenario: Locked dongeng with strike price
- **WHEN** a locked dongeng has `price_idr = 39000` and `strike_price_idr = 49000`
- **THEN** its list item SHALL show "Rp 39.000" and a crossed-out "Rp 49.000"

#### Scenario: Owned dongeng
- **WHEN** the user already owns a paid dongeng
- **THEN** its list item SHALL NOT show a price


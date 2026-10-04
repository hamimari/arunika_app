## Why

Several UI inconsistencies and incomplete interactions were identified across the app — locked content lacks visual feedback, category navigation is broken, printable cards are static, and the AR card detail flow skips important context. These fixes close the gap between the designed experience and the shipped product.

## What Changes

- **Landing screen**: Fix `BoxDecoration` background color to reduce contrast with the page background
- **AR card categories on home**: Replace emoji image with `imageUrl` from category; tapping a category navigates to the Koleksi page pre-filtered to that category; Koleksi page uses a dropdown (instead of chips) for category selection
- **Premium access without login**: When a user taps a locked premium feature without being logged in, show a dialog prompting login or register first; after successful auth, redirect to Paket Konten
- **Kartu printable (printable cards)**: Fetch card data from the backend via AR card categories; backend generates a downloadable A4 PDF with cards sized 75×110 mm (optimised to fit as many per page as possible); frontend downloads the file; share icon replaced with download icon
- **Koleksiku card detail**: Tapping a card shows a detail screen (card image, fun fact, play-sound button, and a direct AR-launch button) before opening the AR scanner
- **Dongeng populer lock state**: When logged in, paid dongeng cards on the home page show a lock icon and grey overlay — consistent with the AR card category treatment

## Capabilities

### New Capabilities

- `printable-cards`: Backend PDF generation from AR card categories (A4, 75×110 mm cards, optimised layout); Flutter download trigger; download icon on card list
- `ar-card-detail`: Detail screen shown before AR launch — displays card image, fun fact, play-sound button, and a launch-AR button

### Modified Capabilities

- `collection-screen`: Category selector changes from chips to a dropdown; category tap from home navigates with pre-applied filter
- `home-screen`: Dongeng populer section shows lock icon + grey overlay for paid content when user is logged in; AR category images use `imageUrl` not emoji
- `splash-screen`: Fix landing screen `BoxDecoration` color contrast
- `premium-upgrade-screen`: Unauthenticated premium tap triggers login/register dialog, then redirects to Paket Konten after success

## Impact

- **Flutter**: `landing_screen.dart` (color), `new_home_screen.dart` (dongeng lock overlay, AR category image), `collection_screen.dart` + `collection_bloc.dart` (dropdown filter + pre-filter navigation), `ar_card_detail_screen.dart` (new screen), `printable_cards_screen.dart` (download icon + PDF fetch), auth guard dialog
- **Backend (Go)**: New `GET /ar/printable-pdf?category_id=<uuid>` endpoint; PDF generation using a Go PDF library (e.g., `gofpdf`); streams A4 PDF with AR card images at 75×110 mm
- **No breaking API changes** — new endpoint only; existing `/ar/categories` and `/ar/cards` unchanged

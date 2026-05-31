## Context

The Arunika app is a Flutter/Go mobile application for children's educational content featuring dongeng (stories), AR cards, and a premium subscription model. The current build has several gaps between the intended design and shipped behaviour:

- The landing screen `BoxDecoration` uses a color that clashes with the page background
- AR card categories on the home screen display emojis instead of category images
- Tapping a category on the home screen does not navigate to the Koleksi page with a pre-applied filter
- The Koleksi page uses chip-based category selection, which requires a redesign to a dropdown
- Unauthenticated users who tap premium-locked content reach the premium page directly without being asked to log in first
- Printable cards are hardcoded/static; there is no PDF generation on the backend
- Tapping a card on Koleksiku immediately opens the AR scanner without showing card details (image, fun fact, sounds)
- Paid dongeng on the home page do not show a lock icon or grey overlay when the user is logged in

The backend uses Go/Gin/GORM. Flutter uses BLoC + `go_router`. DI is via `get_it`. Fonts are Poppins via `google_fonts`. Brand colours: orange `#FF8A3D`, purple `#6C5CE7`, gold `#FFE08A`, bg `#F7F8FC`, text dark `#2D2D2D`.

## Goals / Non-Goals

**Goals:**
- Fix landing screen background contrast
- Render AR category images using `imageUrl` field instead of emoji on home screen
- Wire category tap on home to navigate to Koleksi with pre-filter applied
- Replace Koleksi chip selector with a dropdown (`DropdownButton` or `DropdownButtonFormField`)
- Add auth-guard dialog (login / register) before premium upsell for unauthenticated users; redirect to Paket Konten after success
- Backend: `GET /ar/printable-pdf?category_id=<uuid>` — generate A4 PDF, cards at 75×110 mm, packed as tightly as possible, return as `application/pdf`
- Flutter: download the PDF and open with the device's file opener; replace share icon with download icon on the printable cards screen
- New `ArCardDetailScreen` showing card image, fun fact, play-sound button, and launch-AR button, inserted before the AR scanner
- Dongeng populer: show lock icon + semi-transparent grey overlay on paid cards when the user is logged in

**Non-Goals:**
- Re-design the full Koleksi or home screens beyond the specified changes
- Implement offline PDF caching
- Change the authentication flow itself (login/register screens stay as-is)
- Add new payment integrations

## Decisions

### 1. AR Category Image vs Emoji
Use `ArCardCategory.imageUrl` directly in a `CachedNetworkImage` (or `Image.network`) widget on the home screen category rail. Fall back to the emoji text if `imageUrl` is empty. This aligns with the existing `ArCardResponse` pattern and avoids encoding images in the category name.

### 2. Koleksi Category Selector: Dropdown
Replace `_CategoryChips` / `_SubCategoryChips` with a two-level `DropdownButton<String?>` — one for parent category, one for sub-category (shown only when a parent is selected). This reduces vertical space and scales better as category count grows. The BLoC events `FilterByCategory` and `FilterBySubCategory` remain unchanged; only the UI widget changes.

**Alternative considered:** Keep chips, increase wrapping — rejected because it consumes too much vertical space on small screens.

### 3. Home → Koleksi Pre-filter Navigation
Pass `categoryId` and/or `subCategoryId` as query parameters via `go_router` when navigating from home to `/koleksi`. On arrival, the `CollectionBloc` dispatches `FilterByCategory(categoryId)` from `initState` / `onInit`. This avoids shared state between screens.

### 4. Auth Guard for Premium
Add a helper `guardPremium(context, {required VoidCallback onAuthenticated})` that:
1. Checks `AuthNotifier.isLoggedIn`
2. If not logged in: shows a `showDialog` with "Login" / "Daftar" buttons → navigates to the respective screen; after returning, if now logged in, calls `onAuthenticated`
3. If logged in but not premium: navigates to `/premium`
4. Calls `onAuthenticated` only when fully authenticated and premium

This replaces the current direct `context.push('/premium')` calls across the app.

### 5. PDF Generation on Backend
Use `github.com/jung-kurt/gofpdf` (or `github.com/signintech/gopdf`) to generate an A4 PDF (210×297 mm). Cards are 75×110 mm. With 2 mm gutters, a row fits 2 cards (2×75 + 3×2 = 156 mm < 210 mm) and a column fits 2 rows (2×110 + 3×2 = 226 mm < 297 mm) → **4 cards per page**. The handler fetches AR cards by `category_id`, downloads each card's `file_url` image and renders it centred in the card cell, then streams the result as `application/pdf` with `Content-Disposition: attachment`.

**Alternative considered:** Client-side PDF generation in Flutter — rejected because Flutter PDF libraries have limited image-from-URL support and add significant APK size.

### 6. AR Card Detail Screen
New `ArCardDetailScreen(card: ArCardResponse)` stateful widget:
- Top: card image (from `imageUrl`, full-width, rounded corners)
- Middle: fun fact text (`card.funFact` field, or a placeholder if empty)
- Bottom row: "Putar Suara" button (`card.audioUrl`) + "Lihat AR" button → pushes `ArCoreSurfacePlaceScreen`

The existing `_ArCardItem.onTap` in `collection_screen.dart` pushes `ArCardDetailScreen` instead of `ArCoreSurfacePlaceScreen` directly.

### 7. Dongeng Populer Lock State
Reuse the existing `isLocked = !dongeng.isFree && isLoggedIn` pattern (note: show lock only when logged in — a guest can't buy, so lock is irrelevant to them). Add a `Positioned.fill` semi-transparent black overlay (`Colors.black.withValues(alpha: 0.35)`) inside the card `Stack` and a lock icon badge at bottom-right, consistent with the AR card treatment already implemented.

## Risks / Trade-offs

- **PDF image downloads on server**: Fetching remote images at PDF-generation time adds latency. → Mitigation: set a reasonable HTTP timeout (5 s); skip images that fail to load (render a placeholder rectangle).
- **`gofpdf` dependency size**: Minor Go module size increase. → Acceptable; no impact on APK.
- **Auth-guard dialog UX**: After login/register, the user returns via `Navigator.pop` which may not always return the correct result. → Use `await context.push('/login')` and re-check `AuthNotifier.isLoggedIn` on return rather than relying on a callback parameter.
- **Dropdown vs chips regression**: Existing deep-link tests that trigger chip filter events will need updating if any exist. → Check `collection_bloc_test.dart`; events are unchanged so impact is minimal.
- **`ArCardCategory.imageUrl` may be null/empty** for legacy seed data. → Always fall back to emoji text widget.

## Migration Plan

1. Backend: add `gofpdf` dependency; implement `/ar/printable-pdf` handler; deploy
2. Flutter: update home AR category widget (image); update Koleksi dropdown; add auth-guard helper; add `ArCardDetailScreen`; update `_ArCardItem.onTap`; update printable cards screen (download icon + PDF fetch); fix landing BoxDecoration color; fix dongeng populer overlay
3. No database migrations required
4. Rollback: revert commits individually — each fix is isolated

## Open Questions

- Does `ArCardCategory` already have an `imageUrl` field in the backend model and API response, or does it need to be added? (Assume yes based on prior session context; verify at implementation time.)
- Does `DongengResponse` have an `isFree` boolean, or is the free/paid distinction determined differently? (Assume `isFree` exists based on `_StoryCardWidget` code already using it.)
- Should the PDF include the card title text below the image, or image only? (Assume image + title for better usability.)

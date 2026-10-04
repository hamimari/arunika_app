## 1. Landing Screen Background Fix

- [x] 1.1 Locate the `BoxDecoration` on the landing/welcome screen that has high-contrast background color
- [x] 1.2 Change the background color to `#F7F8FC` (app background) or a close neutral tone that does not clash
- [x] 1.3 Verify the splash-to-landing transition has no harsh color jump on both light/dark device themes

## 2. AR Card Categories — Image URL on Home Screen

- [x] 2.1 Locate the AR category rail widget in `new_home_screen.dart`
- [x] 2.2 Replace the emoji `Text` widget with a `Image.network(category.imageUrl)` widget
- [x] 2.3 Add a fallback to the emoji `Text` widget when `imageUrl` is empty or the image fails to load
- [x] 2.4 Verify category images render correctly and fallback works for empty `imageUrl`

## 3. AR Category Tap → Navigate to Koleksi with Filter

- [x] 3.1 Update the category tap handler in `new_home_screen.dart` to call `context.push('/koleksi?categoryId=<id>')`
- [x] 3.2 Update the `CollectionScreen` / `go_router` route to accept a `categoryId` query parameter
- [x] 3.3 In `collection_bloc_handler.dart` (or `CollectionScreen.initState`), dispatch `FilterByCategory(categoryId)` if the parameter is present on load
- [x] 3.4 Verify tapping a home category opens Koleksi pre-filtered to that category

## 4. Koleksi Category Selector — Chips → Dropdown

- [x] 4.1 Remove `_CategoryChips` and `_SubCategoryChips` widgets from `collection_screen.dart`
- [x] 4.2 Add a `DropdownButton<String?>` for parent categories (options: "Semua" + list of parent categories)
- [x] 4.3 Add a second `DropdownButton<String?>` for sub-categories, visible only when a parent is selected
- [x] 4.4 Wire both dropdowns to dispatch `FilterByCategory` and `FilterBySubCategory` bloc events
- [x] 4.5 Ensure the dropdown values are pre-populated when navigating from the home screen with a `categoryId`
- [x] 4.6 Run `dart analyze lib/` and fix any issues

## 5. Auth Guard Before Premium Upsell

- [x] 5.1 Create a `guardPremium(BuildContext context)` helper function in a shared utilities file (e.g., `lib/core/utils/auth_guard.dart`)
- [x] 5.2 The helper SHALL check `AuthNotifier.isLoggedIn`; if not logged in, show a dialog with "Login" and "Daftar Akun" options
- [x] 5.3 On "Login" tapped: `await context.push('/login')`; on return, if now logged in, `context.push('/premium')`
- [x] 5.4 On "Daftar Akun" tapped: `await context.push('/register')`; on return, if now logged in, `context.push('/premium')`
- [x] 5.5 Replace direct `context.push('/premium')` calls that are currently reached by unauthenticated users with `guardPremium(context)`
- [x] 5.6 Verify: unauthenticated user taps locked content → dialog appears → login → Paket Konten screen

## 6. Printable Cards — Backend PDF Endpoint

- [x] 6.1 Add `gofpdf` (or `gopdf`) dependency to the Go backend module (`go get`)
- [x] 6.2 Create `handlers/printable_card_handler.go` with `GetPrintablePDF(c *gin.Context)` handler
- [x] 6.3 Handler fetches AR cards for the given `category_id` from the database
- [x] 6.4 For each card, fetch `file_url` image bytes with a 5 s timeout; use a grey placeholder on failure
- [x] 6.5 Generate A4 PDF (210×297 mm), 2 columns × 2 rows per page (75×110 mm cells, 2 mm gutters), card image centred + title below
- [x] 6.6 Stream the PDF with `Content-Type: application/pdf` and `Content-Disposition: attachment; filename="kartu-ar.pdf"`
- [x] 6.7 Register route `GET /ar/printable-pdf` in `routes/router.go`
- [x] 6.8 Write a unit test for the PDF handler (mock DB; verify response headers and non-empty body)
- [x] 6.9 Run `go build ./...` and verify no compilation errors

## 7. Printable Cards — Flutter Download

- [x] 7.1 Add `dio` (or use existing HTTP client) + `open_file` (or `flutter_file_dialog`) dependency to `pubspec.yaml` if not present
- [x] 7.2 In the printable cards screen, replace the share icon/button widget with a download icon (`Icons.download_rounded`)
- [x] 7.3 On download icon tap: call `ArApi.getPrintablePdf(categoryId)` and save the response bytes to the device downloads path
- [x] 7.4 After saving, open the file using the device's native PDF viewer via `open_file` or equivalent
- [x] 7.5 Show a loading indicator while the download is in progress
- [x] 7.6 Show an error snackbar if the download or save fails
- [x] 7.7 Add `getPrintablePdf(String categoryId)` method to `ArApi` and update `ArRepository`
- [x] 7.8 Add `arPrintablePdf` constant to `lib/constants/api_paths.dart`
- [x] 7.9 Run `dart analyze lib/` and fix any issues

## 8. AR Card Detail Screen

- [x] 8.1 Create `lib/presentation/screens/vocab/ar_card_detail_screen.dart` with `ArCardDetailScreen(card: ArCardResponse)`
- [x] 8.2 Top section: full-width `Image.network(card.imageUrl)` with rounded top corners
- [x] 8.3 Middle section: "Tahukah Kamu?" title + `card.funFact` body text; show placeholder text if `funFact` is empty
- [x] 8.4 Bottom row: "Putar Suara" `ElevatedButton` that plays/stops `card.audioUrl` using `just_audio` or existing audio player
- [x] 8.5 Bottom row: "Lihat AR" `ElevatedButton` that pushes `ArCoreSurfacePlaceScreen(modelUrl: card.fileUrl!, soundUrl: card.audioUrl ?? '')`
- [x] 8.6 In `collection_screen.dart`, update `_ArCardItem.onTap` (unlocked branch) to push `ArCardDetailScreen` instead of `ArCoreSurfacePlaceScreen` directly
- [x] 8.7 Run `dart analyze lib/` and fix any issues

## 9. Dongeng Populer Lock Overlay on Home Screen

- [x] 9.1 In `new_home_screen.dart`, locate `_StoryCardWidget`
- [x] 9.2 Update `isLocked` logic to `!dongeng.isFree && isLoggedIn` (only show lock when user is authenticated)
- [x] 9.3 Add a `Positioned.fill` semi-transparent grey overlay (`Colors.black.withValues(alpha: 0.35)`) inside the card `Stack` when `isLocked` is true, placed above the image but below the lock icon badge
- [x] 9.4 Verify: logged-in user sees grey overlay + lock on paid cards; guest user sees no overlay
- [x] 9.5 Run `dart analyze lib/` — zero errors

## 10. Unit Tests — Backend (Go)

- [x] 10.1 Create `services/printable_card_service_test.go` — test: valid category returns list of AR cards for PDF generation
- [x] 10.2 Add test: category with no cards returns empty slice (not an error)
- [x] 10.3 Add test: unknown `category_id` returns `gorm.ErrRecordNotFound` or empty result
- [x] 10.4 Create `handlers/printable_card_handler_test.go` — test: `GET /ar/printable-pdf?category_id=<valid>` returns HTTP 200, `Content-Type: application/pdf`, and non-empty body
- [x] 10.5 Add handler test: response has `Content-Disposition: attachment; filename="kartu-ar.pdf"` header
- [x] 10.6 Add handler test: `GET /ar/printable-pdf` without `category_id` returns HTTP 400
- [x] 10.7 Add handler test: `GET /ar/printable-pdf?category_id=<non-existent>` returns HTTP 404
- [x] 10.8 Add handler test: card image fetch failure (mock HTTP timeout) still returns HTTP 200 PDF with placeholder cell (graceful degradation)
- [x] 10.9 Run `go test ./...` — confirm all new and existing tests pass

## 11. Unit Tests — Flutter: CollectionBloc

- [x] 11.1 Update `test/presentation/screens/collection_bloc_test.dart` — test: initial load emits `CollectionLoaded` with all cards and no active category filter
- [x] 11.2 Add test: `FilterByCategory(categoryId)` emits `CollectionLoaded` with only cards matching that category
- [x] 11.3 Add test: `FilterByCategory(null)` resets filter and emits all cards ("Semua")
- [x] 11.4 Add test: `FilterBySubCategory(subCategoryId)` emits `CollectionLoaded` with cards matching parent + sub-category
- [x] 11.5 Add test: `FilterBySubCategory(null)` clears sub-category filter, retains parent filter
- [x] 11.6 Add test: navigating with pre-set `categoryId` triggers `FilterByCategory` on bloc init and emits pre-filtered `CollectionLoaded`
- [x] 11.7 Run `flutter test test/presentation/screens/collection_bloc_test.dart` — all pass

## 12. Unit Tests — Flutter: ArRepository

- [x] 12.1 Update `test/data/repositories/ar_repository_test.dart` — test: `getPrintablePdf(categoryId)` calls correct endpoint `GET /ar/printable-pdf?category_id=<id>` and returns bytes
- [x] 12.2 Add test: `getPrintablePdf` throws / returns error when backend returns non-200 status
- [x] 12.3 Run `flutter test test/data/repositories/ar_repository_test.dart` — all pass

## 13. Unit Tests — Flutter: Auth Guard

- [x] 13.1 Create `test/core/utils/auth_guard_test.dart`
- [x] 13.2 Add test: `guardPremium` when user is not logged in — shows dialog with "Login" and "Daftar Akun" options
- [x] 13.3 Add test: `guardPremium` when user chooses "Login" and login succeeds — navigates to `/premium`
- [x] 13.4 Add test: `guardPremium` when user chooses "Daftar Akun" and registration succeeds — navigates to `/premium`
- [x] 13.5 Add test: `guardPremium` when dialog is dismissed — no navigation occurs
- [x] 13.6 Add test: `guardPremium` when user is already logged in — navigates directly to `/premium` without showing dialog
- [x] 13.7 Run `flutter test test/core/utils/auth_guard_test.dart` — all pass

## 14. Unit Tests — Flutter: ArCardDetailScreen Widget

- [x] 14.1 Create `test/presentation/screens/vocab/ar_card_detail_screen_test.dart`
- [x] 14.2 Add widget test: screen renders card image, "Tahukah Kamu?" title, fun fact text, "Putar Suara" button, and "Lihat AR" button when `card.funFact` is non-empty
- [x] 14.3 Add widget test: screen shows placeholder "Fun fact belum tersedia untuk kartu ini." when `card.funFact` is null or empty
- [x] 14.4 Add widget test: tapping "Putar Suara" triggers audio playback (mock audio player; verify `play()` called)
- [x] 14.5 Add widget test: tapping "Lihat AR" pushes `ArCoreSurfacePlaceScreen` onto the navigator (verify route pushed with correct `modelUrl` and `soundUrl`)
- [x] 14.6 Run `flutter test test/presentation/screens/vocab/ar_card_detail_screen_test.dart` — all pass

## 15. Unit Tests — Flutter: Home Screen Bloc

- [x] 15.1 Update `test/presentation/screens/home/home_bloc_test.dart` — test: `_StoryCardWidget` renders with `isLocked = true` when user is logged in and `dongeng.isFree = false`
- [x] 15.2 Add test: `isLocked = false` when user is not logged in (guest), even if `dongeng.isFree = false`
- [x] 15.3 Add test: `isLocked = false` when `dongeng.isFree = true` regardless of auth state
- [x] 15.4 Add test: AR category item uses `imageUrl` (non-empty) → `Image.network` widget is found in tree
- [x] 15.5 Add test: AR category item uses emoji fallback when `imageUrl` is empty → `Text` widget with emoji found in tree
- [x] 15.6 Run `flutter test test/presentation/screens/home/home_bloc_test.dart` — all pass

## 16. Final Verification

- [x] 16.1 Run `dart analyze lib/` — confirm zero errors across all changed files
- [x] 16.2 Run `flutter test` — confirm all Flutter unit and widget tests pass
- [x] 16.3 Run `go test ./...` in the backend — confirm all Go tests pass
- [x] 16.4 Manually test the 6 user-facing changes on a device or emulator

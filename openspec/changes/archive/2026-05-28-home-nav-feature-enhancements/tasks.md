## 1. Bottom Nav Icons & Labels

- [x] 1.1 Replace home tab icon with a sun icon (e.g., `Iconsax.sun` or `Icons.wb_sunny_rounded`)
- [x] 1.2 Replace collection tab icon with a card-stack icon (e.g., `Iconsax.card` or `Iconsax.layer`)
- [x] 1.3 Replace dongeng tab icon with a fairy-tale/open-book icon (e.g., `Iconsax.book_1` or `Iconsax.story`)
- [x] 1.4 Rename "Orang Tua" label to "Profil" in `AppStrings` and update nav item
- [x] 1.5 Ensure scanner tab remains always centered in the nav bar (no position change)
- [x] 1.6 Remove the QR scan button from the Orang Tua / Profil tab screen if present

## 2. Background Color & Visual Vibe

- [x] 2.1 Apply warm orange gradient background (`Color(0xFFFFEDD5)` → `AppColors.pageBackground`) to the home screen scaffold
- [x] 2.2 Apply the same warm orange gradient background to `new_dongeng_list_screen.dart`
- [x] 2.3 Apply the same warm orange gradient background to `collection_screen.dart`

## 3. Fix Back Button on Auth Screens

- [x] 3.1 Remove `AppBar` from `signin_screen.dart` (the custom `IconButton` in body already handles back navigation)
- [x] 3.2 Remove `AppBar` from `signup_screen.dart` (same reason)
- [x] 3.3 Verify that `Navigator.maybePop()` on the custom back button correctly pops both screens

## 4. Backend — Banner API

- [x] 4.1 Merge `BannerApi` and `BannerItem` from `feature/education-module-v1` into the main branch
- [x] 4.2 Update `BannerItem` model to include `type` (`promo`, `daily_animal`, `feature`), `is_active`, and `sort_order` fields
- [x] 4.3 Create `BannerRepository` wrapping `BannerApi.getActiveBanners()` with error handling (returns empty list on failure)
- [x] 4.4 Register `BannerRepository` in the DI locator

## 5. Backend — Categories API

- [x] 5.1 Create `CategoryApi` with `GET /categories` endpoint call
- [x] 5.2 Create `CategoryItem` model (`id`, `name`, `emoji`, `slug`)
- [x] 5.3 Create `CategoryRepository` with in-memory session cache
- [x] 5.4 Register `CategoryRepository` in the DI locator

## 6. Backend — Dongeng Watch History API

- [x] 6.1 Create `DongengHistoryApi` with:
  - `POST /dongeng/:id/play` (record play start)
  - `PUT /dongeng/:id/play` (update progress_seconds)
  - `GET /dongeng/history` (returns list of partially-watched dongeng)
  - `GET /dongeng/popular` and `GET /dongeng/popular?category=<slug>`
- [x] 6.2 Create `DongengHistoryItem` model (`dongeng_id`, `progress_seconds`, `total_seconds`, `started_at`)
- [x] 6.3 Create `DongengHistoryRepository` wrapping the API calls
- [x] 6.4 Register `DongengHistoryRepository` in the DI locator
- [x] 6.5 Call `POST /dongeng/:id/play` from `DongengListBloc` when a dongeng item is selected

## 7. Home Screen — Banner Carousel

- [x] 7.1 Create `HomeBannerBloc` (or `HomeBannerCubit`) with states: loading, loaded, empty
- [x] 7.2 Build `_BannerCarousel` widget using `PageView` for horizontal swipe
- [x] 7.3 Add dot indicator below carousel that updates with page position
- [x] 7.4 Implement `_PromobannerCard` for `type: "promo"` banners (image + title + CTA)
- [x] 7.5 Implement `_DailyAnimalBannerCard` for `type: "daily_animal"` banners (emoji, name, fact)
- [x] 7.6 Remove standalone `_DailyAnimalCard` widget from `new_home_screen.dart`
- [x] 7.7 Replace static `_HeroBanner` with the new `_BannerCarousel` widget
- [x] 7.8 Hide carousel section entirely when banner list is empty

## 8. Home Screen — Dongeng Populer Section

- [x] 8.1 Create `HomeDongengSectionBloc` with logic: if guest/no history → fetch popular; if history → fetch incomplete + related popular
- [x] 8.2 Rename "Lanjutkan Petualangan" label to "Dongeng Populer" in section header
- [x] 8.3 Show progress indicator bar on story cards when the dongeng is partially watched
- [x] 8.4 Wire up section to `HomeDongengSectionBloc` replacing hardcoded `_kStories` list

## 9. Home Screen — Kategori Binatang

- [x] 9.1 Rename "Kategori Dunia" to "Kategori Binatang" in section header
- [x] 9.2 Fetch categories via `CategoryRepository` and render in `_CategoriesSection`
- [x] 9.3 Limit display to first 5 categories; show "Lihat Semua" link if count > 5
- [x] 9.4 "Lihat Semua" link navigates to the Koleksi tab

## 10. Koleksi Screen — Dynamic Categories & Dropdown Filter

- [x] 10.1 Fetch categories via `CategoryRepository` in `CollectionBlocHandler`
- [x] 10.2 Build a `_CategoryDropdown` widget that shows a bottom-sheet picker on tap
- [x] 10.3 Replace horizontal `ListView` of filter chips with the `_CategoryDropdown` widget
- [x] 10.4 Ensure selected category from dropdown filters the animal grid (wire to `FilterAnimals` event)
- [x] 10.5 Style the dropdown button to match premium design (rounded card with chevron icon)

## 11. QA & Cleanup

- [ ] 11.1 Test bottom nav on both guest and logged-in states (4 tabs vs 5 tabs)
- [ ] 11.2 Test banner carousel with 0, 1, and multiple banners
- [ ] 11.3 Test dongeng section for guest, new logged-in user (no history), and returning user
- [ ] 11.4 Test category count edge cases: 0, 5, and 6+ categories
- [ ] 11.5 Test Koleksi dropdown — open, select, dismiss with no selection
- [ ] 11.6 Test back button on sign-in and sign-up screens (iOS + Android)
- [x] 11.7 Run `flutter analyze` and resolve any new warnings

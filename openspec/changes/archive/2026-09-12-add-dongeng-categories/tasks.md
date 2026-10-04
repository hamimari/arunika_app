## 1. Backend — Schema (`dongeng-categories-cms`)

- [x] 1.1 Migration `db/migrations/V43__create_dongeng_categories.sql`: create `dongeng_categories` table (id, name, emoji, image_url, parent_id self-FK, sort_order, timestamps, is_deleted) + index on `parent_id`, per design.md §1
- [x] 1.2 Same migration: add nullable `dongeng_category_id` / `dongeng_sub_category_id` FK columns to `dongengs`, both referencing `dongeng_categories(id) ON DELETE SET NULL` — additive, does not touch the existing `category_id` column
- [x] 1.3 Seed `db/seeds/R__seed_dongeng_categories.sql`: idempotently insert "Fairy Tales" and "Islamic" as top-level categories, per design.md §1
- [x] 1.4 Add `models/dongeng_category.go` (copy of `models/ar_card_category.go`, renamed) with `FindTopLevelDongengCategories(db)`
- [x] 1.5 Update `models/dongeng.go`: add `DongengCategoryID`, `DongengSubCategoryID`, `CategoryRef`, `SubCategoryRef` fields per design.md §2
- [x] 1.6 Update the dongeng list/detail query functions to `Preload("CategoryRef").Preload("SubCategoryRef")` and accept optional `dongeng_category_id`/`dongeng_sub_category_id` filters

## 2. Backend — API (`dongeng-categories-cms`)

- [x] 2.1 Add public `GET /dongeng-categories` route + handler + service method (mirrors `GET /ar/categories`)
- [x] 2.2 Update `GET /fairy-tales` and `GET /fairy-tales/:id` handlers to pass through the new query filters and include `category_ref`/`sub_category_ref` in the response
- [x] 2.3 Add admin CRUD service methods `List/Create/Get/Update/Delete/ToggleVisibility DongengCategory` in `services/admin_content_service.go`, copied from the `ArCardCategory` equivalents
- [x] 2.4 Add matching admin handlers in `handlers/admin_content_handler.go` and register all 6 routes under `/admin/content/dongeng-categories` in `routes/router.go`
- [x] 2.5 Update the admin fairy-tales create/update handler to accept `dongeng_category_id`/`dongeng_sub_category_id` in the request body

## 3. Backend — Tests (`dongeng-categories-cms`)

- [x] 3.1 `services/admin_content_service_test.go` (or a new file): sqlmock-based tests for List/Create/Get/Update/Delete/ToggleVisibility on `DongengCategory`, following the existing `setupAdminContentDB` pattern
- [x] 3.2 Test `GET /dongeng-categories` returns top-level categories with children, excluding soft-deleted ones
- [x] 3.3 Test `GET /fairy-tales` filtering by `dongeng_category_id`/`dongeng_sub_category_id` and that responses include `category_ref`
- [x] 3.4 Run `go test ./...` in `arunika-backend` and confirm everything passes — 339 passed, 0 failed; `go build`/`go vet` clean

## 4. Backoffice — Dongeng Categories page (`dongeng-categories-backoffice`)

- [x] 4.1 Add `dongengCategoriesApi` to `src/api/content.ts` (`contentApi('dongeng-categories')`)
- [x] 4.2 Add `src/pages/content/DongengCategoriesPage.tsx`, copied from `ArCardCategoriesPage.tsx` with labels/resource swapped
- [x] 4.3 Register the route in `src/App.tsx` and the sidebar menu entry in `src/components/AppLayout.tsx` (under Content, next to "AR Card Categories")
- [x] 4.4 Add "Category"/"Sub-category" `Select` fields to `FairyTalesPage.tsx`'s create/edit form, sourced from `dongengCategoriesApi`, bound to `dongeng_category_id`/`dongeng_sub_category_id`, with the sub-category field conditional on the chosen category having children

## 5. Backoffice — Tests (`dongeng-categories-backoffice`)

- [x] 5.1 Add `describe('dongengCategoriesApi', ...)` to `src/test/api/content.test.ts` mirroring the `arCardsApi`/`bannersApi` blocks
- [x] 5.2 Add `src/test/pages/DongengCategoriesPage.test.tsx` following the `ProductsPage.test.tsx` render pattern (QueryClientProvider + axios-mock-adapter)
- [x] 5.3 Run the backoffice test suite and confirm everything passes — 52/52 passed, build + lint clean (repo needed Node v24 instead of the default v16 to run vitest/rolldown; not a change I made)

## 6. Flutter — Data layer

- [x] 6.1 Add `lib/data/models/response/dongeng_category.dart` (mirrors `ArCardCategory`)
- [x] 6.2 Update `DongengResponse` to parse `dongeng_category_id`/`dongeng_sub_category_id`/`category_ref`/`sub_category_ref` (adjusted from the task's literal `category_id`/`sub_category_id` wording to match the actual backend contract in design.md §2/§4 — the dongeng FK columns are named `dongeng_category_id`/`dongeng_sub_category_id`, unlike `ar_cards`' plain `category_id`, to avoid colliding with the pre-existing generic `dongengs.category_id` column)
- [x] 6.3 Update `FairyTalesApi`: add `getCategories()`, extend `findAll` with optional `categoryId`/`subCategoryId` query params
- [x] 6.4 Update `FairyTalesRepository` to match

## 7. Flutter — Dongeng screen category filter (`dongeng-list-screen`)

- [x] 7.1 Update `DongengListEvent`/`DongengListState`: add `FilterByDongengCategory`/`FilterByDongengSubCategory` events and `categories`/`activeCategoryId`/`activeSubCategoryId` on `DongengListLoaded`
- [x] 7.2 Update `DongengListBloc`: fetch categories alongside the story list in `_onLoad` (`Future.wait`, mirrors `CollectionBlocHandler._onLoad`), apply category/sub-category filtering in `_filtered()` while preserving the existing highlight-pin and ownedOnly behavior
- [x] 7.3 Add the category/sub-category dropdown row to `new_dongeng_list_screen.dart` — extracted a shared `lib/presentation/screens/widgets/category_dropdowns.dart` (`CategoryDropdowns`/`FilterIconButton`) used by both `new_dongeng_list_screen.dart` and `collection_screen.dart`, replacing the latter's private `_CategoryDropdowns`/`_StyledDropdown`

## 8. Flutter — Filter bottom sheet on both screens (`dongeng-list-screen`, `collection-screen`)

- [x] 8.1 Add a shared `lib/presentation/screens/widgets/ownership_filter_sheet.dart`: a `showModalBottomSheet` helper titled "Filter" with a "Kepemilikan" section (two radio options, Semua/Koleksiku) and a "Terapkan" button, taking the current value + an `onApply(bool)` callback, per design.md §6
- [x] 8.2 In `new_dongeng_list_screen.dart`: replace the "Sudah dibeli saja" `FilterChip` with a gear icon beside the category dropdown row that opens the shared sheet, wired to `FilterOwnedOnly`
- [x] 8.3 In `collection_screen.dart`: replace the "Sudah dibeli saja" `FilterChip` with the same gear icon + sheet, wired to `ToggleOwnedOnly`

## 9. Flutter — Tests

- [x] 9.1 Extend `test/presentation/screens/dongeng/dongeng_list_bloc_test.dart` with category-filter cases (filter by category, by sub-category, combined with ownedOnly and the highlight pin)
- [x] 9.2 Add/extend a widget test for the new filter bottom sheet on the dongeng screen (`test/presentation/screens/dongeng/new_dongeng_list_screen_test.dart` — opens on gear tap, applies on "Terapkan", chip is gone)
- [x] 9.3 `CollectionBlocHandler`/`CollectionState` didn't need bloc-test changes (category dropdowns already existed); added `test/presentation/screens/vocab/collection_screen_test.dart` (new file — none existed before) covering the same 3 cases as the dongeng widget test, registering the mock `ArRepository` via `locator` since `CollectionScreen` builds its own internal `BlocProvider` from the locator rather than accepting one from its caller
- [x] 9.4 Ran `flutter analyze` (0 issues) and `flutter test` (full suite) — only the two pre-existing, unrelated failures remain (`signup_bloc_test.dart`, `ar_card_detail_screen_test.dart`); everything else, including all new tests, passes

## 10. End-to-end verification

Not run — requires a deployed backend with the migration/seed applied, a running backoffice, and a device/simulator, none of which exist in this environment. All three layers are verified independently (backend: 339/339 Go tests; backoffice: 52/52 + typecheck/build/lint; Flutter: 140/140 excluding the 2 pre-existing unrelated failures) and the wire contract was cross-checked by hand (backend JSON tags `dongeng_category_id`/`dongeng_sub_category_id`/`category_ref`/`sub_category_ref` match the Flutter model's parsing exactly). Still recommended before shipping:

- [ ] 10.1 Backend running with the new migration+seed applied (via `docker compose run --rm flyway` or equivalent): `GET /dongeng-categories` returns "Fairy Tales" and "Islamic"
- [ ] 10.2 Backoffice: create/edit/delete/hide a dongeng category via the new page; link a Fairy Tales entry to it
- [ ] 10.3 App: dongeng screen shows the category dropdown, filters correctly, and the new Filter sheet replaces the old chip; collection screen shows the same Filter sheet in place of its old chip

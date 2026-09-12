# Change: Dongeng categories + redesigned filter UI

## Why

Dongeng (story) content has no dedicated category taxonomy today — `dongengs.category_id` points at a flat, generic `categories` table shared with unrelated content, with no emoji/hierarchy/sort order, and nothing in the app or backoffice actually lets an admin browse or filter stories by it. AR cards, by contrast, already have a proper hierarchical `ar_card_categories` table (parent/child, emoji, sort order) with full public + admin CRUD and a working category dropdown in the collection screen. The user wants dongeng brought up to the same standard — a real `dongeng_categories` table seeded with "Fairy Tales" and "Islamic", admin CRUD to manage it and link stories to it, and the matching category-dropdown filter UI in the app.

Separately, both the AR card ("Koleksi") screen and the dongeng screen currently expose ownership filtering ("show only what I've bought") as a `FilterChip` labeled "Sudah dibeli saja". The user wants this replaced on both screens with a settings/gear icon next to the category dropdown that opens a "Filter" bottom sheet with a "Kepemilikan" (ownership) radio choice (Semua / Koleksiku) and a "Terapkan" button — consistent with a design mockup they supplied.

## What Changes

- **Backend schema**: add a new `dongeng_categories` table — identical shape to `ar_card_categories` (`id`, `name`, `emoji`, `image_url`, `parent_id` self-FK for a two-level hierarchy, `sort_order`, timestamps, `is_deleted`) — seeded with two top-level categories, "Fairy Tales" and "Islamic". Add new `dongeng_category_id` / `dongeng_sub_category_id` FK columns on `dongengs`, both nullable, both referencing `dongeng_categories(id)`. **Additive only**: the existing `dongengs.category_id` column (pointing at the generic `categories` table) and its backoffice field are left untouched — this change does not migrate or repoint it. Reconciling the old generic category with the new dedicated one is an explicit non-goal here (see Non-Goals in design.md) and can be a follow-up once the team decides whether the generic `categories` table still has a purpose for dongeng.
- **Backend API**: mirror the `ar_card_categories` public/admin surface for dongeng — `GET /dongeng-categories` (public, top-level + children), full admin CRUD + visibility toggle at `/admin/content/dongeng-categories`, and `GET /fairy-tales`/`GET /fairy-tales/:id` gain `category_id`/`sub_category_id` filtering plus a nested `category_ref`/`sub_category_ref` in the response (same `Preload` pattern as `ar_cards`). Admin create/update for a dongeng entry accepts `dongeng_category_id`/`dongeng_sub_category_id` in its payload.
- **Backoffice**: new "Dongeng Categories" admin page (list/create/edit/delete/hide) mirroring `ArCardCategoriesPage.tsx` exactly, registered under Content in the sidebar; the existing Fairy Tales edit form gains category/sub-category `Select` fields sourced from the new API (mirroring the two-level dropdown pattern the Flutter collection screen already uses for AR cards).
- **Flutter app — dongeng screen**: add a category filter row (mirrors the AR card collection screen's `_CategoryDropdowns` — a "Semua Kategori" dropdown, plus a conditional sub-category dropdown) wired to the new API.
- **Flutter app — filter redesign (both dongeng and collection screens)**: replace the "Sudah dibeli saja" `FilterChip` with a gear/settings icon button placed beside the category dropdown row. Tapping it opens a "Filter" bottom sheet containing a "Kepemilikan" section with two radio options — "Semua" (default) and "Koleksiku" — and a "Terapkan" button that applies the choice (reusing the existing `ownedOnly` plumbing on both screens) and closes the sheet.
- **Tests**: add backend service/handler tests for the new `dongeng_categories` CRUD (the equivalent `ar_card_categories` coverage doesn't exist today — this change doesn't retroactively add it, only covers the new dongeng surface), Flutter bloc/widget tests for the new category filter and the new filter bottom sheet on both screens, and a backoffice test for the new admin page. All existing suites must keep passing.

## Capabilities

### New Capabilities
- `dongeng-categories-cms`: backend `dongeng_categories` table, seed data, public listing endpoint, admin CRUD + visibility toggle, and `dongengs` FK/filtering/response changes
- `dongeng-categories-backoffice`: backoffice "Dongeng Categories" admin page, menu entry, and the category-assignment fields on the Fairy Tales edit form

### Modified Capabilities
- `dongeng-list-screen`: adds a category/sub-category dropdown filter row; replaces the "Sudah dibeli saja" chip with a gear-icon-triggered "Filter" bottom sheet (Kepemilikan: Semua/Koleksiku + Terapkan)
- `collection-screen`: replaces the "Sudah dibeli saja" chip with the same gear-icon-triggered "Filter" bottom sheet (category dropdowns are unchanged)

## Impact

- **New backend table**: `dongeng_categories`
- **New backend columns**: `dongengs.dongeng_category_id`, `dongengs.dongeng_sub_category_id` (both nullable FKs, additive)
- **New/changed backend routes**: `GET /dongeng-categories` (new, public); `GET/POST/PUT/DELETE /admin/content/dongeng-categories` + `PATCH .../visibility` (new, admin); `GET /fairy-tales`, `GET /fairy-tales/:id` (gain query filtering + `category_ref`/`sub_category_ref` in response)
- **Backend files**: new `db/migrations/V43__create_dongeng_categories.sql`, new `db/seeds/R__seed_dongeng_categories.sql`, new `models/dongeng_category.go`, changes to `models/dongeng.go`, `services/dongeng_service.go` (or equivalent), `handlers/fairy_tales_handler.go`/`dongeng_handler.go`, `services/admin_content_service.go`, `handlers/admin_content_handler.go`, `routes/router.go`
- **Backoffice files**: new `src/pages/content/DongengCategoriesPage.tsx`, `src/api/content.ts` (new `dongengCategoriesApi`), `src/App.tsx` (route), `src/components/AppLayout.tsx` (menu), `src/pages/content/FairyTalesPage.tsx` (category fields)
- **Flutter files**: `lib/data/models/response/dongeng_response.dart`, new `lib/data/models/response/dongeng_category.dart`, `lib/data/api/fairy_tales_api.dart`, `lib/data/repositories/fairy_tales_repository.dart`, `lib/presentation/screens/dongeng/dongeng_list_bloc.dart`/`dongeng_list_event.dart`/`dongeng_list_state.dart`, `lib/presentation/screens/dongeng/new_dongeng_list_screen.dart`, `lib/presentation/screens/vocab/collection_screen.dart`
- **No breaking changes**: purely additive schema/API; existing `is_free`/`is_unlocked`/legacy `category_id` behavior on dongeng is untouched.

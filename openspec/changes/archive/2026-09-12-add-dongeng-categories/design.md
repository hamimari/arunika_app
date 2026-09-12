# Design: Dongeng categories + redesigned filter UI

## Context

This mirrors an existing, working pattern (`ar_card_categories`) rather than inventing a new one, so the design below is deliberately a close copy with names swapped — see the backend/backoffice research this proposal is based on for the exact source files being mirrored:
- Backend: `db/migrations/V13__create_ar_card_categories.sql`, `V27__add_image_url_to_ar_card_categories.sql`, `models/ar_card_category.go`, the "AR Card Categories" section of `services/admin_content_service.go` / `handlers/admin_content_handler.go`, and the `/ar/categories` public route in `routes/router.go`.
- Backoffice: `src/pages/content/ArCardCategoriesPage.tsx`, `src/api/content.ts`'s `arCardCategoriesApi`.
- Flutter: `lib/presentation/screens/vocab/collection_screen.dart`'s `_CategoryDropdowns`/`_StyledDropdown`, `lib/presentation/screens/vocab/collection_bloc_handler.dart`.

## Goals
- A dongeng category taxonomy with the same shape and admin ergonomics as AR cards.
- A dongeng list screen filter row that looks and behaves like the collection screen's.
- One consistent "Filter" bottom sheet (Kepemilikan: Semua/Koleksiku) shared in spirit by both screens, replacing the "Sudah dibeli saja" chip.

## Non-Goals
- **Not** touching the existing generic `categories` table or `dongengs.category_id` (used today by the backoffice Fairy Tales form's plain "Category" field). It stays exactly as-is. Reconciling/deprecating it is a separate decision for the team, out of scope here.
- **Not** adding category assignment to AR cards' admin form — research found that gap already exists independently of this change (`ArCardsPage.tsx` has no category `Select` despite the backend supporting it), but fixing it is unrelated to dongeng and not requested.
- **Not** retrofitting test coverage for the pre-existing, untested `ar_card_categories` admin service/handler methods. This change only requires the new dongeng equivalent to be tested.
- No sub-category is seeded initially ("Fairy Tales" and "Islamic" are both top-level, `parent_id = NULL`) — the schema supports one level of children (matching `ar_card_categories`) for future use, but nothing seeds them yet.

## 1. Backend schema

`db/migrations/V43__create_dongeng_categories.sql`:

```sql
-- Dongeng categories with parent/child structure, mirrors ar_card_categories.
-- parent_id NULL  -> top-level category  (e.g. "Fairy Tales", "Islamic")
-- parent_id set   -> sub-category
CREATE TABLE IF NOT EXISTS dongeng_categories (
    id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(100) NOT NULL,
    emoji      VARCHAR(20)  NOT NULL DEFAULT '',
    image_url  TEXT         NOT NULL DEFAULT '',
    parent_id  UUID         REFERENCES dongeng_categories(id) ON DELETE SET NULL,
    sort_order INT          NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    is_deleted BOOLEAN      NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_dongeng_categories_parent ON dongeng_categories(parent_id);

-- Additive FK columns on dongengs — the pre-existing `category_id` (generic
-- `categories` table) is untouched; these are new, separate columns.
ALTER TABLE dongengs
    ADD COLUMN IF NOT EXISTS dongeng_category_id UUID REFERENCES dongeng_categories(id) ON DELETE SET NULL;
ALTER TABLE dongengs
    ADD COLUMN IF NOT EXISTS dongeng_sub_category_id UUID REFERENCES dongeng_categories(id) ON DELETE SET NULL;
```

`db/seeds/R__seed_dongeng_categories.sql` (repeatable — must stay idempotent on re-run):

```sql
INSERT INTO dongeng_categories (id, name, emoji, sort_order)
SELECT gen_random_uuid(), 'Fairy Tales', '🧚', 0
WHERE NOT EXISTS (SELECT 1 FROM dongeng_categories WHERE name = 'Fairy Tales' AND parent_id IS NULL);

INSERT INTO dongeng_categories (id, name, emoji, sort_order)
SELECT gen_random_uuid(), 'Islamic', '🕌', 1
WHERE NOT EXISTS (SELECT 1 FROM dongeng_categories WHERE name = 'Islamic' AND parent_id IS NULL);
```

## 2. Backend model/service/handler

`models/dongeng_category.go` — direct copy of `models/ar_card_category.go` renamed (`DongengCategory`, table `dongeng_categories`), with `FindTopLevelDongengCategories(db)` mirroring `FindTopLevelCategories`.

`models/dongeng.go` gains:
```go
DongengCategoryID    *uuid.UUID       `gorm:"column:dongeng_category_id;type:uuid"     json:"dongeng_category_id,omitempty"`
DongengSubCategoryID *uuid.UUID       `gorm:"column:dongeng_sub_category_id;type:uuid" json:"dongeng_sub_category_id,omitempty"`
CategoryRef          *DongengCategory `gorm:"foreignKey:DongengCategoryID"              json:"category_ref,omitempty"`
SubCategoryRef       *DongengCategory `gorm:"foreignKey:DongengSubCategoryID"           json:"sub_category_ref,omitempty"`
```
(JSON keys `category_ref`/`sub_category_ref` match `ArCards`' naming so the Flutter side can reuse the same parsing shape.)

The dongeng list/detail query functions gain `Preload("CategoryRef").Preload("SubCategoryRef")` plus optional `dongeng_category_id`/`dongeng_sub_category_id` query-param filters, mirroring `FindAllCards`/`FindCardById`.

Admin CRUD: new `ListDongengCategories`/`CreateDongengCategory`/`GetDongengCategory`/`UpdateDongengCategory`/`DeleteDongengCategory`/`ToggleDongengCategoryVisibility` in `services/admin_content_service.go`, copied from the equivalent `*ArCardCategory*` methods (same soft-delete-doubles-as-hidden behavior for consistency with the existing, if slightly odd, `ar_card_categories` convention — not worth diverging from the established pattern in this change). Handlers added to `handlers/admin_content_handler.go` the same way.

Routes added to `routes/router.go`:
```go
r.GET("/dongeng-categories", dongengHandler.GetCategories)

admin.GET("/content/dongeng-categories", adminContentHandler.ListDongengCategories)
admin.POST("/content/dongeng-categories", adminContentHandler.CreateDongengCategory)
admin.GET("/content/dongeng-categories/:id", adminContentHandler.GetDongengCategory)
admin.PUT("/content/dongeng-categories/:id", adminContentHandler.UpdateDongengCategory)
admin.DELETE("/content/dongeng-categories/:id", adminContentHandler.DeleteDongengCategory)
admin.PATCH("/content/dongeng-categories/:id/visibility", adminContentHandler.ToggleDongengCategoryVisibility)
```

Admin dongeng create/update (`fairy-tales` admin endpoints) accept `dongeng_category_id`/`dongeng_sub_category_id` in the request body alongside the existing fields, same bind-straight-from-JSON approach `ArCards` create/update already uses.

## 3. Backoffice

- `src/api/content.ts`: `export const dongengCategoriesApi = contentApi('dongeng-categories');`
- `src/pages/content/DongengCategoriesPage.tsx`: copy of `ArCardCategoriesPage.tsx` with the resource key/labels swapped.
- `src/App.tsx`: `<Route path="content/dongeng-categories" element={<DongengCategoriesPage />} />`
- `src/components/AppLayout.tsx`: new sidebar entry `{ key: '/content/dongeng-categories', icon: <AppstoreOutlined />, label: 'Dongeng Categories' }` under Content, next to "AR Card Categories".
- `src/pages/content/FairyTalesPage.tsx`: add `dongeng_category_id`/`dongeng_sub_category_id` `Select` fields to the create/edit form, fetched via `dongengCategoriesApi.list()`, following the same fetch-then-map-to-options pattern already used there for the generic `categoriesApi`. The second `Select` (sub-category) only renders once a parent with children is chosen — same conditional-render idea as the Flutter dropdowns.

## 4. Flutter — data layer

New `lib/data/models/response/dongeng_category.dart`, structurally identical to `ArCardCategory` (id, name, emoji, imageUrl, parentId, sortOrder, children) but its own type — the two content types have independent taxonomies and mixing the model classes would blur that.

`DongengResponse` gains `categoryId`, `subCategoryId`, `categoryRef`, `subCategoryRef` (parsed from `category_ref`/`sub_category_ref`), mirroring `ArCardResponse`.

`FairyTalesApi`/`FairyTalesRepository` gain `getCategories()` (→ `GET /dongeng-categories`) and `findAll` gains optional `categoryId`/`subCategoryId` params — mirrors `ArApi`/`ArRepository`.

## 5. Flutter — dongeng screen category filter

`DongengListBloc`/`DongengListState` gain `categories`, `activeCategoryId`, `activeSubCategoryId` (mirroring `CollectionBlocHandler`/`CollectionLoaded`), and `FilterByDongengCategory`/`FilterByDongengSubCategory` events. `_onLoad` fetches the story list and categories with `Future.wait`, same as `CollectionBlocHandler._onLoad`. `_filtered()` applies the category/sub-category filter the same way `CollectionBlocHandler._apply` does — **and still applies after** the existing highlight-pinning logic from the `add-monetization-entitlements`-adjacent dongeng-navigation-fix (a just-purchased story stays pinned to the front regardless of which category filter is active, same as it already survives `FilterOwnedOnly`).

`new_dongeng_list_screen.dart` gains a `_CategoryDropdowns`-equivalent row, placed where the "Sudah dibeli saja" chip used to be.

## 6. Filter bottom sheet (both screens)

Target layout (from the user's mockup), identical on the collection screen and the dongeng screen:

```
┌──────────────────────────────┐  ┌────┐
│ Semua kategori           ˅   │  │ ⚙  │
└──────────────────────────────┘  └────┘
Filter

Kepemilikan

○ Semua
● Koleksiku

             Terapkan
```

- The gear icon sits to the right of the existing category dropdown row (an `Expanded` dropdown + a fixed-size icon button in the same `Row`).
- Tapping it opens a `showModalBottomSheet` titled "Filter" with a "Kepemilikan" section: two `RadioListTile<bool>`-style options, "Semua" (`false`, default) and "Koleksiku" (`true`), reflecting the current `ownedOnly` value when opened.
- A "Terapkan" button at the bottom dispatches the existing ownership event (`ToggleOwnedOnly` on collection, `FilterOwnedOnly` on dongeng) with the sheet's selected value and closes the sheet. No live-apply while the sheet is open — only on "Terapkan", matching the mockup.
- The existing `FilterChip` ("Sudah dibeli saja") is removed from both screens; the gear icon's fill/badge state (or a small dot) can optionally indicate `ownedOnly == true` is active, but this is a nice-to-have, not required.
- This is a new, small shared widget (e.g. `lib/presentation/screens/widgets/ownership_filter_sheet.dart`) taking the current value and an `onApply(bool)` callback, used by both screens — avoids duplicating the sheet markup twice.

## Risks / Trade-offs

- **Two parallel category systems on `dongengs`** (`category_id` → generic `categories`, `dongeng_category_id`/`dongeng_sub_category_id` → `dongeng_categories`) is intentionally accepted here rather than resolved, per the Non-Goals — flagged explicitly in the proposal so it's a visible, revisitable decision rather than a silent inconsistency.
- Mirroring `ar_card_categories`' soft-delete-doubles-as-visibility-toggle quirk (rather than adding a proper `hidden` column) keeps the two category tables consistent with each other, at the cost of carrying forward a slightly confusing convention. Fixing that convention project-wide is out of scope for this change.

## 1. Database Migrations

- [x] 1.1 Create `migrations/001_create_premium_packages.sql` with the `premium_packages` table schema (id UUID PK, name, subtitle, price_idr, type CHECK, badge_label, is_best_value, is_active, sort_order, created_at, updated_at)
- [x] 1.2 Create `migrations/002_seed_premium_packages.sql` inserting the 6 existing static packages (Paket Hutan, Paket Lautan, Paket Ternak, ALL ACCESS PASS, Bulanan, Tahunan) with correct prices, types, and sort orders
- [ ] 1.3 Run both migrations on the development database and verify row counts

## 2. Backend — Public API

- [x] 2.1 Create `GET /premium/packs` handler that queries `premium_packages` WHERE `is_active = TRUE` ORDER BY `sort_order ASC`; accepts optional `?type=` query param
- [x] 2.2 Wrap response in the standard `{ "data": [...] }` envelope
- [x] 2.3 Ensure no authentication middleware is applied to this route
- [x] 2.4 Write unit test: returns only active packages; filtered by type; ordered by sort_order

## 3. Backend — Admin API

- [x] 3.1 Create `GET /admin/premium/packs` handler returning all packages (including inactive), protected by admin JWT middleware
- [x] 3.2 Create `POST /admin/premium/packs` handler — validate required fields (name, subtitle, price_idr, type), insert row, return created record
- [x] 3.3 Create `PUT /admin/premium/packs/:id` handler — validate fields, update row, return updated record; return 404 if not found
- [x] 3.4 Create `DELETE /admin/premium/packs/:id` handler — delete row, return 204; return 404 if not found
- [x] 3.5 Create `PATCH /admin/premium/packs/:id/visibility` handler — accept `{ "is_active": boolean }`, update field, return updated record
- [x] 3.6 Write unit tests for each admin endpoint (happy path + 401 unauthorized + 404 not found)

## 4. Flutter — Model & Repository

- [x] 4.1 Add `fromJson` factory constructor to `PremiumPack` in `lib/data/static/premium_packs.dart` (or move to `lib/data/models/`) mapping snake_case API keys to camelCase fields
- [x] 4.2 Create `lib/data/api/premium_pack_api.dart` with `fetchPacks({String? type})` calling `GET /premium/packs?type=<type>`
- [x] 4.3 Create `lib/data/repositories/premium_pack_repository.dart` wrapping the API with a 5-minute in-memory cache per type; returns fallback static list on error
- [x] 4.4 Register `PremiumPackRepository` (and `PremiumPackApi`) in `lib/di/locator.dart`

## 5. Flutter — Cubit & State

- [x] 5.1 Create `lib/presentation/screens/premium/premium_pack_cubit.dart` with states: `PremiumPackInitial`, `PremiumPackLoading`, `PremiumPackLoaded(List<PremiumPack>)`, `PremiumPackError(String)`
- [x] 5.2 Cubit `loadPacks(String type)` method calls `PremiumPackRepository.fetchPacks(type: type)`
- [x] 5.3 Register the cubit in the `PremiumUpgradeScreen` via `BlocProvider`

## 6. Flutter — Update PremiumUpgradeScreen

- [x] 6.1 Replace `_PackList(packs: PremiumPacks.contentPacks)` with a `BlocBuilder<PremiumPackCubit, PremiumPackState>` that shows loading skeleton, loaded list, or error+retry
- [x] 6.2 Do the same for the subscription tab (`PremiumPacks.subscriptionPacks`)
- [x] 6.3 Each tab gets its own `PremiumPackCubit` instance (use `MultiBlocProvider`)
- [x] 6.4 Remove the import of `package:arunika_app/data/static/premium_packs.dart` from `premium_upgrade_screen.dart`
- [x] 6.5 Verify `PaymentScreen` still receives a `PremiumPack` object unchanged — no edits required there

## 7. Flutter — Cleanup

- [x] 7.1 Mark `lib/data/static/premium_packs.dart` as deprecated with a comment; do NOT delete yet
- [x] 7.2 Run `flutter analyze` and resolve any new warnings introduced by this change

## 8. Backoffice — API Layer

- [x] 8.1 Add `premiumPackagesApi` object to `src/api/admin.ts` with methods: `list()`, `create(data)`, `update(id, data)`, `remove(id)`, `toggleVisibility(id, isActive)`
- [x] 8.2 Define TypeScript interface `PremiumPackage` in a shared types file or inline in the page

## 9. Backoffice — Packages Page

- [x] 9.1 Create `src/pages/packages/PremiumPackagesPage.tsx` with an Ant Design `Table` showing all packages
- [x] 9.2 Table columns: Name, Subtitle, Price (formatted as Rp X), Type (Tag), Badge Label, Best Value, Active (Switch), Sort Order, Actions (Edit, Delete)
- [x] 9.3 Inactive packages SHALL use a greyed-out row style (Ant Design `rowClassName`)
- [x] 9.4 Implement "Add Package" button that opens a `Modal` with a `Form` (fields: Name, Subtitle, Price, Type, Badge Label, Is Best Value, Sort Order)
- [x] 9.5 Form validation: Name and Subtitle required, Price must be a positive integer, Type is required
- [x] 9.6 On form submit call `premiumPackagesApi.create(data)`, invalidate React Query cache, close modal
- [x] 9.7 Implement "Edit" action: open the same modal pre-filled; on submit call `premiumPackagesApi.update(id, data)`
- [x] 9.8 Implement `Switch` in Active column: `onChange` calls `premiumPackagesApi.toggleVisibility(id, !current)`, invalidates cache
- [x] 9.9 Implement "Delete" action with `Popconfirm`; on confirm call `premiumPackagesApi.remove(id)`, invalidate cache
- [x] 9.10 Show a price-change warning in the edit modal when `price_idr` is modified (compare initial vs current form value)

## 10. Backoffice — Routing & Navigation

- [x] 10.1 Add route `<Route path="packages" element={<PremiumPackagesPage />} />` in `src/App.tsx`
- [x] 10.2 Import `PremiumPackagesPage` in `App.tsx`
- [x] 10.3 Add "Packages" menu item to `menuItems` in `src/components/AppLayout.tsx` (use `GiftOutlined` or `ShoppingOutlined` icon, key `/packages`, label "Premium Packages")

## 11. QA & Integration

- [ ] 11.1 End-to-end test: create a package in backoffice → open Flutter app → verify it appears in the upgrade screen
- [ ] 11.2 Test hiding a package in backoffice → verify it disappears from Flutter app (after cache TTL or app restart)
- [ ] 11.3 Test Flutter error fallback: take API offline → verify upgrade screen shows fallback static list
- [ ] 11.4 Test guest user can see upgrade screen without auth
- [ ] 11.5 Test backoffice delete with confirmation dialog
- [ ] 11.6 Test backoffice form validation (empty fields, negative price)

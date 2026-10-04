## Why

The premium upgrade screen in the Flutter app currently reads package names, prices, and descriptions from a hardcoded Dart file (`lib/data/static/premium_packs.dart`). This means any pricing change, new package, or promotion requires a full app release. There is no way for the business team to manage packages from the backoffice. This change makes premium packages fully data-driven — managed via a backoffice CRUD page and served from the backend.

## What Changes

- **Database**: New `premium_packages` table with fields for name, subtitle, price, type (content/subscription), badge label, best-value flag, visibility (`is_active`), and sort order
- **Backend API (public)**: `GET /premium/packs` — returns only active packages ordered by `sort_order`; supports optional `?type=content|subscription` filter
- **Backend API (admin)**: Full CRUD under `/admin/premium/packs` — create, list (including inactive), update, delete, toggle visibility
- **Flutter app**: Replace `PremiumPacks` static class with a `PremiumPackRepository` that fetches from `/premium/packs`; add a `PremiumPackCubit` to manage load/error/loaded states in `PremiumUpgradeScreen`
- **Backoffice**: New "Premium Packages" page under `/packages` with a table showing all packages (active and inactive), inline toggle for visibility, modal form for create/edit, and delete with confirmation
- **Payment flow**: `PaymentScreen` continues to receive a `PremiumPack` object — no change to payment logic

## Capabilities

### New Capabilities
- `premium-package-cms`: Backend CRUD API and DB schema for premium packages (admin-controlled)
- `premium-package-flutter`: Flutter app fetches packages dynamically from the backend instead of using static data
- `premium-package-backoffice`: Backoffice page for managing premium packages (add, edit, hide, delete)

### Modified Capabilities
*(none — payment flow receives the same `PremiumPack` shape, no spec-level behavior change)*

## Impact

- **New DB table**: `premium_packages`
- **New backend endpoints**: `GET /premium/packs`, `GET /admin/premium/packs`, `POST /admin/premium/packs`, `PUT /admin/premium/packs/:id`, `DELETE /admin/premium/packs/:id`, `PATCH /admin/premium/packs/:id/visibility`
- **Flutter**: `lib/data/static/premium_packs.dart` replaced by `lib/data/repositories/premium_pack_repository.dart`; `lib/presentation/screens/premium/premium_upgrade_screen.dart` updated to use Cubit
- **Backoffice**: new file `src/pages/packages/PremiumPackagesPage.tsx`, new API methods in `src/api/admin.ts`, new route `/packages` in `App.tsx`, new menu item in `AppLayout.tsx`

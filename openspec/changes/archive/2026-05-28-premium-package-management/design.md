## Context

The Flutter app currently has a static `PremiumPacks` class in `lib/data/static/premium_packs.dart` with two hardcoded lists: `contentPacks` (3 category packs + All Access) and `subscriptionPacks` (monthly + annual). These are fed directly into `PremiumUpgradeScreen` and then passed to `PaymentScreen` which sends `plan_name` and `amount` to the `/payment/create` endpoint (Midtrans Snap).

The backoffice (`arunika_backoffice`) is a React + Ant Design + React Query + Zustand app. It already has pages for content, users, payments, campaigns, banners, and categories. All admin API calls go through `src/api/admin.ts` using an Axios client that attaches a JWT from `localStorage`. There is no existing concept of "packages" in the admin.

The backend uses a standard `{ data: ... }` envelope. No ORM or migration tool is visible in this repo — SQL migrations should be written as plain `.sql` files (consistent with what the `feature/education-module-v1` branch shows).

## Goals / Non-Goals

**Goals:**
- Define the `premium_packages` DB schema with all fields needed for CMS management
- Build backend CRUD endpoints: public `GET /premium/packs` and admin `/admin/premium/packs` (list/create/update/delete/toggle visibility)
- Replace Flutter static pack list with a live API call via `PremiumPackRepository` + `PremiumPackCubit`
- Add a "Premium Packages" CRUD page to the backoffice with add, edit, toggle visibility, and delete

**Non-Goals:**
- Changing the Midtrans payment flow (still receives a `PremiumPack`-shaped object from the UI)
- Package purchase history or analytics per-package (existing `/admin/payments` covers transactions)
- Localization of package descriptions
- Tiered access control within packages (what content each pack unlocks is a future feature)

## Decisions

### D1: DB schema — `premium_packages` table

```sql
CREATE TABLE premium_packages (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          VARCHAR(100) NOT NULL,
  subtitle      VARCHAR(255) NOT NULL,
  price_idr     INTEGER NOT NULL,
  type          VARCHAR(20) NOT NULL CHECK (type IN ('content', 'subscription')),
  badge_label   VARCHAR(50),
  is_best_value BOOLEAN NOT NULL DEFAULT FALSE,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Rationale**: `type` separates the two existing tabs (content vs subscription) so the Flutter tab UI stays intact. `is_active` enables hiding without deletion. `sort_order` controls display order without relying on insertion order. `badge_label` + `is_best_value` map 1-to-1 to the existing `PremiumPack` model fields.

**Alternative**: Separate `content_packs` and `subscription_packs` tables. Rejected — same shape, unnecessary complexity.

### D2: Public endpoint returns only active, ordered packages

`GET /premium/packs?type=content|subscription` returns packages where `is_active = TRUE`, ordered by `sort_order ASC`. No auth required — the upgrade screen is visible to guest users.

**Rationale**: Guests can see the upgrade screen, so no JWT needed. Filtering by `type` allows the two-tab layout to make two cheap calls instead of one + client-side split.

### D3: Flutter uses `PremiumPackCubit` (not BLoC) for simplicity

A `Cubit<PremiumPackState>` with states `loading / loaded / error` is sufficient — there are no complex event chains. The cubit calls `PremiumPackRepository.fetchPacks(type)` on creation.

**Alternative**: Full BLoC. Rejected — over-engineering for a simple fetch.

### D4: `PremiumPack` model is kept as-is in Flutter

The existing `PremiumPack` data class fields match the DB schema exactly. `PremiumPackRepository` simply deserializes the API response into `PremiumPack` objects. `PaymentScreen` continues to receive a `PremiumPack` — zero change to payment logic.

**Rationale**: Minimal blast radius. Only the data source changes.

### D5: Backoffice page uses inline toggle + modal form

Visibility (active/inactive) is toggled with an Ant Design `Switch` directly in the table row, making it the fastest operation. Create/edit uses a modal with a `Form`. Delete shows a `Popconfirm`.

**Rationale**: Consistent with the pattern already used in `BannersPage` and `CategoriesPage` in the backoffice.

### D6: Seed data migration

A follow-up migration seeds the existing static packages (Paket Hutan, Paket Lautan, etc.) so the app still shows packages on first deploy without manual backoffice setup.

## Risks / Trade-offs

- **[Risk] Network latency on upgrade screen open** → Mitigation: show a skeleton loader; cache response for the session (5 min TTL in `PremiumPackRepository`)
- **[Risk] Admin accidentally deletes all packages** → Mitigation: backend returns 400 if attempting to delete the last active package in a type; UI shows warning count
- **[Risk] Price change reflected immediately without app release** → This is intentional, but means a misconfigured price goes live instantly → Mitigation: require confirmation modal in backoffice when editing price

## Migration Plan

1. Run `001_create_premium_packages.sql` migration
2. Run `002_seed_premium_packages.sql` to insert the 6 existing static packages
3. Deploy backend with new endpoints
4. Deploy backoffice with new Packages page
5. Deploy Flutter app — `PremiumPacks` static class can be kept as fallback (return it if API fails)
6. Once stable, remove static fallback in a follow-up PR

## Open Questions

- Should `price_idr` support decimal (paise/cents)? Currently all prices are whole IDR — using `INTEGER` is fine for now.
- Should the admin endpoint support bulk sort-order updates (drag-and-drop reorder)? Deferred to a future iteration.

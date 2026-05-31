## Context

Arunika World is a Flutter app targeting children in Indonesia. The current codebase has screens for home, landing, AR scanner, dongeng (stories), and a vocab/collection list — but their visual design and user journeys do not match the approved product mockups. The mockups define two clear user journeys: a **free flow** (welcome → demo AR → explore) and a **paid flow** (discover premium → pay → unlock → enjoy). The redesign must be Flutter-native, work on mid-range Android devices (Android 8+), and feel premium, warm, and child-friendly without requiring any backend changes in this phase.

The backend is a separate project at `/Users/hamim.tohari/Project/arunika backend`. API contracts are not changing in this phase.

## Goals / Non-Goals

**Goals:**
- Implement all screens shown in the two mockup images as Flutter widgets.
- Establish a shared design system (colors, typography, spacing, component styles) used consistently across all screens.
- Implement standardised 5-tab bottom navigation (Beranda, Scan, Koleksi, Dongeng, Orang Tua).
- Update existing screens (home, collection/vocab, dongeng list, landing/splash) to match mockups.
- Add new screens: animal detail, AR experience flow, fun fact overlay, reward screen, premium upgrade, payment, unlock success, progress/journey.
- Keep the existing dongeng player screen visually unchanged.
- Ensure all screens are responsive for common Android phone sizes (360dp–420dp width).

**Non-Goals:**
- Live AR engine integration (Unity bridge) — AR screens will use placeholder/mock AR view for now.
- Real payment gateway integration — payment screen is UI-only in this phase.
- Backend API changes or new endpoints.
- iOS-specific design deviations.
- Animations beyond simple Flutter built-in transitions and hero animations.

## Decisions

### 1. Design System via `AppTheme` and constants

**Decision:** Centralise all design tokens (colors, text styles, border radii, shadows) in `lib/constants/app_theme.dart` and `lib/constants/app_colors.dart`. Apply via `ThemeData` in `MaterialApp`.

**Rationale:** Screens currently hardcode colors and text styles. A central theme ensures consistency and makes future updates (e.g., dark mode, white-label) a single-file change. Alternatives like a third-party design token package were rejected to keep dependencies lean.

### 2. Screen-per-folder structure, no page routing library change

**Decision:** Continue with existing folder-per-screen structure under `lib/presentation/screens/`. New screens follow the same pattern. Navigation stays with the existing router in `lib/presentation/navigation/`.

**Rationale:** Introducing a new router (e.g., go_router) mid-project risks breaking existing deeplink/navigation logic. The existing navigator is sufficient for the number of screens in this phase. This can be revisited in a future refactor.

### 3. Rename `vocab` folder to `collection` conceptually but keep file path

**Decision:** Do not rename `lib/presentation/screens/vocab/` to avoid breaking import chains. Instead, replace the screen content and rename the widget class to `CollectionScreen`.

**Rationale:** Low-risk approach. A full rename would require updating all import references. The widget class rename is sufficient for code clarity.

### 4. Bottom navigation as a persistent shell widget

**Decision:** Implement a `MainShell` scaffold that wraps the 5 main tab screens and persists the `BottomNavigationBar` across tab switches using `IndexedStack`.

**Rationale:** `IndexedStack` preserves scroll state per tab (important for collection and dongeng lists). This is the standard Flutter pattern for persistent bottom nav.

### 5. Premium/payment screens are static UI only

**Decision:** Premium upgrade and payment screens render hardcoded pack data and local payment options. No API calls in this phase.

**Rationale:** Backend payment integration is a separate concern. Static UI allows design review and user testing without backend dependency. A `TODO` comment will mark integration points.

### 6. AR scan and experience screens use a mock/placeholder camera view

**Decision:** The AR scanner screen will use the existing `arscanner` screen's camera feed if available, overlaid with the new UI chrome (scan guide, action buttons). The AR 3D model will remain as-is; only the surrounding UI is redesigned.

**Rationale:** The AR engine (Unity bridge) is out of scope. The goal is to match the UI shell around the AR view.

## Risks / Trade-offs

- **[Risk] Dongeng player screen not breaking** → Only the list page is changed. The player screen widget is not touched. Navigation from list to player is preserved.
- **[Risk] `IndexedStack` memory usage** → Keeping all 5 tab screens alive increases memory. Mitigation: lazy-load heavy screens (AR, collection) only when first visited using `_initialized` flag.
- **[Risk] Asset availability** — Mockup illustrations (animals, backgrounds) may not exist in `assets/`. Mitigation: use placeholder `Image.asset` with fallback colors; actual assets are a content task separate from this UI change.
- **[Risk] Hardcoded Indonesian strings** — The mockups use Indonesian text. No i18n system exists. Mitigation: keep strings in a `AppStrings` constants file for easy future extraction.
- **[Risk] Static premium/payment data becoming stale** — If pack names/prices change before backend integration, static data must be updated manually. Mitigation: isolate pack data in a `lib/data/static/premium_packs.dart` file.

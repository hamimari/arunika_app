## Context

The Arunika World Flutter app has a home screen, bottom navigation, collection (Koleksi), and dongeng list screens that were recently redesigned for a premium look. However several areas are still hardcoded/static, icons are inconsistent, and the user flow for dongeng and categories is not data-driven.

The `feature/education-module-v1` branch already has a `BannerApi` + `BannerItem` model targeting `/banners` endpoint, which we will build on. The backend supports a standard `data` envelope pattern via Dio.

Current state:
- Bottom nav uses custom floating pill; Scan tab is centered but icons for Home, Collection, Dongeng need updating; Orang Tua label needs renaming to Profil
- Home screen banner is a hardcoded AR promo; daily animal card is a separate static widget
- "Lanjutkan Petualangan" section shows hardcoded story cards, not real data
- "Kategori Dunia" section is hardcoded with 4 categories
- Koleksi filter chips are horizontal scroll chips
- Sign in and Register back buttons use `BackButton` with `AppBar`; the custom icon button overlaps with the AppBar's default behavior

## Goals / Non-Goals

**Goals:**
- Bottom nav: sun icon for Home, card-stack icon for Koleksi, open-book/fairy-tale icon for Dongeng; rename "Orang Tua" → "Profil"; scanner always center, no scan button on Profil tab
- Warm orange gradient background on Home, Dongeng list, and Koleksi screens
- Configurable banner carousel: fetch from `/banners` API, support multiple banners including daily-animal slot, CMS-controllable; reuse `BannerApi` + `BannerItem` from `feature/education-module-v1`
- Dongeng Populer section: for new/guest users show most-watched dongeng (by play count); for returning users show incomplete dongeng + popular from same category
- Kategori Binatang: fetch from `/categories` API (same data as Koleksi filter); show max 5 tiles + "Lihat Semua" link
- Koleksi category filter as dropdown
- Fix back button: both sign in and register screens should correctly navigate back using `context.pop()` or `Navigator.pop()` without AppBar conflict

**Non-Goals:**
- Full CMS/admin UI for banner management (backend only)
- Offline caching of banners or categories
- Deep analytics for watch history (simple `watched_at` + `progress_seconds` is sufficient)
- Changing the AR scanner core logic

## Decisions

### D1: Banner carousel replaces both hero banner AND Hewan Hari Ini

**Decision**: Remove the separate `_DailyAnimalCard` widget and merge it into the banner system as a special banner type (`type: "daily_animal"`). The backend returns a `type` field on each banner; the Flutter client renders differently based on type.

**Rationale**: Reduces the number of API calls and widget complexity. The user requested both features be merged. Backend can control whether the daily-animal banner is visible.

**Alternative considered**: Keep `_DailyAnimalCard` separate, just hide the static one. Rejected — keeps duplicate code.

### D2: Dongeng watch history tracked server-side

**Decision**: Add a `POST /dongeng/:id/play` endpoint that records the user's play event (user_id, dongeng_id, started_at). Add `GET /dongeng/history` to retrieve incomplete items and `GET /dongeng/popular` for most-played. Flutter calls the appropriate endpoint based on auth state.

**Rationale**: Centralised history enables cross-device continuity and is needed for the "continue watching" feature later.

**Alternative**: localStorage / SharedPreferences only. Rejected — can't persist across devices and no backend insights.

### D3: Animal categories fetched from `/categories` endpoint

**Decision**: Add `GET /categories` returning `[{id, name, emoji, slug}]`. Both home screen and koleksi screen use the same cached response (via a `CategoryRepository` with in-memory cache).

**Rationale**: Single source of truth; categories on home and koleksi must match.

### D4: Koleksi filter as dropdown

**Decision**: Replace horizontal `ListView` of filter chips with a `DropdownButton` or a custom bottom-sheet picker matching `user_journey_paid.png` reference. Use a bottom-sheet style dropdown to align with premium UX.

**Rationale**: Chips work for ≤5 options but break layout at scale. User explicitly requested dropdown.

### D5: Back button fix — remove AppBar, use leading icon only

**Decision**: Both sign-in and signup screens currently have `AppBar` with `leading: BackButton` and separately a custom `IconButton` in the body. Remove the `AppBar` entirely from both screens; the custom back `IconButton` in the body `SafeArea` already handles navigation via `Navigator.maybePop()`. No changes needed beyond removing the `AppBar`.

**Rationale**: The double back-button (AppBar's default + custom) causes confusion. Removing `AppBar` is the cleanest fix.

## Risks / Trade-offs

- **[Risk] Backend endpoints not yet implemented** → Mitigation: stub with mock data using fallback pattern in repository; feature flag via banner `type` field
- **[Risk] Watch history endpoint adds load** → Mitigation: call only when user is logged in; cache result for session
- **[Risk] Dropdown UX may feel heavy on small screens** → Mitigation: use a bottom-sheet picker (not native dropdown) for better touch ergonomics
- **[Risk] Banner carousel autoplay may cause jank** → Mitigation: use `PageView` with `AutomaticKeepAlive`; avoid network images on rapid swipe

## Migration Plan

1. Merge `feature/education-module-v1` banner files into main branch
2. Backend: add `/categories`, `/dongeng/popular`, `/dongeng/history`, `POST /dongeng/:id/play`, update `/banners` to include `type` field
3. Flutter: implement in feature branches, integrate behind null-safety guards so app degrades gracefully if new endpoints are unavailable
4. QA: test guest vs logged-in flows; test empty history state
5. Rollback: all new sections have loading/error states; removing a banner from CMS immediately hides it

## Open Questions

- Should `/banners` support ordering (e.g., `sort_order` field)? Assuming yes — backend should include it.
- Should the daily-animal banner rotate daily server-side or be a separate entity picked by CMS? Assuming CMS picks it.
- How many play seconds before a dongeng is considered "incomplete" vs "completed"? Suggest: completed if >90% duration played.

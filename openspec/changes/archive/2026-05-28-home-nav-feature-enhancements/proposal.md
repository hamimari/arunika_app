## Why

The app's home experience, navigation, and key screens have inconsistencies in visual design, icons, and data presentation. Several features (home banner, animal categories, dongeng list) are static/hardcoded when they should be dynamic and configurable from the backend. This change addresses both UX polish and feature completeness to deliver a cohesive, data-driven experience.

## What Changes

- **Bottom nav**: Scanner tab always centered; replace home icon with sun icon; use a card-collection icon for Koleksi; use a fairy-tale/book icon for Dongeng; rename "Orang Tua" label to "Profil"; remove QR scan button from Orang Tua/Profil tab
- **Home screen color vibe**: Adopt warm orange gradient background similar to the Orang Tua page; apply same treatment to Dongeng list and Koleksi screens
- **Home banner (configurable)**: Backend-driven banners — support multiple banners including the daily animal highlight; banners can be added, updated, hidden from the CMS; follow existing backend design on `feature/education-module-v1`
- **Dongeng Populer section**: Replace "Lanjutkan Petualangan" with "Dongeng Populer" for guest/new users; if user has watch history, show incomplete dongeng + popular dongeng from same category; data sourced live from backend
- **Kategori Binatang**: Rename "Kategori Dunia" to "Kategori Binatang"; fetch categories dynamically from backend; same categories shown on Koleksi page; if >5 categories show "Lihat Semua" link to Koleksi
- **Koleksi page — category dropdown**: Change filter chips to a dropdown selector matching `user_journey_paid.png` reference design
- **Sign in / Register back button**: Fix the back button behavior on both screens
- **Hewan Hari Ini merged into banner**: Remove the standalone Hewan Hari Ini card; merge it as one of the configurable banner slots

## Capabilities

### New Capabilities
- `home-banner`: Configurable multi-banner carousel on home screen (data-driven, supports daily-animal slot, CMS-controlled visibility)
- `dongeng-populer-section`: Smart dongeng section — shows popular dongeng for new users, incomplete + related for returning users
- `animal-categories-dynamic`: Fetch and display animal categories from backend on home and koleksi screens

### Modified Capabilities
- `dongeng-navigation-fix`: Navigation and list behavior for dongeng screen has new data requirements (watch history, popular ranking)

## Impact

- `lib/presentation/navigation/main_shell.dart` — bottom nav icons, labels, scanner placement
- `lib/presentation/screens/home/new_home_screen.dart` — banner section, categories section, dongeng section, color scheme
- `lib/presentation/screens/vocab/collection_screen.dart` — dropdown filter, dynamic categories, color scheme
- `lib/presentation/screens/dongeng/new_dongeng_list_screen.dart` — color scheme, popular/continue logic
- `lib/presentation/screens/qrscanner/qr_scanner.dart` — ensure scan button removed from Profil tab
- `lib/presentation/screens/signin/signin_screen.dart` — back button fix
- `lib/presentation/screens/signup/signup_screen.dart` — back button fix
- Backend: new/updated API endpoints for banners, animal categories, dongeng watch history
- Database: potential new table for banner config and user watch history

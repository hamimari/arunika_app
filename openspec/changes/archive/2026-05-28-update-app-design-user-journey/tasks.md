## 1. Design System Foundation

- [x] 1.1 Create `lib/constants/app_colors.dart` with full warm color palette (primary orange, cream background, deep brown, accent gold, muted blue, success green, lock grey)
- [x] 1.2 Create `lib/constants/app_text_styles.dart` with Poppins/Nunito text styles for heading (24sp), subheading (18sp), body (14sp), caption (12sp)
- [x] 1.3 Add Poppins and/or Nunito fonts to `pubspec.yaml` and `assets/fonts/` folder
- [x] 1.4 Update `MaterialApp` `ThemeData` in `main.dart` to use `AppColors` and `AppTextStyles`
- [x] 1.5 Create `lib/constants/app_strings.dart` with all Indonesian UI strings used across screens

## 2. Bottom Navigation Shell

- [x] 2.1 Create `lib/presentation/navigation/main_shell.dart` — a `StatefulWidget` with `IndexedStack` hosting 5 tabs
- [x] 2.2 Implement `BottomNavigationBar` with 5 items: Beranda, Scan, Koleksi, Dongeng, Orang Tua with icons and labels
- [x] 2.3 Style active tab with accent colour and filled icon; inactive tabs with muted grey
- [x] 2.4 Wire `MainShell` as the root route after the welcome/landing flow in the navigation router

## 3. Welcome / Splash Screen Update

- [x] 3.1 Update the landing screen (`lib/presentation/screens/landing/`) to display "Bring Animals to Life!" heading, "Scan, learn, explore, and play!" subtitle, hero animal illustration, "Let's Explore!" primary button, and "Try Demo AR" secondary button
- [x] 3.2 Update `flutter_native_splash` config in `pubspec.yaml` or `flutter_native_splash.yaml` to use cream background `#FFF8F0`
- [x] 3.3 Regenerate native splash with `dart run flutter_native_splash:create`

## 4. Home Screen Redesign

- [x] 4.1 Redesign `lib/presentation/screens/home/` — add greeting header widget with settings icon
- [x] 4.2 Add three quick-action buttons row: Scan Mulai AR, Koleksiku, Dongeng — with icons and rounded card style
- [x] 4.3 Add hero animal illustration (Rusa/deer) as central visual
- [x] 4.4 Add "Unduh Kartu Printable" banner at the bottom of the home content with printable card preview images
- [x] 4.5 Remove any old home content that does not match the mockup

## 5. Collection Screen Redesign

- [x] 5.1 Rename `CollectionScreen` widget class (in `lib/presentation/screens/vocab/`) and update its content to a 2-column grid layout
- [x] 5.2 Add category filter chips row: Semua, Hewan Ternak, Hutan, Laut — with active/inactive chip styles
- [x] 5.3 Implement filter logic to show/hide animals by category
- [x] 5.4 Add star counter (⭐ 24) and search/filter icons to the collection header
- [x] 5.5 Implement unlocked card style (full colour + green checkmark) and locked card style (greyed/blurred + lock icon)

## 6. Animal Detail Screen

- [x] 6.1 Create `lib/presentation/screens/animal_detail/animal_detail_screen.dart`
- [x] 6.2 Implement large animal image with styled colour background at top
- [x] 6.3 Add "Fakta Seru 🐾" card with educational text and sound icon button
- [x] 6.4 Add "Scan di AR" button that navigates to the AR scan screen
- [x] 6.5 Add "Suara" (play sound), "Bagikan" (share), and heart/favorite toggle action buttons at the bottom
- [x] 6.6 Wire collection grid item tap to navigate to animal detail screen

## 7. Dongeng List Screen Redesign

- [x] 7.1 Update dongeng list screen (`lib/presentation/screens/dongeng/`) — add large featured story card at top with Premium badge, cover image, description, "Baca Sekarang" button
- [x] 7.2 Add "Cerita Populer — Lihat Semua" section with story list rows (thumbnail, title, short description, lock/unlock icon)
- [x] 7.3 Implement tap on unlocked story row → navigate to existing dongeng player screen (no changes to player)
- [x] 7.4 Implement tap on locked story row → navigate to premium upgrade screen

## 8. AR Scan Flow Redesign

- [x] 8.1 Update `lib/presentation/screens/arscanner/` scan screen: add card-shaped animated scan guide overlay, help (?) and flashlight icon buttons
- [x] 8.2 Create AR experience screen overlay / screen: show AR model area with action buttons row (Info, Suara, Tari, Makan) in circular icon buttons
- [x] 8.3 Create "Tahukah kamu?" fun fact overlay card widget — displayed on animal tap during AR
- [x] 8.4 Create `lib/presentation/screens/reward/reward_screen.dart` — celebration screen with "+10 ⭐", animal name confirmed, and "Lihat Koleksiku" button
- [x] 8.5 Wire AR session end → navigate to reward screen

## 9. Premium Upgrade Screen

- [x] 9.1 Create `lib/presentation/screens/premium/premium_upgrade_screen.dart`
- [x] 9.2 Implement tab bar: "Paket Konten" and "Langganan"
- [x] 9.3 Create `lib/data/static/premium_packs.dart` with static pack data (name, subtitle, price, best value flag)
- [x] 9.4 Render pack cards list with name, subtitle, IDR price, and ALL ACCESS PASS "BEST VALUE" badge
- [x] 9.5 Wire pack card tap → navigate to payment screen passing selected pack

## 10. Payment Screen

- [x] 10.1 Create `lib/presentation/screens/payment/payment_screen.dart`
- [x] 10.2 Show selected pack name and total price at top
- [x] 10.3 Render local payment method options with logos: OVO, GoPay, DANA, ShopeePay, Transfer Bank, Kartu Kredit/Debit
- [x] 10.4 Implement payment method selection state (radio/highlight)
- [x] 10.5 Add "Bayar Sekarang 🔒" button at the bottom — in this phase navigate to unlock success screen on tap

## 11. Unlock Success Screen

- [x] 11.1 Create `lib/presentation/screens/unlock_success/unlock_success_screen.dart`
- [x] 11.2 Show "Yeay! 🎉" heading and pack name
- [x] 11.3 Render checklist of unlocked content items (e.g., 15+ Hewan Baru, 4 Dongeng Eksklusif, Kartu Printable, Offline support)
- [x] 11.4 Add "Mulai Jelajah" button that navigates to the Koleksi tab
- [x] 11.5 Add simple confetti or sparkle animation (Flutter built-in or `confetti` package)

## 12. Navigation Wiring & Route Cleanup

- [x] 12.1 Register all new screen routes in the app router (`lib/presentation/navigation/`)
- [x] 12.2 Remove or redirect any old/unused routes that were replaced
- [x] 12.3 Ensure deep links from home quick-actions correctly switch tabs in `MainShell`
- [x] 12.4 Verify back-navigation works correctly from all new screens

## 13. Assets & Polish

- [x] 13.1 Add placeholder animal thumbnail images and hero illustrations to `assets/images/` (or confirm existing assets are used)
- [x] 13.2 Add payment method logos to `assets/images/payment/`
- [x] 13.3 Add pack cover images to `assets/images/packs/`
- [x] 13.4 Verify all screens render correctly on 360dp and 414dp screen widths
- [x] 13.5 Run `flutter analyze` and fix any lint warnings introduced by new files

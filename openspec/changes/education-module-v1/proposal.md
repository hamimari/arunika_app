## Why

Arunika currently offers AR card scanning and audio fairy tales, but has no interactive learning content for children. Parents need structured, gamified exercises — tracing, counting, and growth tracking — to turn the app into a complete early-childhood education platform. Adding a badge system, monetisation (Midtrans), and push notifications (FCM) creates retention loops and a sustainable revenue model.

## What Changes

- **Tracing exercises** — Canvas-based letter (A–Z), number (0–9), and shape tracing with guide paths, stroke validation, scoring (≥70% = pass), and audio/animation feedback.
- **Counting exercises** — Level-based counting games (Easy 1–5, Medium 1–10, Hard 1–20 + simple arithmetic) with visual object counting and immediate answer feedback.
- **Badge system** — Per-feature badges (Beginner → Explorer → Master) and a global All-Rounder badge driven by aggregated progress stored on the backend; displayed on the Profile page.
- **Free / Paid tiers** — Free tier: Easy level only, limited tracing items. Paid tier: full content. Payment via Midtrans Snap API with webhook handling and subscription status persistence.
- **Push notifications (FCM)** — Badge earned, new content, and payment success notifications; notification list screen with read/unread state.
- **Home page redesign** — Kid-friendly layout with large navigation cards (Dongeng, Tracing, Counting), a "Continue Learning" section, and icon-based navigation.
- **Child growth tracking** — Parents log weight and height; historical data displayed as line charts (fl_chart) on the Profile page, with optional WHO standard comparison.

## Capabilities

### New Capabilities

- `tracing-exercise`: Canvas tracing for alphabets, numbers, and shapes with stroke scoring and badge integration
- `counting-exercise`: Level-based counting and simple arithmetic exercises with badge integration
- `badge-system`: Per-feature and global badge tracking, thresholds, unlocking, and profile display
- `payment-subscription`: Midtrans Snap payment flow, webhook handling, and feature-access gating by subscription status
- `push-notifications`: FCM token registration, notification dispatch from backend, and in-app notification list screen
- `home-redesign`: Restructured home page with primary feature cards and recent activity section
- `growth-tracking`: Weight and height logging, historical chart display, and optional WHO percentile overlay

### Modified Capabilities

- `flutter-prod-hardening`: Home page navigation structure changes require updates to AppRouter and BottomNav

## Impact

- **Flutter**: New screens (tracing, counting, badge gallery, notification list, growth chart); new BLoC classes; updated home screen and profile screen; new dependencies (`fl_chart`, FCM plugin); AppRouter additions.
- **Backend (Go)**: New GORM models (tracing items/progress, counting questions/progress, badges, notifications, subscriptions, growth records); new service and handler packages; Midtrans SDK integration; FCM HTTP v1 API calls; new DB migration files.
- **Database**: ~8 new tables (see design.md).
- **External services**: Midtrans Snap API, Firebase Cloud Messaging (FCM).
- **No breaking changes** to existing AR, dongeng, or auth flows.

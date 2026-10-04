# Change: Backoffice feature toggles, payment history, and FCM promo push

## Why

- The printable-cards section and QR scanning can only be removed from the app with a new release. The business needs to hide/unhide them instantly from the backoffice.
- Users have no way to see what they bought, what is still pending, or to quote an order id to support.
- New AR cards and dongeng ship silently. The backend already has FCM sending and a campaign endpoint, but the app never registers for push, campaigns are synchronous (they time out on large audiences), guests can't be reached, and a notification can't open the content it announces.

## What Changes

- **Feature flags (backend)**: new `app_feature_flags` table (seeded `printable_cards`, `qr_scan`), public `GET /app/feature-flags`, admin `GET /admin/feature-flags` and `PATCH /admin/feature-flags/:key`.
- **Feature flags (backoffice)**: new "App Features" page with a switch per flag.
- **Feature flags (app)**: `FeatureFlagsNotifier` loads cached flags before first frame, refreshes on start, resume and home pull-to-refresh; defaults to enabled when unknown. Hidden QR scan removes the Scan tab (tabs become id-based so remaining tabs keep working and the nav reflows), unlinks the fallback hero banner, redirects `/ar-scan`, and hides the animal-detail scan button. Hidden printable cards removes the home section.
- **Payment history (backend)**: `GET /orders?page&per_page` — the caller's orders in every status, with item type/name (AR card, dongeng, package), amount, status, payment method label (bank/store resolved from the Midtrans payload), timestamps. Still-pending orders under 48h old are reconciled with Midtrans (max 5 per request).
- **Payment history (app)**: "Riwayat Pembayaran" screen reachable from Profile, paginated with pull-to-refresh, copyable order id.
- **Promo push (backend)**: campaigns are persisted (`campaigns` table) and delivered in the background with progress counters; new `all_devices` segment sends once to FCM topic `arunika_promo`; optional `image_url` and `link_type`/`link_id` (AR card or dongeng) delivered as FCM data; `GET /admin/campaigns` history; FCM credentials cached instead of re-parsed per send; subscribers segment excludes expired subscriptions. **BREAKING**: `POST /admin/campaigns` now returns `202` with the campaign row instead of `{sent, failed}`.
- **Promo push (backoffice)**: campaign form gains audience "all app installs", image URL, "when tapped, open" content picker, live preview, and a history table that polls while sending.
- **Promo push (app)**: add `firebase_messaging`; subscribe every install to the promo topic, register the token on login, rotate it on logout, show foreground messages as a snackbar, and open the linked content on tap using the same unlocked/login/purchase rules as in-app taps.

## Capabilities

### New Capabilities
- `app-feature-flags`
- `payment-history`
- `promo-push-notifications`

## Impact

- Backend: migrations `V44__create_app_feature_flags.sql`, `V45__create_campaigns.sql`; `services/{feature_flag_service,admin_campaign_service,notification_service,order_service,payment_method}.go`; handlers and routes.
- Backoffice: `src/pages/settings/FeatureFlagsPage.tsx`, `src/pages/campaigns/CampaignsPage.tsx`, `src/api/admin.ts`.
- App: `lib/core/feature_flags/`, `lib/services/push_notification_service.dart`, `lib/presentation/screens/payment_history/`, `main_shell.dart`, `new_home_screen.dart`, Android `POST_NOTIFICATIONS` permission.
- iOS push is out of scope: Firebase is not configured for iOS yet (`firebase_options.dart` throws on iOS); it needs `GoogleService-Info.plist`, APNs key upload and the Push Notifications capability.

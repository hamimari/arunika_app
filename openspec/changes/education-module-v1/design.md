## Context

Arunika is a Flutter app (BLoC, go_router, Dio, get_it) backed by a Go 1.23 API (Gin, GORM, PostgreSQL, Redis). The existing feature set covers authentication, AR card scanning, and audio fairy tales. This design covers adding seven new capabilities in three phases: core learning (tracing, counting, badges), engagement (home redesign, notifications), and monetisation (Midtrans payments, growth tracking).

Current architecture is well-established: layered Flutter (screen → BLoC → repository → API) and Go (handler → service → GORM model). All new features follow the same layers.

## Goals / Non-Goals

**Goals:**
- Canvas-based tracing with real-time stroke scoring and per-session progress persistence
- Level-gated counting exercises with server-validated answers
- Badge system that aggregates progress across all features automatically
- Midtrans Snap payment integration with webhook subscription updates
- FCM push notifications for key lifecycle events
- Kid-friendly home page redesign with feature cards and recent activity
- Weight/height growth tracking with fl_chart line charts

**Non-Goals:**
- Offline-first sync (network required for progress submission and payment)
- Real-time multiplayer or leaderboards
- Custom Midtrans checkout UI (use Snap redirect/webview)
- WHO growth percentile comparison (deferred post-MVP)
- Web or desktop support

## Decisions

### D1 — Tracing stroke scoring in Flutter, not backend
**Decision:** Stroke scoring runs fully on-device using a path-comparison algorithm (nearest-point distance against the guide path sampled at fixed intervals). Only the final pass/fail result and score are sent to the backend.
**Rationale:** Reduces latency, avoids sending raw stroke data (large payloads), and keeps the backend stateless for tracing evaluation. The backend only persists outcomes.
**Alternative considered:** Server-side scoring — rejected due to latency and payload size.

### D2 — Badge thresholds evaluated server-side on progress submission
**Decision:** After each exercise completion POST, the backend service checks whether the submission crosses a badge threshold and, if so, inserts a `user_badges` row in the same transaction. The Flutter app reads badge state on profile load.
**Rationale:** Centralises business logic; prevents client-side spoofing of badge awards; consistent across future entry points (e.g., web).
**Alternative considered:** Client-side badge calculation — rejected (spoofable, hard to audit).

### D3 — Midtrans Snap via in-app WebView redirect
**Decision:** The Flutter app calls the backend to create a Snap transaction, receives a `redirect_url`, and opens it in a WebView (`url_launcher` or `webview_flutter`). The backend receives the Midtrans webhook and updates `user_subscriptions`.
**Rationale:** Snap handles PCI compliance and all card/wallet UI. Webhook is the only reliable confirmation path (redirect callbacks can be dropped if user closes the app).
**Alternative considered:** Custom Midtrans Core API — rejected (requires PCI SAQ D, far more complex).

### D4 — FCM via Firebase Admin SDK (HTTP v1) from Go backend
**Decision:** The Go backend sends FCM notifications using the Firebase HTTP v1 REST API (`https://fcm.googleapis.com/v1/projects/{project}/messages:send`) authenticated via a service account JSON. FCM tokens are stored in a `fcm_tokens` table per user.
**Rationale:** Firebase Admin Go SDK is available but adds a large dependency; direct HTTP v1 calls with a service account are simpler and equally reliable.
**Alternative considered:** Firebase Admin SDK — acceptable but heavier; rejected for simplicity.

### D5 — fl_chart for growth visualization
**Decision:** Use `fl_chart` (already indirectly available via pub.dev) for weight and height line charts on the profile page.
**Rationale:** Best-maintained Flutter charting library, supports line charts with tooltips and zoom out of the box.
**Alternative considered:** `syncfusion_flutter_charts` — rejected (license cost for commercial use).

### D6 — Feature access middleware on the backend
**Decision:** A Go middleware `SubscriptionMiddleware` reads the user's `subscription_status` from the JWT claims (or DB lookup) and returns HTTP 403 for premium endpoints when status is `free`.
**Rationale:** Centralised access control; client UI can also check status to hide/show upgrade CTAs, but the backend is the authoritative gate.

### D7 — Database schema (new tables)
```
tracing_items        (id, type[alphabet|number|shape], label, guide_path_json, difficulty, created_at)
tracing_progress     (id, user_id, child_id, item_id, score, passed, created_at)
counting_questions   (id, level[easy|medium|hard], question_json, answer, created_at)
counting_progress    (id, user_id, child_id, question_id, is_correct, created_at)
badges               (id, feature[tracing|counting|global], level[beginner|explorer|master|all_rounder], threshold)
user_badges          (id, user_id, badge_id, earned_at)
user_subscriptions   (id, user_id, status[free|premium], expires_at, midtrans_order_id, created_at)
growth_records       (id, child_id, recorded_at, weight_kg, height_cm, created_at)
notifications        (id, user_id, title, body, type, is_read, created_at)
fcm_tokens           (id, user_id, token, created_at)
```

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Midtrans webhook delivery failure | Store pending payment state; expose a manual "check payment status" endpoint that polls Midtrans API |
| Stroke scoring accuracy on low-end devices | Tune the sampling interval; provide a generous tolerance (~15 px); favour encouragement over strictness |
| FCM token staleness | Refresh token on each app launch; delete stale tokens on 404 response from FCM |
| Large tracing guide_path_json blobs | Store as JSONB in PostgreSQL; add GIN index if query-filtered; cap path points at 200 |
| Badge race condition (concurrent submissions) | Use `INSERT ... ON CONFLICT DO NOTHING` for `user_badges`; wrap badge check + insert in a DB transaction |
| Midtrans webhook authentication | Validate `signature_key` (SHA-512 of `order_id + status_code + gross_amount + server_key`) on every webhook |

## Migration Plan

1. **Branch**: `feature/education-module-v1` (from `main`)
2. **Database**: Add Flyway migration files for the 10 new tables; no existing table alterations
3. **Backend deploy**: Zero-downtime — new endpoints are additive; existing endpoints unchanged
4. **Flutter**: Feature-flagged by subscription status (free users see Easy tier); no existing screens removed
5. **Rollback**: Drop the 10 new tables (no FK references from existing tables); revert Flutter to prior commit

## Open Questions

- **Tracing guide paths**: Will paths be authored by the content team and seeded via migration, or managed via an admin CMS? (Assume seeded via migration for v1.)
- **Midtrans environment**: Use Sandbox for development. Production credentials to be supplied by ops team before Phase 3.
- **FCM service account**: Needs to be created in Firebase Console and securely stored in backend config (not committed to git). Add `FIREBASE_SERVICE_ACCOUNT_JSON` to `.env.example`.
- **fl_chart version**: Confirm compatible version with current Flutter SDK before adding to `pubspec.yaml`.

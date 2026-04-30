## 1. Branch & Dependencies Setup

- [x] 1.1 Create feature branch `feature/education-module-v1` from `main` in both repos
- [x] 1.2 Add `fl_chart` to Flutter `pubspec.yaml` (verify compatible version with Flutter SDK)
- [x] 1.3 Add `webview_flutter` to Flutter `pubspec.yaml` (for Midtrans Snap payment WebView)
- [x] 1.4 Add `firebase_messaging` to Flutter `pubspec.yaml` (FCM)
- [x] 1.5 Add Midtrans Go client or configure direct HTTP v1 calls in backend `go.mod`
- [x] 1.6 Add `MIDTRANS_SERVER_KEY`, `MIDTRANS_CLIENT_KEY`, `FIREBASE_SERVICE_ACCOUNT_JSON` to backend `.env.example` and `validateEnv()` in `main.go`

## 2. Database Migrations

- [x] 2.1 Write Flyway migration: `tracing_items` table (id, type, label, guide_path_json JSONB, difficulty, created_at)
- [x] 2.2 Write Flyway migration: `tracing_progress` table (id, user_id, child_id, item_id FK, score, passed, created_at)
- [x] 2.3 Write Flyway migration: `counting_questions` table (id, level, question_json JSONB, answer, created_at)
- [x] 2.4 Write Flyway migration: `counting_progress` table (id, user_id, child_id, question_id FK, is_correct, created_at)
- [x] 2.5 Write Flyway migration: `badges` table (id, feature, level, threshold) and seed rows
- [x] 2.6 Write Flyway migration: `user_badges` table (id, user_id, badge_id FK, earned_at) with unique constraint
- [x] 2.7 Write Flyway migration: `user_subscriptions` table (id, user_id UNIQUE, status, expires_at, midtrans_order_id, created_at)
- [x] 2.8 Write Flyway migration: `growth_records` table (id, child_id, recorded_at, weight_kg, height_cm, created_at)
- [x] 2.9 Write Flyway migration: `notifications` table (id, user_id, title, body, type, is_read, created_at)
- [x] 2.10 Write Flyway migration: `fcm_tokens` table (id, user_id, token UNIQUE, created_at)
- [x] 2.11 Seed default `free` subscription row for all existing users via migration

## 3. Backend — GORM Models

- [x] 3.1 Create `models/tracing_item.go` and `models/tracing_progress.go`
- [x] 3.2 Create `models/counting_question.go` and `models/counting_progress.go`
- [x] 3.3 Create `models/badge.go` and `models/user_badge.go`
- [x] 3.4 Create `models/user_subscription.go`
- [x] 3.5 Create `models/growth_record.go`
- [x] 3.6 Create `models/notification.go` and `models/fcm_token.go`

## 4. Backend — Tracing & Counting Services and Handlers

- [x] 4.1 Create `services/tracing_service.go`: `GetItems(type)`, `SaveProgress(userID, childID, itemID, score, passed)` with badge check in same transaction
- [x] 4.2 Create `handlers/tracing_handler.go`: GET `/tracing/items`, POST `/tracing/progress`
- [x] 4.3 Register tracing routes in `routes/router.go` under JWT middleware
- [x] 4.4 Create `services/counting_service.go`: `GetQuestions(level)`, `SaveProgress(...)` with badge check
- [x] 4.5 Create `handlers/counting_handler.go`: GET `/counting/questions`, POST `/counting/progress`
- [x] 4.6 Register counting routes in `routes/router.go` under JWT + subscription middleware

## 5. Backend — Badge Service

- [x] 5.1 Create `services/badge_service.go`: `CheckAndAward(tx, userID, feature)` — evaluates thresholds and inserts `user_badges` rows using `ON CONFLICT DO NOTHING`
- [x] 5.2 Create `handlers/badge_handler.go`: GET `/badges` returning all badges with user earned status and progress
- [x] 5.3 Register badge routes in `routes/router.go`

## 6. Backend — Payment (Midtrans)

- [x] 6.1 Create `services/payment_service.go`: `CreateSnapTransaction(userID)` calling Midtrans Snap API
- [x] 6.2 Create `handlers/payment_handler.go`: POST `/payment/create`, POST `/payment/webhook`
- [x] 6.3 Implement webhook signature validation (`SHA-512(order_id + status_code + gross_amount + server_key)`)
- [x] 6.4 On settled webhook: update `user_subscriptions.status` to `premium`, set `expires_at` to now+30d, dispatch FCM notification
- [x] 6.5 Create `middlewares/subscription_middleware.go`: return HTTP 403 for premium routes when user status is `free`
- [x] 6.6 Register subscription middleware on counting hard/medium and full tracing routes
- [x] 6.7 Register payment routes in `routes/router.go` (webhook route skips JWT middleware)

## 7. Backend — Notifications & FCM

- [x] 7.1 Create `services/notification_service.go`: `Send(userID, title, body, type)` — inserts `notifications` row and calls FCM HTTP v1 API for all user tokens
- [x] 7.2 Handle FCM 404 response by deleting the stale token from `fcm_tokens`
- [x] 7.3 Create `handlers/notification_handler.go`: GET `/notifications`, PATCH `/notifications/:id/read`, POST `/notifications/token`
- [x] 7.4 Register notification routes in `routes/router.go`
- [x] 7.5 Call `notification_service.Send` from badge award path and payment webhook handler

## 8. Backend — Growth Tracking

- [x] 8.1 Create `services/growth_service.go`: `Save(childID, weight, height, recordedAt)`, `GetHistory(childID)`
- [x] 8.2 Create `handlers/growth_handler.go`: POST `/growth`, GET `/growth`
- [x] 8.3 Register growth routes in `routes/router.go`

## 9. Backend — Tests

- [x] 9.1 Write unit tests for `tracing_service.go` (get items, save progress, badge award path)
- [x] 9.2 Write unit tests for `counting_service.go` (get questions by level, save progress, badge award)
- [x] 9.3 Write unit tests for `badge_service.go` (threshold logic, idempotent award, all-rounder)
- [x] 9.4 Write unit tests for `payment_service.go` (create transaction, webhook signature validation, subscription update)
- [x] 9.5 Write unit tests for `notification_service.go` (send, stale token cleanup)
- [x] 9.6 Write unit tests for `growth_service.go` (save, get history)
- [x] 9.7 Run `go test ./...` and fix any failures

## 10. Flutter — AppRouter & Navigation

- [x] 10.1 Add routes to `AppRouter`: `/tracing`, `/tracing/:id`, `/counting`, `/counting/:id`, `/badges`, `/notifications`, `/growth`, `/payment`
- [x] 10.2 Add notification bell icon to home screen app bar navigating to `/notifications`

## 11. Flutter — Tracing Exercise

- [x] 11.1 Create `TracingRepository` and `TracingApi` (GET items, POST progress)
- [x] 11.2 Create `TracingListBloc` and `TracingListScreen` (list items by type with tab bar: Alphabet / Numbers / Shapes)
- [x] 11.3 Create `TracingExerciseBloc` and `TracingExerciseScreen` with CustomPainter canvas
- [x] 11.4 Implement guide path rendering from `guide_path_json` in CustomPainter
- [x] 11.5 Implement stroke capture and nearest-point scoring algorithm
- [x] 11.6 Add success animation (lottie or simple scale animation) and sound feedback on pass
- [x] 11.7 Add retry prompt with encouraging message on fail
- [x] 11.8 Submit result to backend on completion; dispatch `LoadMore` if badge earned

## 12. Flutter — Counting Exercise

- [x] 12.1 Create `CountingRepository` and `CountingApi` (GET questions by level, POST progress)
- [x] 12.2 Create `CountingListBloc` and `CountingListScreen` with Easy / Medium / Hard tabs; show lock on premium levels for free users
- [x] 12.3 Create `CountingExerciseBloc` and `CountingExerciseScreen` with visual object images and answer selection buttons
- [x] 12.4 Show green/red immediate feedback on answer selection
- [x] 12.5 Submit result to backend on each answer; advance to next question on correct

## 13. Flutter — Badge System

- [x] 13.1 Create `BadgeRepository` and `BadgeApi` (GET `/badges`)
- [x] 13.2 Create `BadgeBloc` and `BadgeGalleryScreen` (grid of badge cards, locked/unlocked, progress bar)
- [x] 13.3 Add badge gallery section to `ProfileScreen` below info cards

## 14. Flutter — Payment & Subscription

- [x] 14.1 Create `PaymentRepository` and `PaymentApi` (POST `/payment/create`)
- [x] 14.2 Create `PaymentBloc` and payment WebView screen (open `redirect_url` via `webview_flutter`)
- [x] 14.3 Show lock overlay + "Upgrade" button on premium content in counting and tracing list screens
- [x] 14.4 Reload subscription status after returning from WebView

## 15. Flutter — Push Notifications

- [x] 15.1 Initialize Firebase in `main.dart`; request notification permission
- [x] 15.2 Register FCM token with backend on login and on token refresh
- [x] 15.3 Create `NotificationRepository` and `NotificationApi` (GET list, PATCH read, POST token)
- [x] 15.4 Create `NotificationBloc` and `NotificationListScreen` (read/unread styling, timestamp, mark-as-read on tap)

## 16. Flutter — Home Page Redesign

- [x] 16.1 Redesign `HomeScreen` to show three primary feature cards (Dongeng, Tracing, Counting) with large icons and labels
- [x] 16.2 Add "Continue Learning" section below feature cards showing most recent tracing or counting activity
- [x] 16.3 Move story list to a dedicated "Dongeng" tab or secondary section; preserve search functionality
- [x] 16.4 Ensure all tap targets are ≥ 56 dp and layout is correct on 360 dp width screens

## 17. Flutter — Growth Tracking

- [x] 17.1 Create `GrowthRepository` and `GrowthApi` (POST `/growth`, GET `/growth`)
- [x] 17.2 Create `GrowthBloc` and growth input form (weight, height, date picker)
- [x] 17.3 Add fl_chart line charts (weight over time, height over time) to `ProfileScreen` below badge gallery
- [x] 17.4 Hide charts and show prompt when fewer than 2 records exist

## 18. Flutter — Tests

- [x] 18.1 Write unit tests for `TracingExerciseBloc` (load, pass, fail, submit)
- [x] 18.2 Write unit tests for `CountingExerciseBloc` (load, correct answer, wrong answer)
- [x] 18.3 Write unit tests for `BadgeBloc` (load badges, locked/unlocked state)
- [x] 18.4 Write unit tests for `PaymentBloc` (create transaction success/failure)
- [x] 18.5 Write unit tests for `NotificationBloc` (load list, mark as read)
- [x] 18.6 Write unit tests for `GrowthBloc` (submit record, load history)
- [x] 18.7 Run `flutter test` and fix any failures

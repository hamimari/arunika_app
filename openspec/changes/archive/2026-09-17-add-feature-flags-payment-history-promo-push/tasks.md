## 1. Feature flags
- [x] 1.1 Backend migration, model, service, public + admin endpoints, tests
- [x] 1.2 Backoffice App Features page, route, menu, tests
- [x] 1.3 App `FeatureFlagsNotifier` (cache, refresh on start/resume/pull-to-refresh), tests
- [x] 1.4 App: id-based main shell tabs; hide Scan tab, hero banner scan link, `/ar-scan` route, animal-detail scan button; hide printable section; widget test

## 2. Payment history
- [x] 2.1 Backend `GET /orders` with batch enrichment, payment method labels, bounded pending sync, tests
- [x] 2.2 App model, API, repository, cubit with pagination, tests
- [x] 2.3 App screen with copyable order id, route, Profile entry, widget tests

## 3. Promo push
- [x] 3.1 Backend `campaigns` table, async delivery, topic segment, link/image payload, history endpoint, cached FCM credentials, tests
- [x] 3.2 Backoffice campaign form (audience, image, content link picker, preview) and history table, tests
- [x] 3.3 App `firebase_messaging`, topic subscription, token register/rotate, foreground snackbar, tap deep links, Android permission, tests
- [ ] 3.4 Manual QA on a physical Android device: permission prompt, background/terminated tap opens linked dongeng/AR card, logout stops user-targeted pushes

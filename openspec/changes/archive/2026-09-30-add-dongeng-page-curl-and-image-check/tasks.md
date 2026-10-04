## 1. Backoffice page image check (arunika-backoffice) — can run in parallel with section 2
- [x] 1.1 `src/lib/pageImage.ts`: constants (ratio 1.70–2.00, minimum width 1280, crop preview at 2:1), a pure `checkPageImage({width, height})` that returns `ok | too_narrow | too_tall | too_wide`, and `loadImageSize(url)`, which uses `<img>` and `naturalWidth` / `naturalHeight` and rejects when the image fails to load
- [x] 1.2 `FairyTalePages` modal: an async validator on `image_url` (checked on blur and on save) that skips an empty value and returns the error text from the spec. A preview under the field, debounced 400 ms, shows the size and dims the 2:1 crop.
- [x] 1.3 Tests:
  - Unit: `checkPageImage`, including the edges (1.70, 2.00, 1279 / 1280 px), 1408×768 → ok, 2400×1792 → `too_tall`
  - Page: the save is blocked with the error text for too tall, too small and failed to load; an empty URL saves; a good image saves (`loadImageSize` mocked)
- [x] 1.4 Audit: `scripts/audit_page_images.ts`, run with `node scripts/audit_page_images.ts` (Node ≥22.18 strips types, so `tsx` isn't needed), using `API_BASE_URL`, `ADMIN_EMAIL` and `ADMIN_PASSWORD`. It reads the sizes of PNG, JPEG, GIF and WebP files from their bytes, reuses `checkPageImage`, and prints the failures as `title · page N · reason`. Checked on the e2e stack: 307 page images, 8 failing (placeholder 1024×1024 fixtures, plus one blocked r2.dev URL).
- [x] 1.5 Run the audit against the real backend and record the list. This needs the admin credentials for that environment. — **deferred to the owner** and tracked under "Tracked" in `docs/prerelease-triage.md`.
- [x] 1.6 `npm test` (214 passing), `npm run lint` (0 errors, the same 15 warnings as before), `tsc -b`. Playwright: 7 of 8 pass. The failure is `order-refunds`, whose Play verify call is refused because the e2e stack's fake Google token server isn't running. It is unrelated to this change.

## 2. App page curl (arunika_app)
- [x] 2.1 `lib/presentation/screens/dongeng/detail/page_curl/page_turn_controller.dart`: pure Dart. It holds the direction, progress, threshold (0.35), fling (800 px/s), the ends of the book and the one-turn-at-a-time lock, and it reports whether a turn completes or is cancelled.
- [x] 2.2 `page_curl/page_curl.dart`: clips the current image along a fold line that tilts mid-turn, draws the mirrored back of the page and the shadow gradients, and shows the neighbouring page underneath. Drag gestures go to the controller; arrow taps animate it for 450 ms.
- [x] 2.3 `dongeng_detail_screen.dart`: the image `AnimatedSwitcher` is replaced by the curl, and all overlays stay above it. Only a completed turn sends `NextPage` / `PreviousPage`. The neighbouring pages' images are precached. When `MediaQuery.disableAnimations` is true, the cross-fade is kept.
- [x] 2.4 Tests:
  - Unit: `PageTurnController` covers threshold, fling, spring-back, the ends of the book and ignoring input while a turn is running
  - Widget: `PageCurl` covers the drag, spring-back, fling, curl mid-drag, both ends, the arrow double tap and reduce motion. The screen covers a swipe that turns the page, a double tap on next that turns one page, and a drag that starts on the subtitle and doesn't turn.
- [x] 2.5 `flutter analyze` finds no new issues (9 older infos). `flutter test` passes (390 tests, the new ones included). The profile run on the emulator (`integration_test/perf`, now with swipes) drew 184 frames, raster p90 3.1 ms, max 12.0 ms, 0 over budget.

## 3. Content fix and wrap-up
- [x] 3.1a Crop `kancil-1.jpeg` to 2400×1350 (16:9) and save it as `~/Downloads/kancil-1-16x9.jpeg`. `checkPageImage` accepts it.
- [x] 3.1b Upload the cropped file and replace the page's Image URL through the backoffice (owner) — **deferred to the owner** and tracked under "Tracked" in `docs/prerelease-triage.md`.
- [x] 3.2 Fix any other pages that 1.5 lists in the same way, or list them in `docs/prerelease-triage.md` as follow-up — **deferred to the owner** and tracked under "Tracked" in `docs/prerelease-triage.md`.
- [x] 3.3 Record the page curl in `docs/prerelease-triage.md`: its emulator profile numbers, and that it still needs a check on a real device, together with task 4.5

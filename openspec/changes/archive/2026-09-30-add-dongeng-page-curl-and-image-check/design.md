## Context
`_PageReaderView` draws the current page's image full-bleed (`BoxFit.cover`) under fixed overlays (title bar, side arrows, subtitle, controls). The page index lives in `DongengDetailBloc` (`NextPage` / `PreviousPage`), and changing it stops the audio. Page images are stored as plain URLs, which an admin types into the backoffice.

## Goals / Non-Goals
- Goals: a page turn that feels like a paper book; stop badly shaped page images at entry time.
- Non-goals: reflowing or letterboxing existing images; server-side image checks; file upload.

## Decisions

### Page curl: built in the app, not from a package
- The curl is a small custom widget. It clips the current page along a fold line and draws the folded-over back of the page as a mirrored, lightened copy, with a shadow gradient on the fold and on the page underneath. The next (or previous) page is drawn underneath and shows as the fold moves.
- Why not a package: the pub.dev page-flip packages are small, single-maintainer projects. Most flip whole widget trees through an offscreen capture, which we don't need, since our pages are single images. Owning about 200 lines is safer than adding an unmaintained dependency to a release build.
- The gesture rules are a pure-Dart `PageTurnController`, kept separate from the painting and unit-tested in the same way as `PlacementMachine`:
  - A horizontal drag right-to-left turns forward. Left-to-right turns back: the previous page curls back in from the left.
  - On release, the turn completes when progress is ≥ 0.35 of the width, or when the fling velocity is ≥ 800 px/s in the turn's direction. Otherwise the page springs back.
  - A drag toward a page that doesn't exist (back on the first page, forward on the last) does not start a turn.
  - While a turn is animating, new drags and arrow taps are ignored. There is one turn at a time.
  - Only a completed turn sends `NextPage` / `PreviousPage` to the bloc. So the subtitle, the page counter and the audio stop all happen once, when the turn lands.
- Arrow taps play the same curl, for about 450 ms, from the bottom corner.
- The overlays stay above the curl and don't move. Drags that start on a control are handled by that control and don't start a turn.
- The pages on either side of the current one are precached (`precacheImage`), so the page shown under the fold is not a spinner.
- When `MediaQuery.disableAnimations` is true, the reader keeps today's cross-fade and has no curl.

### Image check: in the backoffice browser, blocking
- A rule module (`src/lib/pageImage.ts`) holds the constants and a pure `checkPageImage({width, height})`. It returns `ok`, or one of: `too_narrow`, `too_tall`, `too_wide`.
  - The shape must be between 1.70 and 2.00 (width ÷ height). 16:9 is 1.78, `kelinci.png` is 1.83, and phones in landscape are about 2.0–2.2. `kancil-1.jpeg` is 1.34 and fails.
  - The width must be at least 1280 px, so pages stay sharp on large phones.
- The form loads the URL with an `<img>` and reads `naturalWidth` / `naturalHeight`. A failed load is also a blocking error ("Could not load this image"). An image the reader can't load is broken there too.
- The URL gets an async antd `Form.Item` validator, so `validateFields()` in `handleSave` rejects the page and the modal's OK does nothing until the image passes. An empty Image URL is still allowed (the field is optional today) and skips the check.
- The preview shows the image with the part a 2:1 phone screen will crop dimmed. The admin can see what gets cut even for an image that passes.
- Why not on the backend: the check would need the server to fetch arbitrary admin-entered URLs (an SSRF surface) and to download multi-MB images on every save. The only people who enter images are trusted admins in the backoffice, so a browser check covers the real failure, which is a mistake, not an attack.

## Risks / Trade-offs
- **r2.dev blocking:** some Indonesian ISPs (Telkom Internet Positif) hijack `pub-*.r2.dev`. On such a network the check can fail with "Could not load this image" even for a good URL. That is the same failure users on that network see in the app, and it goes away once media is served from a custom domain. The error text says to check the URL or the network.
- **CORS is not needed:** reading `naturalWidth` from a plain `<img>` works cross-origin. No `crossOrigin` attribute and no canvas are used.
- **Curl performance:** the curl redraws a clipped full-screen image on every frame. Mitigation: the images are already decoded (precached), the painting uses clip plus transforms only (no shaders), and it is checked in profile mode on the emulator. The real-device check stays on the pre-release list (task 4.5 of the security gate).

## Open Questions
- None.

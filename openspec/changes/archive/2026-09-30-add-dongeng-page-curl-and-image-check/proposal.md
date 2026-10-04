# Change: Book-style page curl in the dongeng reader, and page image checks in the backoffice

## Why
1. The dongeng reader changes pages only through the side arrows, with a cross-fade. There is no swipe, and nothing about it feels like reading a book.
2. A newly added page image (`kancil-1.jpeg`, 2400×1792, 4:3) shows with its bottom cut off. The reader fills a landscape phone screen with `BoxFit.cover`, which is about 2:1. A 4:3 image loses about 38% of its height, and the subtitle bar hides part of what is left. Images shaped like `kelinci.png` (1408×768, about 16:9) lose only a thin strip. The backoffice accepts any URL in the page's Image URL field without checking it and without a preview, so an admin can't see the problem until the app shows it.

## What Changes
- **App (arunika_app):** the reader turns pages with a page curl. The page follows the finger when you drag it. On release it either completes the turn or springs back. The arrows play the same curl. The title bar, arrows, subtitle and controls stay in place, and only the picture turns. When the system "reduce motion" setting is on, the reader keeps the current cross-fade.
- **Backoffice (arunika-backoffice):** in the fairy tale **page** form, the Image URL is loaded in the browser once it is entered. The form shows a preview, the pixel size, and how the picture will be cropped on a phone. **Saving is blocked** when the image can't be loaded, when its shape is outside 1.70–2.00 (width ÷ height), or when it is narrower than 1280 px.
- A one-off audit lists the existing page images that fail the same rule, so they can be re-cropped and replaced by hand.

## Non-goals
- The reader keeps cropping images that are already uploaded with the wrong shape (`BoxFit.cover` stays). The fix for those is to re-crop and replace the URL, for example `kancil-1.jpeg` cropped to about 16:9.
- The fairy tale **cover** image (list cards) and other content types are not checked.
- The backend does not check images, because it would have to fetch admin-supplied URLs (see design.md).
- There is no file upload. The field stays a URL.

## Impact
- Affected specs: `dongeng-page-turn` (new), `dongeng-page-image-check` (new). `dongeng-navigation-fix` still applies unchanged: the arrows keep their safe-area insets.
- Affected code:
  - `arunika_app`: `lib/presentation/screens/dongeng/detail/dongeng_detail_screen.dart`, a new `page_curl/` widget and a pure-Dart turn controller next to it, and tests
  - `arunika-backoffice`: `src/pages/content/FairyTalesPage.tsx` (`FairyTalePages` modal), a new `src/lib/pageImage.ts`, and tests
- No API, database or migration changes.

## Why

Three connected bugs in the AR scan and playback flow break the core user experience: scanning a valid QR code does nothing visible, the AR core screen never shows a play-audio button even when the card has audio, and the "Putar Suara" button stays in "playing" state after audio finishes. These issues together make the flagship AR scan feature non-functional.

## What Changes

- **Fix QR scan confirmation flow**: `ArScanShell` sets `_qrDetected = true` and shows a bottom card with "Lihat AR", but the `BlocListener` that should navigate on `ModelLoaded` is either missing or not wired to the correct `QRScannerBloc` in that screen. The listener must dispatch `FetchModelById` on confirm and navigate on `ModelLoaded`.
- **Show audio button in AR core screen**: `ArCoreSurfacePlaceScreen` only initialises `_audioPlayer` when `soundUrl` is non-null and non-empty. When `soundUrl` arrives as an empty string `""` (which happens when `QRScannerBloc` emits `ModelLoaded` with `soundUrl: response.audioUrl` and `audioUrl` is empty), the button never appears. Fix the guard and ensure `soundUrl` propagation from bloc → screen is correct.
- **Reset "Putar Suara" button state on audio end**: `ArCardDetailScreen` uses a manual `_isPlaying` bool that is never reset when `just_audio` finishes playback naturally. Wire a `playerStateStream` listener to flip `_isPlaying = false` when the player transitions to the completed/stopped state.

## Capabilities

### New Capabilities

_(none — all changes are bug fixes to existing capabilities)_

### Modified Capabilities

- `ar-scan-flow`: QR code scan result confirmation and navigation to AR core screen must work end-to-end.
- `ar-sound-playback`: Audio button must appear in AR core screen when `soundUrl` is non-empty; "Putar Suara" button state must reset after playback ends.

## Impact

- `lib/presentation/screens/arscanner/ar_scan_shell.dart` — BlocListener / navigation fix
- `lib/presentation/screens/arscanner/ar_core_screen.dart` — `soundUrl` guard + `_audioPlayer` init fix
- `lib/presentation/screens/arscanner/ar_card_detail_screen.dart` — `_isPlaying` state reset on audio completion
- `lib/presentation/screens/qrscanner/qr_scanner_bloc.dart` — possibly `soundUrl` emission path
- No new dependencies; no API changes; no breaking changes.

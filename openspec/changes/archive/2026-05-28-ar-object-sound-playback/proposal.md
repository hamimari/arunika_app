## Why

The AR placement screen shows a 3D object but has no audio dimension — objects that represent real-world items (animals, products, characters) are richer when they can speak or make their natural sound. `just_audio` is already declared in `pubspec.yaml` but unused; this change activates it.

## What Changes

- `ArCoreSurfacePlaceScreen` gains an optional `soundUrl` parameter (`String?`, nullable so existing call-sites are unaffected).
- After the AR object is successfully placed (`_state == placed`), a **"Play Sound" button** appears as a floating overlay.
- Tapping the button streams and plays the MP3 from `soundUrl`; a loading indicator replaces the icon while buffering.
- If playback is already in progress, tapping again stops it (toggle behaviour).
- The button is not rendered when `soundUrl` is null or empty.

## Capabilities

### New Capabilities

- `ar-sound-playback`: Stream and play an MP3 from a URL via a button overlay on the AR placement screen, using `just_audio`. Supports play/stop toggle and buffering state.

### Modified Capabilities

<!-- none -->

## Impact

- **`lib/presentation/screens/arscanner/ar_core_screen.dart`** — add `soundUrl` parameter, `AudioPlayer` lifecycle, and sound button overlay widget.
- **`just_audio: ^0.9.36`** — already in `pubspec.yaml`; no version change needed.
- **No breaking changes** — `soundUrl` is optional/nullable; all existing callers continue to work without modification.
- **Tests** — new widget tests for the sound button visibility and toggle behaviour.

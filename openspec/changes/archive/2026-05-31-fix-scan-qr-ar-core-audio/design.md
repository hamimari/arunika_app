## Context

The app has three interrelated bugs in the AR scan and audio playback flow:

1. **Scan tab does nothing on valid QR**: `ArScanShell` (`ar_scan_shell.dart`) uses `_onQRViewCreated` to listen on `scannedDataStream`. On detect it sets `_qrDetected = true` and shows a confirmation card. Tapping "Lihat AR" calls `_confirmScan()` which dispatches `FetchModelById(_detectedCode)` to `QRScannerBloc`. A `BlocListener` should react to `ModelLoaded` and push `ArCoreSurfacePlaceScreen`. Investigation is needed to confirm whether the listener exists but is mis-scoped, or is absent entirely.

2. **No audio button in AR core screen**: `ArCoreSurfacePlaceScreen` guards `_audioPlayer` init with `soundUrl != null && soundUrl!.isNotEmpty`. The bloc emits `ModelLoaded(fileUrl, soundUrl: response.audioUrl)`. If `audioUrl` on the response is `null`, `soundUrl` becomes `null` but the parameter has a default; if it comes back as `""`, the guard fails. The `_SoundButton` widget is only shown when `_audioPlayer != null`, so any falsy `soundUrl` silently hides the button.

3. **"Putar Suara" stuck in playing state**: `ArCardDetailScreen` uses a manual `bool _isPlaying` toggled in `_toggleAudio()`. `just_audio`'s `AudioPlayer` fires a `PlayerState` with `processingState == ProcessingState.completed` when playback ends naturally, but no listener resets `_isPlaying`, leaving the button showing "Stop" indefinitely.

## Goals / Non-Goals

**Goals:**
- QR scan in bottom nav tab triggers AR core screen navigation on success.
- AR core screen shows play-audio button whenever `soundUrl` is a non-empty string.
- "Putar Suara" button in `ArCardDetailScreen` resets to idle state when audio finishes.

**Non-Goals:**
- Changing the AR rendering engine or model-loading logic.
- Adding new audio features (looping, seek bar, volume control).
- Fixing the standalone `QRScannerPage` (Scan Again flow) — it already has the BlocListener pattern; only `ArScanShell` is in scope.

## Decisions

### D1 — Fix BlocListener in ArScanShell
Look at `ar_scan_shell.dart`; the `BlocConsumer` or `BlocListener` must wrap the full widget tree with `QRScannerBloc` in scope. If the listener is absent, add it. If it exists but the `context` used for `Navigator.push` is not a descendant of the `BlocProvider`, lift the listener or pass the bloc explicitly.

**Alternative considered:** Move navigation logic into the bloc's event handler — rejected because navigation is UI concern, not bloc concern.

### D2 — Normalise soundUrl propagation
In `ArScanShell._confirmScan` (or the bloc), ensure `soundUrl` passed to `ArCoreSurfacePlaceScreen` is either a valid non-empty string or `null`. Change the constructor parameter to `String? soundUrl` and keep the existing guard `soundUrl != null && soundUrl.isNotEmpty`. No change needed to `_SoundButton`.

**Alternative considered:** Change the guard to `soundUrl?.isNotEmpty == true` inline — same effect, less clear.

### D3 — Reset _isPlaying via playerStateStream
In `ArCardDetailScreen.initState`, add a listener on `_audioPlayer.playerStateStream`. When `state.processingState == ProcessingState.completed` (or `state.playing == false && state.processingState == ProcessingState.idle`), call `setState(() => _isPlaying = false)`. Cancel the subscription in `dispose`.

**Alternative considered:** Use `_audioPlayer.playingStream` — does not fire on natural completion with processingState, so `playerStateStream` is more reliable.

## Risks / Trade-offs

- [Risk] `ArScanShell` BlocListener fix may miss edge cases where bloc is rebuilt → Mitigation: use `listenWhen` to only react to `ModelLoaded` and `ModelError` states.
- [Risk] `playerStateStream` emits multiple times during seek/buffer → Mitigation: guard the reset with `processingState == ProcessingState.completed` specifically.
- [Risk] `soundUrl` empty string vs null difference between API versions → Mitigation: normalise at the bloc layer: `soundUrl: (response.audioUrl?.isNotEmpty == true) ? response.audioUrl : null`.

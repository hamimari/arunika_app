## Context

`ArCoreSurfacePlaceScreen` is a single `StatefulWidget` in `lib/presentation/screens/arscanner/ar_core_screen.dart` (~685 lines). It already manages `AnimationController` objects for the entrance animation and ripple effect, and disposes them in `dispose()`. The `just_audio` package (`^0.9.36`) is declared in `pubspec.yaml` but unused.

After placement (`_state == placed`), the only persistent overlay is the always-visible "Scan Again" button at the bottom. A sound button will be added to this post-placement UI layer.

## Goals / Non-Goals

**Goals:**
- Accept an optional `soundUrl` parameter on `ArCoreSurfacePlaceScreen`.
- Show a "Play Sound" FAB-style button only after the object is placed and only when `soundUrl` is non-null.
- Stream the MP3 from the URL using `just_audio`; show a loading indicator while buffering.
- Toggle: tap once to play, tap again to stop; icon reflects current state.
- Dispose the `AudioPlayer` in `dispose()` to prevent resource leaks.

**Non-Goals:**
- No volume control, seek bar, or playlist.
- No offline caching of the audio file.
- No background audio / audio continuing after screen is closed.
- No changes to existing callers of `ArCoreSurfacePlaceScreen` — `soundUrl` is nullable.

## Decisions

### D1 — Use `just_audio` (already declared)
`just_audio` is already in `pubspec.yaml`. It supports `setUrl()` + `play()` / `stop()`, streams `PlayerState` for reactive UI, and handles HTTP audio out of the box. No new dependency needed.

### D2 — Single `AudioPlayer` instance, created in `initState`, disposed in `dispose()`
One player instance lives with the widget. `setUrl()` is called lazily on first tap (not at widget init) to avoid unnecessary network requests if the user never taps the button.

Alternative considered: create the player on first tap. Rejected because it complicates disposal tracking — the widget may be disposed before the player is fully created.

### D3 — Play/stop toggle (not play/pause)
`stop()` (not `pause()`) is used so replaying from the start is natural. A character sound or animal call should restart from the beginning every time. `pause()` would require tracking position and is unnecessary complexity.

### D4 — Button positioned above "Scan Again" button
The sound button sits above the always-visible "Scan Again" button (`bottom: 90` vs the button's `bottom: 30`). This avoids redesigning the existing layout. It appears/disappears with a `AnimatedOpacity` tied to `_state == placed`.

### D5 — State reflected via `StreamBuilder` on `player.playerStateStream`
`just_audio` exposes `playerStateStream` which emits `PlayerState` with `playing` bool and `ProcessingState` enum. The button icon switches between:
- `Icons.volume_up` — idle / stopped
- `CircularProgressIndicator` — buffering (`ProcessingState.buffering` / `loading`)
- `Icons.stop` — actively playing

This is purely reactive — no extra `setState` needed for audio state.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| Network failure when loading the MP3 URL | Wrap `setUrl()` + `play()` in try/catch; show a `SnackBar` on error |
| `just_audio` on iOS requires `NSAppTransportSecurity` or HTTPS URLs | Document requirement; enforce HTTPS URLs at the API layer |
| Player not disposed if widget is torn down mid-buffering | `dispose()` calls `_audioPlayer.dispose()` unconditionally |
| Button tap during placement animation (before `placed`) | Button is only rendered when `_state == placed` — no guard needed |

## Migration Plan

No migration needed. `soundUrl` is nullable — all existing `ArCoreSurfacePlaceScreen(modelUrl: ...)` call-sites continue to work unchanged.

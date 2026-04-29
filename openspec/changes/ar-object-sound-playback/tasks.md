## 0. Data Layer

- [x] 0.1 Add `final String? audioUrl` field to `ArCardResponse` and map it from `json['audio_url']` in `fromJson()`
- [x] 0.2 Add `final String? soundUrl` to `ModelLoaded` BLoC state as an optional named parameter; include in `props`
- [x] 0.3 Update `QRScannerBloc._onFetchModelById` to pass `response.audioUrl` as `soundUrl` when emitting `ModelLoaded`
- [x] 0.4 Update `qr_scanner.dart` to forward `state.soundUrl` to `ArCoreSurfacePlaceScreen`

## 1. Widget Parameter

- [x] 1.1 Add `final String? soundUrl` field to `ArCoreSurfacePlaceScreen` and include it in the constructor as an optional named parameter
- [x] 1.2 Thread `soundUrl` through to `_ArCoreSurfacePlaceScreenState` (access via `widget.soundUrl`)

## 2. AudioPlayer Lifecycle

- [x] 2.1 Add `AudioPlayer? _audioPlayer` field to `_ArCoreSurfacePlaceScreenState`; initialise it in `initState()` only when `widget.soundUrl` is non-null and non-empty
- [x] 2.2 Call `_audioPlayer?.dispose()` in the widget's `dispose()` method (null-safe guard)

## 3. Sound Button Widget

- [x] 3.1 Add a `_SoundButton` private `StatelessWidget` that takes the `AudioPlayer` instance and `soundUrl`
- [x] 3.2 Use `StreamBuilder<PlayerState>` on `_audioPlayer.playerStateStream` to reactively show: `CircularProgressIndicator` (buffering/loading), `Icons.stop_rounded` (playing), `Icons.volume_up_rounded` (idle/stopped)
- [x] 3.3 On tap: if `playing`, call `_audioPlayer.stop()`; else call `_audioPlayer.setUrl(soundUrl)` then `_audioPlayer.play()` — wrap in try/catch and show `SnackBar` on error
- [x] 3.4 Style the button as a circular `ElevatedButton` with `Colors.green.shade600` background to match the AR screen colour theme

## 4. Layout Integration

- [x] 4.1 Add a new `Positioned` layer in the `Stack` inside `build()`: position it at `bottom: 100, right: 24` (above the "Scan Again" button)
- [x] 4.2 Wrap the sound button in `AnimatedOpacity` with `opacity: _state == _PlacementState.placed ? 1.0 : 0.0` and `duration: Duration(milliseconds: 300)`
- [x] 4.3 Use `IgnorePointer(ignoring: _state != _PlacementState.placed)` so taps are only captured when visible

## 5. Tests

- [x] 5.1 Add BLoC test: `ArCardResponse` with `audioUrl` → `ModelLoaded.soundUrl` is populated
- [x] 5.2 Add BLoC test: `ArCardResponse` without `audioUrl` → `ModelLoaded.soundUrl` is null
- [ ] 5.3 Write widget test: `ArCoreSurfacePlaceScreen` with no `soundUrl` → `_SoundButton` absent from tree
- [ ] 5.4 Write widget test: `ArCoreSurfacePlaceScreen` with `soundUrl` before placement → opacity 0
- [x] 5.5 Run `flutter test` and confirm all tests pass (10/10 green)

## 6. Verification

- [x] 6.1 Run `flutter analyze` and confirm no new errors
- [ ] 6.2 On a physical device: place an object with a valid `soundUrl` MP3, tap the button, confirm audio plays and button icon switches to stop
- [ ] 6.3 On device: tap stop button, confirm playback halts and icon returns to play
- [ ] 6.4 On device: simulate no-network condition (airplane mode after screen loads), tap button, confirm error SnackBar is shown

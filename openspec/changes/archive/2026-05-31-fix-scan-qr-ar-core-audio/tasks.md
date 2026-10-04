## 1. Fix QR Scan Navigation in ArScanShell

- [x] 1.1 Read `ar_scan_shell.dart` and verify whether a `BlocListener` for `QRScannerBloc` exists and is correctly scoped within the `BlocProvider`
- [x] 1.2 If missing, add a `BlocListener<QRScannerBloc, QRScannerState>` inside `_ArScanView` that listens for `ModelLoaded` and calls `Navigator.push` to `ArCoreSurfacePlaceScreen`
- [x] 1.3 If the listener exists but the `context` is wrong, lift the `BlocListener` to wrap the `Scaffold` so `Navigator.push` has a valid context
- [x] 1.4 Add `listenWhen` to only react to `ModelLoaded` and `ModelError` states to avoid spurious rebuilds
- [x] 1.5 Verify that `_resetScanner()` is called in the `.then()` callback after the AR screen is popped

## 2. Normalise soundUrl in QRScannerBloc

- [x] 2.1 Open `qr_scanner_bloc.dart` and locate the `_onFetchModelById` handler
- [x] 2.2 Change `soundUrl: response.audioUrl` to `soundUrl: (response.audioUrl?.isNotEmpty == true) ? response.audioUrl : null`
- [x] 2.3 Confirm `ModelLoaded` state still passes `soundUrl` as `String?` (no type change needed)

## 3. Fix Audio Button Visibility in ArCoreSurfacePlaceScreen

- [x] 3.1 Open `ar_core_screen.dart` and locate the `initState` guard for `_audioPlayer` init
- [x] 3.2 Confirm the guard is `soundUrl != null && soundUrl!.isNotEmpty` — this is correct; ensure `soundUrl` arriving as `null` (from fix in task 2.2) properly skips init
- [ ] 3.3 Manually test: scan a card with a known `sound_url` value — confirm `_SoundButton` appears after AR object is placed

## 4. Reset _isPlaying State After Audio Completion in ArCardDetailScreen

- [x] 4.1 Open `ar_card_detail_screen.dart` and locate `initState` where `_audioPlayer` is initialised
- [x] 4.2 Add a listener on `_audioPlayer.playerStateStream` that calls `setState(() => _isPlaying = false)` when `state.processingState == ProcessingState.completed`
- [x] 4.3 Store the `StreamSubscription` returned by the listener
- [x] 4.4 Cancel the subscription in `dispose()` before `_audioPlayer.dispose()`
- [ ] 4.5 Verify the button label switches back to "Putar Suara" automatically after a track ends

## 5. Manual End-to-End Verification

- [ ] 5.1 Open the app on a device, tap the Scan tab, scan a valid QR code, tap "Lihat AR" — confirm navigation to AR core screen
- [ ] 5.2 Confirm `_SoundButton` is visible after placing the AR object when the card has `sound_url`
- [ ] 5.3 Confirm `_SoundButton` is absent when the card has no `sound_url`
- [ ] 5.4 In `ArCardDetailScreen`, tap "Putar Suara", let audio finish — confirm button returns to idle state without a second tap

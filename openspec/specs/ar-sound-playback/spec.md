### Requirement: Sound URL parameter
`ArCoreSurfacePlaceScreen` SHALL accept an optional `soundUrl` parameter of type `String?`. When `soundUrl` is null or empty, all sound-related UI SHALL be hidden and no `AudioPlayer` SHALL be initialised. The `QRScannerBloc` SHALL normalise `soundUrl` before emission: if `response.audioUrl` is null or empty string, it SHALL emit `soundUrl: null`.

#### Scenario: Widget renders without sound URL
- **WHEN** `ArCoreSurfacePlaceScreen` is constructed without a `soundUrl`
- **THEN** the play sound button is not present in the widget tree

#### Scenario: Widget renders with sound URL
- **WHEN** `ArCoreSurfacePlaceScreen` is constructed with a non-empty `soundUrl`
- **THEN** the play sound button is present in the widget tree (though possibly not yet visible)

#### Scenario: Bloc normalises empty string to null
- **WHEN** `ArCardResponse.audioUrl` is an empty string `""`
- **THEN** `QRScannerBloc` emits `ModelLoaded` with `soundUrl: null`
- **AND** the play sound button is not shown in `ArCoreSurfacePlaceScreen`

### Requirement: Play sound button visibility
The play sound button SHALL only be visible after the AR object has been successfully placed (`_state == placed`). It SHALL not be visible during scanning, ready, or placing states.

#### Scenario: Button hidden before placement
- **WHEN** the AR session is in scanning, ready, or placing state
- **THEN** the play sound button is not visible

#### Scenario: Button visible after placement
- **WHEN** the AR object has been placed (`_state == placed`)
- **AND** `soundUrl` is non-null and non-empty
- **THEN** the play sound button is visible on screen

### Requirement: Play sound on tap
When the play sound button is tapped and the player is not currently playing, the system SHALL begin streaming and playing the MP3 from `soundUrl`.

#### Scenario: First tap starts playback
- **WHEN** the user taps the play sound button while audio is stopped
- **THEN** playback begins from the start of the audio file
- **AND** the button icon changes to a stop indicator

#### Scenario: Buffering state shown
- **WHEN** the audio is loading or buffering from the network
- **THEN** the button displays a loading indicator instead of the play/stop icon

### Requirement: Stop sound on tap
When the play sound button is tapped while audio is playing, the system SHALL stop playback immediately.

#### Scenario: Second tap stops playback
- **WHEN** the user taps the play sound button while audio is playing
- **THEN** playback stops immediately
- **AND** the button icon returns to the play indicator

### Requirement: Audio player resource management
The `AudioPlayer` instance SHALL be properly disposed when the widget is removed from the tree to prevent resource leaks.

#### Scenario: Player disposed on widget removal
- **WHEN** `ArCoreSurfacePlaceScreen` is disposed
- **THEN** the `AudioPlayer` instance is disposed

### Requirement: Audio playback state reset on completion
In `ArCardDetailScreen`, the "Putar Suara" button SHALL automatically return to its idle (not-playing) state when the audio track finishes playing naturally, without requiring a second tap from the user.

#### Scenario: Button resets after natural playback end
- **WHEN** audio is playing via the "Putar Suara" button
- **AND** the track reaches its end
- **THEN** `_isPlaying` is set to `false`
- **AND** the button label changes back to "Putar Suara"

#### Scenario: Button not stuck after completion
- **WHEN** the audio finishes and the user has not tapped stop
- **THEN** the button does not remain in the "playing/stop" state

### Requirement: Network error handling
If loading the audio URL fails (network error, invalid URL, server error), the system SHALL show an error message to the user and the button SHALL return to the idle play state.

#### Scenario: URL load failure
- **WHEN** the user taps the play sound button
- **AND** the URL cannot be loaded
- **THEN** an error message is displayed (e.g., via SnackBar)
- **AND** the button returns to the idle play icon

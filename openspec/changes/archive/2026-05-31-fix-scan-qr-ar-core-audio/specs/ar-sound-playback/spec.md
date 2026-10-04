## MODIFIED Requirements

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

## ADDED Requirements

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

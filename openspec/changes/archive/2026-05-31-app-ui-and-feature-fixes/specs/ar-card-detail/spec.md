## ADDED Requirements

### Requirement: AR card detail screen before AR launch
The app SHALL display an `ArCardDetailScreen` when the user taps an unlocked AR card in Koleksiku. This screen SHALL show the card image (full-width, rounded corners), a fun fact section (title "Tahukah Kamu?" and body text from `card.funFact`), a "Putar Suara" button that plays the card's audio, and a "Lihat AR" button that pushes `ArCoreSurfacePlaceScreen`.

#### Scenario: Detail screen shows card content
- **WHEN** the user taps an unlocked AR card on the Koleksi screen
- **THEN** `ArCardDetailScreen` opens showing the card image, fun fact text, Putar Suara button, and Lihat AR button

#### Scenario: Fun fact section shows placeholder when empty
- **WHEN** the tapped card has no `funFact` value
- **THEN** the fun fact section shows "Fun fact belum tersedia untuk kartu ini."

#### Scenario: Putar Suara plays audio
- **WHEN** the user taps the "Putar Suara" button on the detail screen
- **THEN** the card's audio file (`audioUrl`) begins playing; the button icon toggles to a stop/pause state

#### Scenario: Lihat AR launches AR screen
- **WHEN** the user taps the "Lihat AR" button on the detail screen
- **THEN** `ArCoreSurfacePlaceScreen` is pushed with `modelUrl` and `soundUrl` from the card

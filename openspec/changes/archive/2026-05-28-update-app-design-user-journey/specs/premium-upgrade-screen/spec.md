## ADDED Requirements

### Requirement: Premium upgrade screen with tabs
The premium upgrade screen SHALL display two tabs: "Paket Konten" (content packs) and "Langganan" (subscription).

#### Scenario: Paket Konten tab shows pack cards
- **WHEN** the user opens the upgrade screen with "Paket Konten" tab selected
- **THEN** pack cards are shown: Farm Animals Pack (Rp 29.000), Ocean World Pack (Rp 39.000), Dinosaur Pack (Rp 49.000), ALL ACCESS PASS (Rp 149.000)

#### Scenario: Best value pack highlighted
- **WHEN** the upgrade screen is displayed
- **THEN** the ALL ACCESS PASS card is marked with a "BEST VALUE" badge

### Requirement: Pack card details
Each pack card SHALL display the pack name, subtitle (e.g., "20+ animals & 5 stories"), price in IDR, and a select/buy button.

#### Scenario: Pack card is tappable
- **WHEN** the user taps a pack card
- **THEN** the app proceeds to the payment screen for that pack

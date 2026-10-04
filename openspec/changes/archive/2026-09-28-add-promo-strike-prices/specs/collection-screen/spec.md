## ADDED Requirements

### Requirement: Locked AR cards show price and strike price
Each locked AR card in the Koleksi grid that has a `price_idr` SHALL show its price, formatted as "Rp 15.000", using the shared price tag. When `strike_price_idr` is non-null, the strike price SHALL be shown crossed out next to the price. Unlocked cards and cards without a price SHALL NOT show a price.

#### Scenario: Locked card with strike price
- **WHEN** a locked AR card has `price_idr = 15000` and `strike_price_idr = 19000`
- **THEN** the card SHALL show "Rp 15.000" and a crossed-out "Rp 19.000"

#### Scenario: Locked card without strike price
- **WHEN** a locked AR card has `price_idr = 15000` and `strike_price_idr = null`
- **THEN** the card SHALL show only "Rp 15.000"

#### Scenario: Unlocked card
- **WHEN** an AR card is unlocked for the user
- **THEN** no price SHALL be shown on it

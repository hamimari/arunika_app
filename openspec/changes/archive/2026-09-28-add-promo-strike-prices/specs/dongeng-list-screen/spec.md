## ADDED Requirements

### Requirement: Paid dongeng show price and strike price
Each dongeng in the dongeng list that is locked for the user and has a `price_idr` SHALL show its price, formatted as "Rp 39.000", using the shared price tag. When `strike_price_idr` is non-null, the strike price SHALL be shown crossed out next to the price. Free or already-owned dongeng SHALL NOT show a price.

#### Scenario: Locked dongeng with strike price
- **WHEN** a locked dongeng has `price_idr = 39000` and `strike_price_idr = 49000`
- **THEN** its list item SHALL show "Rp 39.000" and a crossed-out "Rp 49.000"

#### Scenario: Owned dongeng
- **WHEN** the user already owns a paid dongeng
- **THEN** its list item SHALL NOT show a price

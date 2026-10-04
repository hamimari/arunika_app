## MODIFIED Requirements

### Requirement: PremiumPack model maps from API response
The existing `PremiumPack` data class SHALL be updated with a `fromJson` factory constructor. All fields (`id`, `name`, `subtitle`, `priceIdr`, `isBestValue`, `badgeLabel`, `strikePriceIdr`, `discountPercent`, `promoEndsAt`) SHALL map directly from the API JSON keys (`id`, `name`, `subtitle`, `price_idr`, `is_best_value`, `badge_label`, `strike_price_idr`, `discount_percent`, `promo_ends_at`). `strikePriceIdr`, `discountPercent` and `promoEndsAt` (parsed as `DateTime`) SHALL be nullable.

#### Scenario: JSON deserialised correctly
- **WHEN** the API returns a package JSON object
- **THEN** `PremiumPack.fromJson` SHALL produce a `PremiumPack` with all fields populated

#### Scenario: Nullable badge_label handled
- **WHEN** the API returns a package with `badge_label: null`
- **THEN** the resulting `PremiumPack.badgeLabel` SHALL be `null` and no badge SHALL be shown

#### Scenario: Missing strike fields handled
- **WHEN** the API returns a package without `strike_price_idr` or with it set to `null`
- **THEN** `PremiumPack.strikePriceIdr`, `discountPercent` and `promoEndsAt` SHALL be `null`, and deserialisation SHALL NOT fail

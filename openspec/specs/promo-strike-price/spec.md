# promo-strike-price Specification

## Purpose
Defines display-only promotional strike prices ("harga coret"): backoffice-configured global and per-item rules, always time-limited (at most 90 days), computed by the backend and shown next to the real price, which is the only amount ever charged.
## Requirements
### Requirement: Global strike-price rules per scope
The system SHALL have a `strike_price_rules` table keyed by `scope` (`AR_CARD`, `DONGENG`, `PACKAGE`). Each row SHALL have a `mode` (`NONE`, `PERCENT`, `FIXED`), an integer `value`, and a promo period `starts_at` / `ends_at` (TIMESTAMPTZ). `ends_at` SHALL be required when `mode` is not `NONE`. `starts_at` MAY be null, meaning the promo starts immediately. A migration SHALL seed all three scopes with `mode = 'NONE'`, `value = 0` and no period.

#### Scenario: Seeded rules show no strike price
- **WHEN** the migration runs on a database with existing products and packages
- **THEN** all three rules SHALL exist with `mode = 'NONE'`, and no API response SHALL include a non-null `strike_price_idr`

#### Scenario: Invalid mode rejected
- **WHEN** a rule is written with a `mode` outside `NONE`, `PERCENT`, `FIXED`
- **THEN** the database SHALL reject it with a constraint violation

#### Scenario: Active promo without end date rejected
- **WHEN** a rule is written with `mode = 'PERCENT'` and `ends_at = NULL`
- **THEN** the database SHALL reject it with a constraint violation

### Requirement: Per-item strike-price override
`products` and `premium_packages` SHALL each have nullable `strike_mode` (`NONE`, `PERCENT`, `FIXED`), `strike_value`, `strike_starts_at` and `strike_ends_at` columns. `strike_ends_at` SHALL be required when `strike_mode` is `PERCENT` or `FIXED`. A NULL `strike_mode` SHALL mean the item inherits its scope's global rule. `strike_mode = 'NONE'` SHALL always suppress the strike price for that item. A `PERCENT`/`FIXED` override SHALL take precedence over the global rule while its own period is active. Outside its period, the item SHALL fall back to the global rule. A product's scope SHALL be its feature code (`AR_CARD` or `DONGENG`). Every package's scope SHALL be `PACKAGE`.

#### Scenario: Item inherits global rule
- **WHEN** the `DONGENG` rule is `PERCENT 20` with an active period, and a dongeng product priced 39000 has `strike_mode = NULL`
- **THEN** that dongeng's `strike_price_idr` SHALL be 49000

#### Scenario: Active item override wins over global rule
- **WHEN** the `AR_CARD` rule is `PERCENT 20`, and an AR card product priced 15000 has an active `FIXED 5000` override
- **THEN** that AR card's `strike_price_idr` SHALL be 20000

#### Scenario: Expired item override falls back to global rule
- **WHEN** an AR card's `FIXED 5000` override has `strike_ends_at` in the past, and the `AR_CARD` rule is an active `PERCENT 20`
- **THEN** the card's strike price SHALL be computed from the `AR_CARD` rule

#### Scenario: Item opts out of a global rule
- **WHEN** the `PACKAGE` rule is an active `FIXED 10000`, and a package has `strike_mode = 'NONE'`
- **THEN** that package's `strike_price_idr` SHALL be null

### Requirement: Strike price shown only during the promo period
A rule or override SHALL be in effect only while `starts_at` (or now, if null) ≤ current time < `ends_at`. Outside that window it SHALL produce no strike price. No backfill or job SHALL be needed: expiry SHALL be evaluated at request time. The promo period SHALL be at most 90 days long (`ends_at` − max(`starts_at`, time of saving) ≤ 90 days), so a promo cannot run indefinitely.

#### Scenario: Promo ends automatically
- **WHEN** the `PACKAGE` rule's `ends_at` is 2026-10-31 23:59 WIB and a request is made on 2026-11-01
- **THEN** no package SHALL have a strike price, without any admin action

#### Scenario: Scheduled promo not yet started
- **WHEN** a rule's `starts_at` is in the future
- **THEN** no strike price SHALL be produced until `starts_at` is reached

### Requirement: Strike price computation
The backend SHALL compute the strike price from the item's real price and its effective, in-period rule. For `PERCENT` with value `p` (1–90): strike = `ceil(price / (1 − p/100) / 1000) × 1000`. For `FIXED` with value `a` (≥ 1): strike = `price + a`. The strike price SHALL be null when there is no effective in-period rule, when the effective mode is `NONE`, when the price is ≤ 0, or when the computed strike is not greater than the price. `discount_percent` SHALL be `round((strike − price) / strike × 100)` whenever a strike price exists, and null otherwise. The strike price SHALL be display-only: it SHALL NOT change the amount charged, order amounts, or entitlement logic.

#### Scenario: Percent is rounded up to the nearest thousand
- **WHEN** the price is 39000 and the effective rule is `PERCENT 20`
- **THEN** `strike_price_idr` SHALL be 49000 and `discount_percent` SHALL be 20

#### Scenario: Fixed amount is added to the price
- **WHEN** the price is 29000 and the effective rule is `FIXED 10000`
- **THEN** `strike_price_idr` SHALL be 39000 and `discount_percent` SHALL be 26

#### Scenario: Charged amount unaffected
- **WHEN** a user pays for an item that has a strike price
- **THEN** the order SHALL be created with the item's `price_idr`, not its strike price

### Requirement: Public APIs expose strike price
The AR card list and detail responses, the dongeng list and detail responses, and `GET /premium/packs` SHALL include nullable `strike_price_idr`, `discount_percent` and `promo_ends_at` (ISO-8601, the `ends_at` of the rule that produced the strike price) alongside `price_idr`. All three SHALL be null together when there is no strike price. Global rules SHALL be loaded once per request, not once per item.

#### Scenario: Package list includes strike fields
- **WHEN** `GET /premium/packs` is called while the `PACKAGE` rule is an active `PERCENT 25` ending 2026-10-31
- **THEN** each package SHALL include `strike_price_idr` and `discount_percent` computed from its `price_idr`, and `promo_ends_at` of 2026-10-31

#### Scenario: Free content has no strike price
- **WHEN** an AR card has no product mapping, so it has no `price_idr`
- **THEN** its response SHALL NOT include a non-null `strike_price_idr`

### Requirement: Admin API manages strike-price rules and overrides
The backend SHALL expose `GET /admin/strike-price-rules` and `PUT /admin/strike-price-rules/:scope` with body `{mode, value, starts_at, ends_at}`. Both SHALL require an admin JWT. `PUT` SHALL return 404 for an unknown scope and 400 for any of the following:
- a `PERCENT` value outside 1–90
- a `FIXED` value < 1
- a missing `ends_at` for `PERCENT`/`FIXED`
- an `ends_at` that is not after both `starts_at` and the current time
- a period longer than 90 days

`PUT /admin/products/:id` and `PUT /admin/premium/packs/:id` SHALL accept optional `strike_mode` (null meaning inherit), `strike_value`, `strike_starts_at` and `strike_ends_at`, with the same validation. Admin product and package list responses SHALL include the stored override and the effective `strike_price_idr` and `promo_ends_at`.

#### Scenario: Admin sets a global percent rule
- **WHEN** an admin calls `PUT /admin/strike-price-rules/AR_CARD` with `{"mode":"PERCENT","value":20,"ends_at":"2026-10-31T23:59:00+07:00"}`
- **THEN** the rule SHALL be saved, and AR card responses SHALL reflect it until that time

#### Scenario: Out-of-range percent rejected
- **WHEN** an admin calls `PUT /admin/strike-price-rules/PACKAGE` with `{"mode":"PERCENT","value":95,...}`
- **THEN** the server SHALL respond 400 and the rule SHALL be unchanged

#### Scenario: Promo longer than 90 days rejected
- **WHEN** an admin saves a rule whose period is 120 days long
- **THEN** the server SHALL respond 400 and the rule SHALL be unchanged

#### Scenario: Admin resets a product to inherit
- **WHEN** an admin calls `PUT /admin/products/:id` with `strike_mode: null`
- **THEN** the product's override and its period SHALL be cleared, and it SHALL follow its scope's global rule

### Requirement: Backoffice strike-price configuration
The backoffice SHALL have a "Harga Coret" page under Settings with one card per scope (Kartu AR, Dongeng, Paket Premium). Each card SHALL have:
- a mode selector (Tidak ada / Persen / Nominal)
- a value input
- a promo period picker (start optional, end required, times in WIB)
- an example preview
- a status tag: Aktif, Terjadwal, Berakhir or Nonaktif

The Product edit modal and the Package create/edit modal SHALL include:
- a "Harga coret" selector (Ikuti global / Tidak ada / Persen / Nominal)
- a value input and period picker, shown only for Persen/Nominal
- a live preview of the resulting strike price

The Products and Packages tables SHALL show the effective strike price and its end date.

#### Scenario: Admin configures a global rule with preview
- **WHEN** the admin selects Persen, types 20 and picks an end date on the Dongeng card
- **THEN** the preview SHALL show an example price and its strike price, and saving SHALL call `PUT /admin/strike-price-rules/DONGENG`

#### Scenario: End date required
- **WHEN** the admin selects Nominal but leaves the end date empty
- **THEN** the form SHALL show a validation error and SHALL NOT call the API

#### Scenario: Expired rule is visible as ended
- **WHEN** a rule's `ends_at` has passed
- **THEN** its card SHALL show the "Berakhir" status tag

#### Scenario: Admin overrides a single package
- **WHEN** the admin edits a package, chooses Nominal with 10000 and an end date, then saves
- **THEN** `PUT /admin/premium/packs/:id` SHALL be sent with `strike_mode: "FIXED"`, `strike_value: 10000` and the period, and the Packages table SHALL show the new strike price


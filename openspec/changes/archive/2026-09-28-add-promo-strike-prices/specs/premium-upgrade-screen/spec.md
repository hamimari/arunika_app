## ADDED Requirements

### Requirement: Package cards show strike price and discount badge
Each package card on the premium upgrade screen SHALL show the package price. When `strike_price_idr` is non-null, it SHALL also show the strike price crossed out, a discount badge (e.g. "-20%") based on `discount_percent`, and the promo end date ("Promo s/d …") from `promo_ends_at`.

#### Scenario: Package with strike price
- **WHEN** a package has `price_idr = 79000`, `strike_price_idr = 99000`, `discount_percent = 20`, `promo_ends_at` 2026-10-31
- **THEN** its card SHALL show "Rp 79.000", a crossed-out "Rp 99.000", a "-20%" badge and "Promo s/d 31 Okt"

#### Scenario: Active subscriber sees no strike price
- **WHEN** a user with an active subscription outside the renewal window opens the premium upgrade screen
- **THEN** no package card, price or strike price SHALL be shown (see "Active subscribers see no packages outside the renewal window")

#### Scenario: Package without strike price
- **WHEN** a package has `strike_price_idr = null`
- **THEN** its card SHALL show only the price, with no crossed-out price or badge

### Requirement: Active subscribers see no packages outside the renewal window
When the logged-in user has an active subscription and the profile's `subscription.can_renew` is false, the premium upgrade screen SHALL show a "Langganan aktif" state instead of package tabs, prices or purchase buttons. It SHALL show the plan name and "Berlaku sampai {date}", or "Diperpanjang otomatis pada {date}" when `auto_renew` is true. The profile membership card SHALL NOT show a "Perpanjang" button in that state.

#### Scenario: Subscriber outside the window opens the premium screen
- **WHEN** a subscriber whose Midtrans subscription ends on 31 Des 2026 opens `/premium` on 1 Des 2026
- **THEN** the screen SHALL show "Langganan aktif" and "Berlaku sampai 31 Des 2026", with no packages or prices, and the profile card SHALL NOT show "Perpanjang"

#### Scenario: Auto-renewing Play subscriber
- **WHEN** a subscriber with a Google Play subscription and `auto_renew = true` opens `/premium` at any time
- **THEN** the screen SHALL show "Diperpanjang otomatis pada {expiry date}" and no packages or "Perpanjang" button

#### Scenario: Subscription has expired
- **WHEN** the user's subscription `expires_at` has passed
- **THEN** the premium screen SHALL show the package tabs and prices as normal

### Requirement: Renewal in the last 7 days
When `subscription.can_renew` is true, the profile membership card SHALL show a "Perpanjang" button.
- For a non-Play subscription (`provider != 'google_play'`), the button SHALL open `/premium` in subscription-only mode. That mode SHALL show only subscription packages, with a banner stating the new period is added from the current expiry date ("Masa aktif baru ditambahkan mulai {expiry}"), and SHALL NOT show content packages.
- For a Google Play subscription with auto-renew cancelled, the button SHALL open the Google Play subscription management page for that subscription, and SHALL NOT start an in-app purchase.

#### Scenario: Midtrans subscriber in the window
- **WHEN** a Midtrans subscriber's subscription ends on 31 Okt 2026 and they open the profile on 26 Okt 2026
- **THEN** the card SHALL show "Perpanjang", and tapping it SHALL open subscription packages with the banner "Masa aktif baru ditambahkan mulai 31 Okt 2026"

#### Scenario: Cancelled Play subscriber in the window
- **WHEN** a Google Play subscriber with `auto_renew = false` is within 7 days of expiry and taps "Perpanjang"
- **THEN** the Google Play subscription page for that subscription SHALL open, and no in-app purchase SHALL be started

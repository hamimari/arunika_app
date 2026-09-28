# payment-screen Specification

## Purpose
Defines the required behaviour for payment screen in the Arunika system.
## Requirements
### Requirement: Pay now button
The payment screen SHALL have a "Bayar Sekarang 🔒" button at the bottom that initiates payment by calling `POST /payment/create` and opening the Midtrans Snap webview. The webview's own `onSuccess`/`onPending` callbacks SHALL NOT directly navigate to the unlock success screen; they SHALL instead trigger backend-confirmation polling.

#### Scenario: Bayar Sekarang is tappable
- **WHEN** the user selects a payment method and taps "Bayar Sekarang"
- **THEN** `POST /payment/create` is called and, on success, the Midtrans Snap webview opens with the returned token

### Requirement: Payment outcome is confirmed by the backend, not the client
After the Midtrans webview reports `onSuccess` or `onPending`, the payment screen SHALL show a waiting state and poll `GET /orders/:id` (using the `order_id` returned by `POST /payment/create`) at a fixed interval until the order status is `PAID`, `FAILED`, or `EXPIRED`, or a timeout elapses. The screen SHALL navigate to `/unlock-success` only when the polled status is `PAID`.

#### Scenario: Webview success triggers polling, not immediate navigation
- **WHEN** the Midtrans webview reports `onSuccess`
- **THEN** the screen SHALL show a waiting/confirming state and begin polling `GET /orders/:id` rather than navigating immediately

#### Scenario: Backend-confirmed PAID order navigates to unlock success
- **WHEN** a poll of `GET /orders/:id` returns `status = 'PAID'`
- **THEN** the app SHALL navigate to `/unlock-success`

#### Scenario: Backend-confirmed failure shows retry
- **WHEN** a poll of `GET /orders/:id` returns `status = 'FAILED'` or `'EXPIRED'`
- **THEN** the screen SHALL show a failure message with a retry affordance instead of navigating to unlock success

#### Scenario: Polling timeout shows retry
- **WHEN** the order remains `PENDING` after the polling timeout elapses
- **THEN** the screen SHALL show a message indicating confirmation is taking longer than expected, with a retry/refresh affordance

### Requirement: Payment screen price summary
The payment screen SHALL show a bottom summary for the currently selected option with:
- its name
- when a strike price exists: the crossed-out strike price, the "Hemat" amount (strike minus price) and the promo end date ("Promo s/d …")
- the "Total", equal to the option's real price (e.g. "Rp 39.000")

The strike price SHALL NOT be labelled "Harga normal". The screen SHALL NOT show any text about the payment processor, including the previous "Pembayaran diproses melalui Midtrans…" and Google Play/Midtrans info note.

#### Scenario: Total price displayed
- **WHEN** the payment screen loads
- **THEN** the selected option's name and total price (e.g., "Rp 39.000") are shown at the bottom

#### Scenario: Savings and promo end shown when strike price exists
- **WHEN** the selected option has price 39000, strike price 49000 and `promo_ends_at` 2026-10-31
- **THEN** the summary SHALL show a crossed-out "Rp 49.000", "Hemat Rp 10.000 · Promo s/d 31 Okt", and "Total Rp 39.000", and SHALL NOT show the words "Harga normal"

#### Scenario: Processor note removed
- **WHEN** the payment screen is shown on any platform
- **THEN** no text mentioning Midtrans SHALL be displayed

### Requirement: Inline premium package options on the payment screen
The payment screen SHALL show a "Pilih paket" list of selectable options on the page itself, with no navigation to another screen. When the screen was opened for a single product, the first option SHALL be that product ("Beli {judul} saja"). It SHALL be followed by all active premium packages from `GET /premium/packs` in `sort_order`. Each option SHALL show its name, subtitle, badge/best-value highlight, price and strike price. The entry item SHALL be preselected. The previous "Ingin lebih hemat?" link to `/premium` SHALL be removed.

#### Scenario: Buying a single AR card shows upgrade options
- **WHEN** the user opens the payment screen for a single AR card
- **THEN** the card option SHALL be listed first and preselected, followed by every active content and subscription package

#### Scenario: Opened from the premium upgrade screen
- **WHEN** the user opens the payment screen for a package chosen on `/premium`
- **THEN** the package list SHALL be shown with that package preselected and no single-product option

#### Scenario: Packages fail to load
- **WHEN** `GET /premium/packs` fails
- **THEN** the entry item option SHALL remain selectable and payable, and a "Coba lagi" retry row SHALL replace the package list

### Requirement: Selecting an option updates price and payment target
Tapping an option SHALL immediately mark it selected and update the summary's name, strike price, savings and total without a network call. "Bayar Sekarang" SHALL pay for the selected option. A package SHALL use the package purchase path (Play Billing when eligible, otherwise `POST /payment/create`), and the single product SHALL use the product path (Play Billing when eligible, otherwise `POST /payment/create-product`). The selected item SHALL be passed to `/unlock-success`. Option selection SHALL be disabled while a payment is being started.

#### Scenario: Upgrading to a package changes the total
- **WHEN** the user opened the payment screen for a Rp 15.000 AR card and taps a Rp 79.000 package
- **THEN** that package SHALL be highlighted and the summary total SHALL change to "Rp 79.000"

#### Scenario: Paying for the selected package
- **WHEN** the user has selected a package and taps "Bayar Sekarang"
- **THEN** the purchase SHALL be started for that package, not the originally opened product

#### Scenario: Selection locked during payment start
- **WHEN** "Bayar Sekarang" is loading
- **THEN** tapping another option SHALL NOT change the selection

### Requirement: Active subscribers pay only to renew
When the logged-in user has an active subscription and `subscription.can_renew` is false, the payment screen SHALL show the "Langganan aktif" state instead of options, the price summary and "Bayar Sekarang". When `can_renew` is true, the option list SHALL contain only subscription packages, with the current plan preselected if it is still active. The summary SHALL show the current and new end dates ("Aktif sampai {expires_at} → {expires_at + duration_days}"), recomputed when the user selects another plan. If the backend rejects payment creation with 409 `SUBSCRIPTION_ACTIVE`, the screen SHALL switch to the "Langganan aktif" state rather than show a generic error.

#### Scenario: Subscriber outside the window reaches the payment screen
- **WHEN** a user with an active subscription and `can_renew = false` opens the payment screen
- **THEN** no packages, prices or "Bayar Sekarang" button SHALL be shown

#### Scenario: Renewing shows the stacked end date
- **WHEN** a subscriber whose subscription ends on 31 Okt 2026 is in the renewal window and the 30-day "Bulanan" plan is selected
- **THEN** only subscription packages SHALL be listed, and the summary SHALL show "Aktif sampai 31 Okt 2026 → 30 Nov 2026"

#### Scenario: Switching plan updates the new end date
- **WHEN** the same subscriber selects the 365-day "Tahunan" plan
- **THEN** the summary total SHALL change to the Tahunan price, and the new end date SHALL become 31 Okt 2027

#### Scenario: Backend reports an active subscription
- **WHEN** `POST /payment/create` returns 409 `SUBSCRIPTION_ACTIVE`
- **THEN** the screen SHALL show the "Langganan aktif" state and no charge SHALL be started


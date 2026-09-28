## MODIFIED Requirements

### Requirement: Pay now button
The payment screen SHALL have a "Bayar Sekarang 🔒" button at the bottom that starts payment for the selected option. The Midtrans path (calling `POST /payment/create` or `/payment/create-product` and opening the Midtrans Snap webview) SHALL be used only while the `alternative_billing` flag is on. On that path, the webview's own `onSuccess`/`onPending` callbacks SHALL NOT directly navigate to the unlock success screen; they SHALL instead trigger backend-confirmation polling.

#### Scenario: Bayar Sekarang is tappable
- **WHEN** the `alternative_billing` flag is on, the user selects an option that uses the Midtrans path, and taps "Bayar Sekarang"
- **THEN** the create-payment endpoint is called and, on success, the Midtrans Snap webview opens with the returned token

## ADDED Requirements

### Requirement: Only Google Play purchases while alternative billing is off
While the `alternative_billing` flag is off, the payment screen SHALL offer only Google Play purchases:
- the payment screen SHALL NOT call `POST /payment/create` or `/payment/create-product`, and SHALL NOT open the Midtrans webview
- on Android, packages without a `play_product_id` SHALL NOT be listed as options
- a single product without a `play_product_id` SHALL be shown with "Belum tersedia di perangkat ini" and no "Bayar Sekarang" button
- on iOS and web, the screen SHALL show a purchase-unavailable state instead of options

A 403 `ALTERNATIVE_BILLING_DISABLED` from the backend SHALL be shown as that unavailable state.

#### Scenario: Unmapped package hidden on Android
- **WHEN** the flag is off and the package list contains one package with a `play_product_id` and one without
- **THEN** only the mapped package SHALL be listed

#### Scenario: Unmapped single product not sold
- **WHEN** the flag is off and the screen is opened for an AR card without a `play_product_id`
- **THEN** that option SHALL show "Belum tersedia di perangkat ini", no "Bayar Sekarang" button SHALL be shown for it, and no Midtrans request SHALL be made

#### Scenario: iOS has no purchase path
- **WHEN** the flag is off and the payment screen opens on iOS
- **THEN** a purchase-unavailable state SHALL be shown, and no Midtrans webview SHALL open

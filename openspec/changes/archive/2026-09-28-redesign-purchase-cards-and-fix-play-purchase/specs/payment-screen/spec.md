## ADDED Requirements

### Requirement: A failed purchase says why
When starting a purchase fails, the payment screen SHALL show a message for the specific cause instead of one generic error, and SHALL log the cause. The button SHALL remain so the user can retry, and a cancellation SHALL NOT show an error.
- Google Play Billing unavailable on the device: "Google Play tidak tersedia di perangkat ini…".
- Google Play doesn't know the item's product: "Item ini belum tersedia di Google Play…".
- The backend didn't create the order: "Pesanan gagal dibuat…".
- Google Play took the payment but the backend couldn't confirm it: a message telling the user not to pay again and that access will activate automatically. The purchase SHALL be left unacknowledged so that it is retried on the next app start.
- Anything else: "Pembayaran gagal. Coba lagi.".

#### Scenario: Play Store unavailable
- **WHEN** the user taps "Bayar Sekarang" and Google Play Billing is unavailable
- **THEN** the screen SHALL show that Google Play isn't available on this device, and "Bayar Sekarang" SHALL remain

#### Scenario: Product not found in Google Play
- **WHEN** Google Play doesn't recognise the item's product
- **THEN** the screen SHALL show that the item isn't available in Google Play yet

#### Scenario: Paid but not confirmed
- **WHEN** Google Play completes the payment but the backend verification fails
- **THEN** the screen SHALL tell the user not to pay again and that access will activate automatically

#### Scenario: Cancelled
- **WHEN** the user cancels in Google Play
- **THEN** no error message SHALL be shown

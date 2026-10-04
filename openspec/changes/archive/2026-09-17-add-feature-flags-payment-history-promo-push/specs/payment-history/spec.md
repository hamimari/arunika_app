## ADDED Requirements

### Requirement: User payment history endpoint
The backend SHALL expose authenticated `GET /orders?page=&per_page=` returning only the caller's orders in every status, newest first, with `total`. Each row SHALL include `id`, `item_type` (`AR_CARD` | `DONGENG` | `PACKAGE`), `item_name`, `package_type` for packages, `amount_idr`, `status`, `payment_type`, a human-readable `payment_method`, `created_at` and `updated_at`. Names and methods SHALL be resolved with batch queries, not per order. Still-PENDING orders younger than 48 hours SHALL be reconciled with Midtrans, at most 5 per request.

#### Scenario: Mixed history
- **WHEN** a user with a paid AR card order, a failed dongeng order and a pending package order calls `GET /orders`
- **THEN** all three are returned with their item names, statuses and payment methods

#### Scenario: Bank resolved from webhook payload
- **WHEN** an order's payments include a webhook payload with `va_numbers[0].bank = "bni"` and a newer status-sync row without bank detail
- **THEN** `payment_method` is `BNI Virtual Account`

#### Scenario: Unauthenticated
- **WHEN** `GET /orders` is called without a valid token
- **THEN** the server responds 401

### Requirement: Payment history screen
The app SHALL provide a "Riwayat Pembayaran" screen reachable from the Profile tab that lists orders of every status with product name and type (Kartu AR, Dongeng, Paket Konten/Langganan), price in Rupiah, status, payment method ("-" when not chosen yet), order time, payment/update time for non-pending orders, and the full order id. Tapping the order id or its copy button SHALL copy it to the clipboard and confirm with a snackbar. The list SHALL paginate on scroll and support pull-to-refresh, and SHALL show empty and retryable error states.

#### Scenario: Copy order id
- **WHEN** the user taps the copy icon on an order
- **THEN** the order id is placed on the clipboard and "ID pesanan disalin" is shown

#### Scenario: No purchases yet
- **WHEN** the user has no orders
- **THEN** the screen shows "Belum ada pembayaran"

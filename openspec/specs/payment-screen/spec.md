# payment-screen Specification

## Purpose
Defines the required behaviour for payment screen in the Arunika system.
## Requirements
### Requirement: Payment screen with local methods
The payment screen SHALL display the selected pack name and price, and a list of local Indonesian payment methods: OVO, GoPay, DANA, ShopeePay, Transfer Bank, Kartu Kredit/Debit.

#### Scenario: Payment methods are shown
- **WHEN** the user arrives at the payment screen
- **THEN** all supported local payment methods are listed with their logos

#### Scenario: Total price displayed
- **WHEN** the payment screen loads
- **THEN** the pack name and total price (e.g., "Rp 39.000") are shown at the bottom

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


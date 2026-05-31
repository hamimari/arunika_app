## ADDED Requirements

### Requirement: Payment screen with local methods
The payment screen SHALL display the selected pack name and price, and a list of local Indonesian payment methods: OVO, GoPay, DANA, ShopeePay, Transfer Bank, Kartu Kredit/Debit.

#### Scenario: Payment methods are shown
- **WHEN** the user arrives at the payment screen
- **THEN** all supported local payment methods are listed with their logos

#### Scenario: Total price displayed
- **WHEN** the payment screen loads
- **THEN** the pack name and total price (e.g., "Rp 39.000") are shown at the bottom

### Requirement: Pay now button
The payment screen SHALL have a "Bayar Sekarang 🔒" button at the bottom that initiates payment.

#### Scenario: Bayar Sekarang is tappable
- **WHEN** the user selects a payment method and taps "Bayar Sekarang"
- **THEN** the payment flow is initiated (UI-only: navigates to unlock success screen in this phase)

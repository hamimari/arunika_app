# unlock-success-screen Specification

## Purpose
Defines the required behaviour for unlock success screen in the Arunika system.
## Requirements
### Requirement: Unlock success celebration screen
The app SHALL only navigate to the unlock success screen after the backend has confirmed the corresponding order's status is `PAID` (see `payment-screen`). The screen SHALL display a celebration screen with "Yeay! 🎉" heading, the pack name unlocked, a checklist of what was unlocked (e.g., "15+ Hewan Baru", "4 Dongeng Eksklusif", "Kartu Printable", "Bisa digunakan offline"), and a "Mulai Jelajah" button.

#### Scenario: Unlock success screen shown after backend-confirmed payment
- **WHEN** the payment screen's polling confirms the order status is `PAID`
- **THEN** the unlock success screen is displayed with a celebratory animation

#### Scenario: Screen is not reachable without a confirmed order
- **WHEN** the app has not received a `PAID` order status from the backend
- **THEN** the app SHALL NOT navigate to the unlock success screen

#### Scenario: Unlocked content checklist is shown
- **WHEN** the unlock success screen is visible
- **THEN** a checklist of newly unlocked content items is displayed

#### Scenario: Mulai Jelajah navigates to collection
- **WHEN** the user taps "Mulai Jelajah"
- **THEN** the app navigates to the Koleksi screen showing newly unlocked animals


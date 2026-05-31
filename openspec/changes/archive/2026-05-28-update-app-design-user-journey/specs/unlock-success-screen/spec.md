## ADDED Requirements

### Requirement: Unlock success celebration screen
After a successful purchase, the app SHALL display a celebration screen with "Yeay! 🎉" heading, the pack name unlocked, a checklist of what was unlocked (e.g., "15+ Hewan Baru", "4 Dongeng Eksklusif", "Kartu Printable", "Bisa digunakan offline"), and a "Mulai Jelajah" button.

#### Scenario: Unlock success screen shown after payment
- **WHEN** the payment flow completes successfully
- **THEN** the unlock success screen is displayed with a celebratory animation

#### Scenario: Unlocked content checklist is shown
- **WHEN** the unlock success screen is visible
- **THEN** a checklist of newly unlocked content items is displayed

#### Scenario: Mulai Jelajah navigates to collection
- **WHEN** the user taps "Mulai Jelajah"
- **THEN** the app navigates to the Koleksi screen showing newly unlocked animals

## ADDED Requirements

### Requirement: Belajar hub screen
The Belajar tab SHALL open on a hub titled "Belajar", with the subtitle "Pilih petualangan belajar hari ini!". It SHALL list a "Kartu AR" card ("Lihat hewan jadi nyata lewat kamera", link "Buka", frog artwork, peach background) and a "Dongeng" card ("Cerita seru penuh pesan baik", link "Buka", story artwork, lavender background), styled as in the Belajar design. Tapping a card SHALL open its screen. Cards for Stimulasi Bayi, Angka and Huruf SHALL NOT be shown until those features exist.

#### Scenario: Open Kartu AR from the hub
- **WHEN** the user taps the Kartu AR card
- **THEN** the existing AR collection screen opens inside the Belajar tab, and the bottom navigation stays visible with Belajar highlighted

### Requirement: Kartu AR and Dongeng live inside the Belajar tab
The Belajar tab SHALL host its own navigation stack: the hub, Kartu AR (the existing collection screen, accepting an optional category id) and Dongeng (the existing Dongeng list screen, accepting an optional product id to highlight). Kartu AR and Dongeng SHALL show a back button that returns to the hub. The system back gesture SHALL pop this stack before leaving the tab. Tapping the Belajar tab while it is active SHALL return to the hub. Screens pushed from them, such as the AR viewer, the Dongeng player and payment, SHALL keep using the app's root routes.

#### Scenario: Back from Dongeng
- **WHEN** the user is on Dongeng inside Belajar and presses the system back button
- **THEN** the Belajar hub is shown and the app stays open

#### Scenario: Tab state kept
- **WHEN** the user opens Kartu AR in Belajar, switches to Beranda and comes back to Belajar
- **THEN** Kartu AR is still shown at the same scroll position

### Requirement: Cross-screen shortcuts open Belajar destinations
Every entry point that used to switch to the Koleksi or Dongeng tab SHALL open the matching Belajar destination instead. This covers the Beranda shortcuts and category tiles, the "Lihat Semua" links, the unlock-success actions and push-notification taps. Entry points that used to switch to the Scan tab SHALL push the AR scan route.

#### Scenario: Dongeng unlocked
- **WHEN** a purchase of a dongeng completes and the user taps the unlock-success action
- **THEN** the Belajar tab opens on Dongeng, with the purchased story highlighted

#### Scenario: Push notification for an AR card promo
- **WHEN** the user taps a push notification that links to AR cards
- **THEN** the Belajar tab opens on Kartu AR

### Requirement: QR scan entry in the Kartu AR header
While `qr_scan` is enabled, the Kartu AR screen header SHALL show a scan icon next to the search icon, and it SHALL open the AR scan route. While `qr_scan` is disabled, the icon SHALL be hidden.

#### Scenario: Scan from Kartu AR
- **WHEN** `qr_scan` is enabled and the user taps the scan icon on Kartu AR
- **THEN** the QR scanner opens

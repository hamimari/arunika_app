## ADDED Requirements

### Requirement: 5-tab bottom navigation bar
The app SHALL display a persistent bottom navigation bar with 5 tabs: Beranda, Scan, Koleksi, Dongeng, Orang Tua — each with an icon and label.

#### Scenario: Bottom nav is visible on main screens
- **WHEN** the user is on any of the 5 main tab screens
- **THEN** the bottom navigation bar is visible at the bottom of the screen

#### Scenario: Active tab is highlighted
- **WHEN** the user is on the Koleksi tab
- **THEN** the Koleksi tab icon and label are visually highlighted (e.g., filled icon, accent color)

### Requirement: Tab state is preserved with IndexedStack
The main shell SHALL use `IndexedStack` to preserve the scroll and state of each tab when switching between tabs.

#### Scenario: Scroll position preserved on tab switch
- **WHEN** the user scrolls down in the Koleksi tab then switches to Beranda and back
- **THEN** the Koleksi tab is at the same scroll position as before

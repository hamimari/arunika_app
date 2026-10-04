## MODIFIED Requirements

### Requirement: 5-tab bottom navigation bar
The app SHALL display a persistent bottom navigation bar with up to 4 tabs, in this order, each with an icon and label:
- Beranda (sun icon);
- Belajar (graduation-cap icon);
- Tumbuh (sprout icon), shown only when the user is logged in and `growth_tracking` is enabled;
- Profil (profile-circle icon), shown only when the user is logged in.

The active tab SHALL show a peach pill behind its icon and a bold orange label, as in the redesign. Hidden tabs SHALL be removed with the remaining tabs evenly spaced. The former Scan, Koleksi, Dongeng and Orang Tua tabs SHALL no longer exist. Koleksi and Dongeng are reached through Belajar, and scan through the Kartu AR header.

#### Scenario: Bottom nav is visible on main screens
- **WHEN** the user is on any main tab screen, or on Kartu AR or Dongeng inside Belajar
- **THEN** the bottom navigation bar is visible at the bottom of the screen

#### Scenario: Active tab is highlighted
- **WHEN** the user is on the Tumbuh tab
- **THEN** the Tumbuh icon and label are highlighted with the peach pill and orange bold label

#### Scenario: Guest user
- **WHEN** the user is not logged in
- **THEN** only Beranda and Belajar are shown

#### Scenario: Logout while on Tumbuh
- **WHEN** the user logs out while the Tumbuh tab is open
- **THEN** the app returns to Beranda and Tumbuh and Profil disappear

### Requirement: Tab state is preserved with IndexedStack
The main shell SHALL use `IndexedStack` to preserve the scroll and state of each tab, including the Belajar tab's inner navigation stack, when switching between tabs.

#### Scenario: Scroll position preserved on tab switch
- **WHEN** the user scrolls down in the Tumbuh tab then switches to Beranda and back
- **THEN** the Tumbuh tab is at the same scroll position as before

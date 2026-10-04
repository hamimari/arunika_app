## ADDED Requirements

### Requirement: Beranda growth card
When the user is logged in and `growth_tracking` is enabled, Beranda SHALL show a growth card below the Kartu AR categories section (where the redesign's "Mau belajar apa hari ini?" grid will go).
- **With measurements:** the title is "Tumbuh kembang {nama}", with a sprout icon and a chevron. The subtitle is "Diukur {tanggal} · {y} th {m} bln". Two inner tiles show "Tinggi" and "Berat", each with the latest value ("94,8 cm") and its status chip. Tapping the card SHALL open the Tumbuh tab.
- **Without measurements:** a dashed-border card shows the title "Pantau tumbuh kembang {nama}", the text "Catat tinggi dan berat pertama untuk melihat grafik sesuai standar WHO." and an outlined button "+ Catat pengukuran pertama". The button SHALL open the add-measurement form.
- **Incomplete child profile:** the empty-state card SHALL be shown, and its button SHALL open the Tumbuh tab, which explains what is missing.

The card SHALL be hidden for guests, while `growth_tracking` is disabled, and while its data is loading for the first time. It SHALL refresh with Beranda's pull-to-refresh and after any growth change.

#### Scenario: Card with data
- **WHEN** hamiz was last measured on 12 Sep 2026 at 94,8 cm and 13,9 kg, both normal
- **THEN** the card reads "Tumbuh kembang hamiz", "Diukur 12 Sep 2026 · 3 th 2 bln", with "Tinggi 94,8 cm Normal" and "Berat 13,9 kg Normal"

#### Scenario: New user
- **WHEN** a logged-in parent has no measurements yet
- **THEN** the card reads "Pantau tumbuh kembang hamiz", and tapping "Catat pengukuran pertama" opens "Tambah Pengukuran"

#### Scenario: Feature off
- **WHEN** `growth_tracking` is disabled
- **THEN** Beranda shows no growth card and no leftover gap

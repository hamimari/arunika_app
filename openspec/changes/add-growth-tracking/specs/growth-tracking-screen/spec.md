## ADDED Requirements

### Requirement: Tumbuh Kembang screen layout
The Tumbuh tab SHALL show, top to bottom, for the account's first child:
1. The title "Tumbuh Kembang" and the subtitle "Pantau tinggi dan berat si kecil".
2. A child header with avatar, name, and "{Laki-laki|Perempuan} · {y} tahun {m} bulan". There is no child selector in this phase.
3. Two summary tiles, "Tinggi badan" and "Berat badan". Each shows the latest value with a comma decimal and its unit ("94,8 cm"), a status chip, and "+2,2 cm dari pengukuran lalu" (or the kg form). The change line is hidden when there is no earlier value.
4. A primary "Tambah Pengukuran" button.
5. The growth chart card.
6. "Riwayat Pengukuran" with the count "{n} data".

The screen SHALL match the "Tumbuh Kembang — grafik & riwayat" design. It SHALL be scrollable and SHALL support pull-to-refresh.

#### Scenario: Child with five measurements
- **WHEN** a parent whose son hamiz has five measurements opens Tumbuh
- **THEN** the tiles show 94,8 cm and 13,9 kg with "Normal" chips and the change lines, and the history header reads "5 data"

#### Scenario: Only one measurement
- **WHEN** the child has exactly one measurement
- **THEN** both tiles hide the "dari pengukuran lalu" line and the chart shows a single point

### Requirement: Status chips and copy never show z-scores
Every parent-facing growth surface SHALL show a category as a text chip and SHALL NEVER render a z-score number. The chip labels and colours SHALL be:
- Normal (green) for both indicators;
- Pendek (amber), Sangat pendek (red) and Tinggi (blue) for height;
- Berat badan kurang (amber), Berat badan sangat kurang (red) and Risiko berat badan lebih (amber) for weight.

The status sentence under the chart SHALL read:
- normal: "{Tinggi|Berat} {nama} normal untuk usianya.";
- `stunted`, `underweight` or `risk_overweight`: "{Kategori}. Coba konsultasikan ke posyandu atau dokter anak saat kunjungan berikutnya.";
- `severely_stunted` or `severely_underweight`: "{Kategori}. Sebaiknya segera periksakan ke dokter anak atau puskesmas."

#### Scenario: Stunted height
- **WHEN** the latest height category is `stunted`
- **THEN** the height tile chip reads "Pendek" in amber, and the status box reads "Pendek. Coba konsultasikan ke posyandu atau dokter anak saat kunjungan berikutnya."

#### Scenario: No z-score rendered
- **WHEN** any growth screen, sheet or card is rendered in a widget test
- **THEN** no text matches a signed decimal z-score pattern such as "-0.68" or "−2,00 SD"

### Requirement: WHO growth chart
The chart card SHALL contain:
- a two-segment switch, "Tinggi badan" (TB/U) and "Berat badan" (BB/U);
- the title "{Tinggi|Berat} badan menurut umur" and the subtitle "Standar WHO · {laki-laki|perempuan} · {range}";
- zone fills from the child's-sex LMS curves: TB/U Sangat pendek < −3 SD, Pendek −3 to −2, Normal −2 to +3, Tinggi > +3; BB/U with cut-offs −3, −2 and +1;
- the median drawn as a dashed line;
- the child's measurements as points joined by a line at the adjusted value, with the latest point larger and labelled;
- a legend;
- the status box;
- the disclaimer "Acuan: WHO Child Growth Standards & Permenkes No. 2 Tahun 2020. Grafik ini bukan diagnosis; tanyakan dokter atau posyandu bila ada kekhawatiran."

The x-axis SHALL span from the first measurement minus 3 months to the latest plus 3 months, clamped to 0–60 months. The chart SHALL be drawn on the device from the bundled LMS file. It SHALL expose the status sentence as its accessibility label.

#### Scenario: Switch to weight
- **WHEN** the parent taps "Berat badan"
- **THEN** the chart redraws with the BB/U zones, median and weight points, and the status box describes the weight category

#### Scenario: Child older than 60 months
- **WHEN** the child is older than 60 months
- **THEN** the chart shows data only up to 60 months, and a note says the WHO 0–5 year standard no longer applies

### Requirement: Measurement history list
"Riwayat Pengukuran" SHALL list every measurement newest first. Each row SHALL show the date ("12 Sep 2026"), the age ("3 th 2 bln"), the height and weight (or "–" when missing), an edit button and a delete button. Each button SHALL be a touch target of at least 44 px.

#### Scenario: Edit from history
- **WHEN** the parent taps the pencil on the 12 Sep 2026 row
- **THEN** the "Edit Pengukuran" form opens pre-filled with that row

### Requirement: Add and edit measurement form
"Tambah Pengukuran" and "Edit Pengukuran" SHALL share one form. The header SHALL read "{nama} · {Laki-laki|Perempuan}". The form SHALL have:
- "Tanggal pengukuran", defaulting to today, with future dates and dates before birth disabled or shown as an inline error;
- "Umur saat diukur: {y} tahun {m} bulan (otomatis dari tanggal lahir)", read-only;
- "Tinggi badan" (cm) and "Berat badan" (kg), on a numeric keypad, with one decimal, accepting a comma or a dot;
- "Posisi saat diukur", Berdiri or Berbaring, defaulting to Berbaring under 24 months and Berdiri from 24 months, with the helper text "Anak di bawah 2 tahun diukur berbaring (panjang badan).";
- a "Hasil menurut standar WHO" card that shows the "Tinggi badan / umur" and "Berat badan / umur" chips. It SHALL be recomputed locally 250 ms after the last keystroke.

Saving SHALL be disabled while both values are empty or the date is invalid. The add form's primary button SHALL be "Simpan". The edit form's SHALL be "Simpan Perubahan", with a "Hapus data ini" link below it. After a successful save, the form SHALL close and the Tumbuh screen and Beranda card SHALL reload.

#### Scenario: Live preview
- **WHEN** a parent types "94,8" into Tinggi badan for a 3-year-old boy
- **THEN** within 250 ms of the last keystroke, the preview shows "Tinggi badan / umur · Normal", without a network call

#### Scenario: Position default for a baby
- **WHEN** the measurement date makes the child 14 months old
- **THEN** Berbaring is preselected

#### Scenario: Both values empty
- **WHEN** both value fields are empty
- **THEN** the save button is disabled

#### Scenario: Unusual value
- **WHEN** the entered height is implausible for the child's age
- **THEN** the form shows "Angka ini tidak biasa. Periksa lagi, ya." and a "Tetap simpan" action, and saving only proceeds through "Tetap simpan", which is sent with `confirm_outlier: true`

### Requirement: Delete with confirmation and undo
Deleting from a history row or from the edit form SHALL open a bottom sheet with:
- a trash icon;
- the title "Hapus data pengukuran?";
- the body "Data ini akan dihapus dan grafik {nama} diperbarui.";
- a summary row with date, age and "94,8 cm · 13,9 kg";
- a red "Ya, hapus" button and a "Batal" button.

"Batal" SHALL close the sheet with no change. "Ya, hapus" SHALL remove the row from the list and chart at once, call the delete endpoint, and show a toast with "Urungkan" for 5 seconds. Tapping "Urungkan" SHALL call restore and put the row back.

#### Scenario: Delete then undo
- **WHEN** the parent confirms deleting the 12 Sep 2026 row and taps "Urungkan" within 5 seconds
- **THEN** the row and its chart point reappear, and the summary tiles return to their previous values

#### Scenario: Cancel
- **WHEN** the parent taps "Batal"
- **THEN** the sheet closes and nothing is deleted

### Requirement: Incomplete profile and empty states
When the child's birth date or sex is missing or unrecognized (`profile_complete: false`), Tumbuh SHALL show "Lengkapi profil anak" and a button that opens the Profil tab's edit sheet, and SHALL show no chart. When the profile is complete but there are no measurements, Tumbuh SHALL show the header, a prompt to add the first measurement, and the "Tambah Pengukuran" button.

#### Scenario: Missing gender
- **WHEN** the child's gender is empty
- **THEN** Tumbuh shows "Lengkapi profil anak", and the button opens the profile edit sheet

#### Scenario: After completing the profile
- **WHEN** the parent saves a valid gender and birth date in Profil and returns to Tumbuh
- **THEN** the Tumbuh screen reloads and shows the normal layout

### Requirement: Saving requires connectivity in this phase
In this phase, creates, edits, deletes and restores SHALL be sent straight to the backend. On a network failure, the app SHALL keep the form open with its values, and show "Gagal menyimpan. Periksa koneksi, lalu coba lagi." Every create SHALL send a new `client_id` UUID, and SHALL reuse it when the parent retries the same save.

#### Scenario: Offline save attempt
- **WHEN** the device is offline and the parent taps "Simpan"
- **THEN** the form stays open with the entered values and the error message, and nothing is added to the history

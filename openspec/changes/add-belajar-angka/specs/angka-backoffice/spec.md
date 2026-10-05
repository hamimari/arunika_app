## ADDED Requirements

### Requirement: Angka menu and page
The "Konten Belajar" menu group SHALL list Fairy Tales, AR Cards, Angka and Huruf, in that order. "Angka" SHALL open `/angka`, "Belajar Angka", with the subtitle "Atur level Hitung Benda, pustaka benda, dan kartu Kenal Angka yang tampil di aplikasi." It SHALL have three tabs with counts: "Level Hitung Benda", "Pustaka benda" and "Kenal Angka". The tab SHALL be kept in the URL, and `/angka/*` SHALL highlight the Angka menu entry.

#### Scenario: Open Angka
- **WHEN** an admin clicks Konten Belajar › Angka
- **THEN** the page opens on the "Level Hitung Benda" tab with the level count in the tab label

### Requirement: Level list tab
The levels tab SHALL show:
- the note "Soal dibuat otomatis dari rentang angka dan benda di tiap level. Satu level bertanda Gratis bisa dimainkan tanpa Akses Premium.";
- a table with a drag handle, Urutan, Nama level (with the "Gratis" chip, and "Tanpa syarat" or "Setelah Level n"), Rentang, Soal, Benda, Bintang (benar pertama), Status (Terbit, Draft, Ada perubahan or Disembunyikan), Versi, and Edit plus a "⋯" menu (Sembunyikan or Tampilkan, Jadikan gratis, Hapus);
- a "Pustaka benda" summary card with each object's picture, name and "Dipakai di n level", and "Kelola pustaka", which switches tabs.

"+ Tambah level" SHALL create a draft level and open its editor; any admin may use it. Dragging and the "⋯" actions SHALL be disabled for editors.

#### Scenario: Reorder levels
- **WHEN** a publisher drags Level 3 above Level 2
- **THEN** the full order is saved, and the Urutan column updates

#### Scenario: Delete a used level
- **WHEN** a publisher deletes Level 2, which Level 3 requires
- **THEN** the page shows that the level is in use, and nothing is deleted

### Requirement: Level editor
The editor (`/angka/levels/:id`) SHALL show the breadcrumb "Konten Belajar / Angka / Level n", the level name as the title, the "Ada perubahan belum terbit" badge, the version and autosave line, and "Riwayat versi", "Simpan draft" and "Terbitkan". It SHALL have these sections:
- **Identitas:** Nama level, Urutan (read-only), "Terbuka setelah" (a level select or "Tanpa syarat"), "Tampil di aplikasi" (on a never-published level, turning it on publishes), and "Gratis untuk semua" with "Saat ini: Level n. Hanya satu level yang bisa gratis.";
- **Soal:**
  - "Jumlah benda paling sedikit" and "Jumlah benda paling banyak", and "Soal per level" as a stepper;
  - "Benda yang dipakai", as toggle chips with "Kelola pustaka benda" and "Satu benda per soal, dipilih acak. n benda dipilih.";
  - "Susunan gambar", with Tersebar or Baris;
- **Penilaian:** "★★★ jika benar minimal … dari N soal", "★★ jika benar minimal … dari N soal", and a note that the child keeps trying until the answer is right;
- **Umpan balik:** "Judul benar", "Judul salah", and "Petunjuk saat salah" with "{benda} diganti otomatis dengan nama benda di soal."

The draft SHALL autosave 2 seconds after the last edit. A `409 DRAFT_CONFLICT` SHALL show a reload prompt. Publish validation errors SHALL highlight the matching fields.

#### Scenario: Publish highlights errors
- **WHEN** a publisher presses "Terbitkan" with ★★ set to 9 and ★★★ set to 7
- **THEN** publish is refused, and both Penilaian fields are highlighted

#### Scenario: Editor sees publish disabled
- **WHEN** an editor opens a level
- **THEN** "Terbitkan", "Tampil di aplikasi" and "Gratis untuk semua" are disabled with the publishing-role tooltip

### Requirement: Question preview
The editor SHALL show a "Pratinjau soal" phone panel, labelled "Contoh soal k dari N · draft". It SHALL render the preview endpoint's questions for the unsaved draft, using the app's question-screen layout. Arrows SHALL step through the questions, and "Acak ulang" SHALL request a new seed. The number pad SHALL work, and "Periksa" SHALL show the draft's success or retry title and hint. The panel SHALL end with "Soal di aplikasi dibuat dengan cara yang sama, jadi pratinjau ini sesuai dengan yang dilihat anak."

#### Scenario: Preview follows edits
- **WHEN** an editor changes the range to 1–5
- **THEN** after the debounce, the preview shows questions with 1–5 pictures

### Requirement: Object library tab
The "Pustaka benda" tab SHALL show the objects as cards (the picture on a tinted background, the name, "Dipakai di n level", and the status) with "+ Tambah benda". The add and edit drawer SHALL have:
- Gambar: the upload-or-URL field, with "PNG/WebP latar transparan, maks. 300 KB";
- Nama;
- Teks pertanyaan, prefilled "Ada berapa {nama}?" while it is empty;
- Suara pertanyaan: the upload-or-URL field, with "maks. 5 detik";
- the actions "Simpan draft", "Terbitkan", "Sembunyikan" or "Tampilkan", and "Hapus".

The `OBJECT_IN_USE` and `OBJECT_LAST_IN_LEVEL` refusals SHALL be shown as messages. When the refusal is `OBJECT_IN_USE`, the message SHALL suggest hiding the object instead.

#### Scenario: Add an object
- **WHEN** an editor adds "Kucing" with a picture and audio and saves
- **THEN** a Draft card "Kucing" appears, and it can be picked in a level once a publisher publishes it

### Requirement: Kenal Angka tab
The "Kenal Angka" tab SHALL list numbers 1–20 with these columns:
- Angka;
- Nama;
- Suara, with a play button, or "Tambah suara" (opening the drawer) when the number has no audio;
- Benda, as a thumbnail;
- "Gratis", a switch;
- "Tampil di aplikasi", a switch that publishes, hides or unhides. Turning it on for a number without audio opens the drawer instead;
- Status;
- Edit, which opens a drawer with the name, the upload-or-URL audio field, and the object select.

The switches SHALL be disabled for editors.

#### Scenario: Show number 6
- **WHEN** a publisher turns on "Tampil di aplikasi" for 6, which has a name, audio and object
- **THEN** 6 is published and appears in the app's Kenal Angka grid within 15 minutes

#### Scenario: Level needs number audio
- **WHEN** publishing a level with range 1–10 is refused because numbers 8 and 10 have no published audio
- **THEN** the editor shows "Angka 8, 10 belum punya suara yang terbit" with steps and a link to the Kenal Angka tab

### Requirement: Shared content components
`AssetField` (upload or URL), `StatusTag` and `HistoryDrawer` SHALL live in `src/components/content/`, and the Huruf and Angka pages SHALL both use them. `HistoryDrawer` SHALL take the entity type, the entity id and a versions loader. The Huruf pages SHALL behave as before.

#### Scenario: Huruf unaffected
- **WHEN** the Huruf tests run after the move
- **THEN** they pass unchanged

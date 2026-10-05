## ADDED Requirements

### Requirement: Huruf letter list page
The "Konten Belajar" menu group SHALL contain Fairy Tales, AR Cards and Huruf. Fairy Tales and AR Cards move there from "Content". The legacy Tracing Items, Counting Questions and Badges entries SHALL NOT be in the menu; their routes stay reachable by URL.

The backoffice SHALL have a "Konten Belajar › Huruf" menu entry opening "Belajar Huruf", with the subtitle "Atur 26 huruf, kata contoh, suara, dan garis tebalkan yang tampil di aplikasi." and the info note on the 15-minute publish delay and the free letter.

It SHALL show:
- status tabs with counts (Semua, Terbit, Draft, Disembunyikan) and a search by letter or word;
- a table with No., Huruf ("Aa"), Kata contoh (thumbnail and word, plus a "Gratis" chip on the free letter), Suara (n/2), Tebalkan ("n garis"), Status (Terbit, Draft, Ada perubahan or Disembunyikan), Versi ("v3" or "—"), Terakhir diubah (date and admin) and an Edit action;
- pagination at 10 per page.

"Ubah urutan" SHALL enter a drag-to-reorder mode that saves the full order. It SHALL be available only to publishers.

#### Scenario: Status filter
- **WHEN** the admin selects the "Draft" tab
- **THEN** only letters without a published version are listed

#### Scenario: Editor sees no reorder
- **WHEN** an editor opens the page
- **THEN** "Ubah urutan" is disabled with a tooltip saying publishing roles are required

### Requirement: Letter editor page
The editor SHALL show the breadcrumb "Konten Belajar / Huruf / X", the title "Huruf X", an "Ada perubahan belum terbit" badge when the draft differs from the published content, and the line "Versi terbit: vN · Draft disimpan otomatis {waktu} oleh {admin}". It SHALL have these sections:
- **Identitas:** read-only upper and lower case, order, the "Tampil di aplikasi" toggle (hide or unhide) and the "Gratis untuk semua" toggle with its one-free-letter note. Turning it on calls set-free, and turning it off calls unset-free.
- **Kenali:** the example word, a highlighted-letter picker with one button per character, the "Tampil sebagai …" preview, and an image upload with filename, dimensions and size plus "Ganti" and "Hapus".
- **Dengar:** letter-sound and word audio uploads with play buttons, filename, duration and "Ganti".
- Each image and audio field SHALL have an "Unggah file / Pakai URL" switch. In URL mode it takes a URL, shows the image or plays the audio from it, and warns when the URL isn't https or is on an `r2.dev` host. A slot saved with only a URL opens in URL mode.
- **Tebalkan:** "Huruf besar" and "Huruf kecil" tabs, a 300 × 300 grid canvas with "Gambar garis", "Unggah SVG" and "Putar contoh", the "Urutan garis" list (a label and the raw path for each stroke, which can be edited, deleted and dragged), "+ Tambah garis", and the "Huruf kecil wajib" toggle.
- **Umpan balik:** "Judul berhasil", "Judul belum pas" and "Petunjuk saat belum pas".

The draft SHALL autosave 2 seconds after the last edit, and also on "Simpan draft". A `409 DRAFT_CONFLICT` SHALL show a reload prompt. Upload errors SHALL show the reason in Indonesian. Publish validation errors SHALL highlight the matching fields.

#### Scenario: Upload too large
- **WHEN** an editor uploads a 700 KB image
- **THEN** the image field shows "Ukuran gambar maksimal 500 KB" and the draft is unchanged

#### Scenario: Media from a URL
- **WHEN** an editor switches the letter sound to "Pakai URL", enters `https://media.haloarunika.com/huruf/a.mp3` and saves
- **THEN** the draft stores `letter_audio_url` with `letter_audio_id` null, and the other slots are unchanged

#### Scenario: Free letter turned off
- **WHEN** a publisher turns off "Gratis untuk semua" on the free letter
- **THEN** the backoffice calls unset-free

#### Scenario: Invalid path typed
- **WHEN** an editor types `M10 10 A5 5` into a stroke path
- **THEN** the stroke row shows a parse error, and the canvas does not draw it

#### Scenario: Publish highlights errors
- **WHEN** a publisher presses "Terbitkan" on a draft without a word audio
- **THEN** publish is refused, and the Dengar word-audio field is highlighted

### Requirement: Publish, history and rollback in the backoffice
"Terbitkan" SHALL publish after confirmation. It and the "Tampil di aplikasi", "Gratis untuk semua" and rollback controls SHALL be enabled only for publishers. "Riwayat versi" SHALL open a drawer with two tabs:
- **Versi:** version, published by and when, and "Kembalikan" for publishers;
- **Aktivitas:** the audit entries for the letter.

#### Scenario: Rollback from history
- **WHEN** a publisher clicks "Kembalikan" on v1 of A and confirms
- **THEN** a new version is published with v1's content, and the header shows the new version

### Requirement: Editor live preview
The editor SHALL show a phone-sized "Pratinjau" panel, labelled "Draft, belum terbit", with Kenali and Tebalkan tabs. It SHALL render the current, unsaved draft in the app's layout: the large picture, "A a" and the word with highlighted letters on Kenali, the "Aa" card on Tebalkan, the "Dengar bunyi" button playing the uploaded audio, and the tracing guide with numbered start points and arrows. It SHALL include "Putar contoh", which animates the strokes in order at 600 ms per stroke.

#### Scenario: Preview follows edits
- **WHEN** an editor changes the word to "Anggur" and highlights index 0
- **THEN** the preview shows "Anggur" with the "A" highlighted, before any save

### Requirement: Roles page
A "Pengaturan & peran" page SHALL list the admins with email and role, and let a publisher switch any admin between "Editor" and "Publisher". The page SHALL show the `LAST_PUBLISHER` refusal as a message. Editors SHALL see the page read-only.

#### Scenario: Publisher promotes an editor
- **WHEN** a publisher sets `tim.konten@arunika.id` to Publisher
- **THEN** that admin can publish on their next request

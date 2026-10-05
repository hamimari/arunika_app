## ADDED Requirements

### Requirement: Huruf entry points
When `belajar_huruf` is on, the Belajar hub SHALL show a Huruf card ("Huruf", "Kenal huruf A sampai Z"). For non-subscribers the card SHALL carry a "Premium" badge.

Tapping the card SHALL open Belajar Huruf inside the Belajar tab, with the nav bar visible and back returning to the hub. A guest tapping the card SHALL get the existing login prompt.

When the flag is on, Beranda SHALL show a "Lanjutkan belajar" row only if the first child has a letter in progress. Its card ("HURUF", "Huruf X", the progress bar, the next activity and a play button) SHALL open that letter's detail.

#### Scenario: Subscriber opens Huruf
- **WHEN** a logged-in subscriber taps the Huruf card on Belajar
- **THEN** Belajar Huruf opens inside the Belajar tab with no "Premium" badge on the card

#### Scenario: Continue from Beranda
- **WHEN** the child completed Kenali of A
- **THEN** Beranda shows "Lanjutkan belajar" with "Huruf A", and tapping it opens A on the Tebalkan tab

#### Scenario: No progress yet
- **WHEN** the child has no letter progress
- **THEN** Beranda shows no "Lanjutkan belajar" row

### Requirement: Letter list screen
Belajar Huruf SHALL show:
- a back button, the title "Belajar Huruf" and the subtitle "Kenal huruf A sampai Z";
- a "Lanjutkan belajar" card for the latest unfinished letter, showing the Kenali and Tebalkan chips with ✓ on the completed ones;
- the "Semua Huruf" grid of published letters in manifest order, with a "x dari 26 selesai" counter that counts done letters out of the published total.

Each tile SHALL show the upper and lower case in its own pastel colour, and one state:
- not started;
- in progress, with an orange ring;
- done, with a check;
- locked, with a lock icon (non-subscribers only);
- free, with a "Gratis" chip shown to non-subscribers.

State SHALL never be conveyed by colour alone. The screen SHALL support pull-to-refresh, and SHALL show a retry state when the manifest fails to load.

#### Scenario: Non-subscriber grid
- **WHEN** a non-subscriber opens Belajar Huruf and A is free
- **THEN** A shows "Gratis" and every other tile shows a lock

#### Scenario: Locked tap
- **WHEN** a non-subscriber taps B
- **THEN** the parental gate opens, followed by the Akses Premium paywall

#### Scenario: Unlock in place
- **WHEN** the parent subscribes on the paywall and returns
- **THEN** the manifest is refetched and every tile is unlocked without restarting the app

### Requirement: Letter detail screen
The letter detail SHALL show:
- a header with back, the title "Huruf X" and a next-letter button, which is hidden on the last letter and opens the paywall when the next letter is locked;
- the Kenali and Tebalkan segmented tabs, with ✓ on completed ones. Dengar is not a separate tab: its sounds live on Kenali.

The activities SHALL behave as follows:
- **Kenali:** shown on open. It shows the example picture (about 200 px), the letter as "A a" in large type, and the word with its highlighted letters. Tapping the picture or the word plays the word audio, and "Dengar bunyi" plays the letter sound, both without limit. "Lanjut ke Tebalkan" switches tabs. Opening a letter marks both `kenali_done` and `dengar_done`.
- **Tebalkan:** shows the "Aa" card with "Dengar bunyi" and the word button, then "Tebalkan huruf X", "Ikuti angka dan panah", the tracing canvas (see `huruf-tracing`), and "Ulangi" and "Selesai".

A letter is done when Kenali and Tebalkan are done.

Progress SHALL be sent to the server after each change and retried with backoff while the screen is open. Audio SHALL respect the device's silent mode. A failed audio load SHALL show a retry icon without blocking completion. Touch targets SHALL be at least 44 px.

#### Scenario: Kenali with sounds
- **WHEN** the child opens A
- **THEN** Kenali shows the Apel picture, "A a" and "Apel" with the A highlighted, the Kenali tab shows ✓, and `kenali_done: true` and `dengar_done: true` are sent
- **AND** tapping "Dengar bunyi" plays the letter sound and tapping the picture plays the word

#### Scenario: Audio fails
- **WHEN** the word audio URL fails to load
- **THEN** the word button shows a retry icon, and Kenali and Tebalkan can still be completed

#### Scenario: Next letter locked
- **WHEN** a non-subscriber finishes A and taps the "B ›" button
- **THEN** the parental gate and paywall open

### Requirement: Learning feedback pop-ups
A shared `LearningFeedbackDialog` SHALL render two variants:
- **success:** the mascot with a check, confetti, a title, a subtitle, three stars, a "+1 bintang" chip, a primary green action and a secondary outlined action;
- **retry:** the mascot with a retry badge, a title, a subtitle, a "Petunjuk:" hint box, a primary orange action and a secondary outlined action.

The pop-ups SHALL NOT use red or failure sounds.

For Huruf:
- **success** SHALL use the letter's feedback title (for example "Keren! Huruf A rapi!"), "Kamu berhasil menebalkan huruf A.", "Lanjut ke huruf B" and "Tebalkan lagi";
- **retry** SHALL use the feedback retry title, the reason text, the feedback hint, "Coba lagi" and "Lihat contoh".

For a non-subscriber finishing the free letter, the success pop-up SHALL add "Buka semua huruf", which opens the parental gate and the paywall.

#### Scenario: Success on the free letter
- **WHEN** a non-subscriber completes tracing A
- **THEN** the success pop-up shows "Keren! Huruf A rapi!" and a "Buka semua huruf" action

#### Scenario: Retry
- **WHEN** the child fails a stroke three times by going off the path
- **THEN** the retry pop-up shows "Belum pas, ayo lagi!", "Garisnya keluar dari jalur huruf A." and the hint

### Requirement: Locked access handling
When any Huruf request returns 402 `PREMIUM_REQUIRED`, the app SHALL refetch the manifest and show the letter as locked, without an error message. While a letter is open, the child SHALL be able to finish it after the subscription lapses. Progress writes rejected with 402 SHALL be dropped silently.

#### Scenario: Subscription expires mid-letter
- **WHEN** the subscription expires while the child is tracing C
- **THEN** the child can finish C, and on returning to the grid, C is shown locked

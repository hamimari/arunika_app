## ADDED Requirements

### Requirement: Angka entry points
When `belajar_angka` is on, the Belajar hub SHALL show an Angka card ("Angka", "Kenal angka, hitung benda, jawab soal", "Mulai"), with a "Premium" badge for non-subscribers. Tapping it SHALL open Belajar Angka inside the Belajar tab. A guest SHALL get the existing login prompt.

When the flag is on and the first child has a level in progress, Beranda's "Lanjutkan belajar" row SHALL show an Angka card ("ANGKA", the level name, "x/10 soal" and a play button) next to the Huruf card. Tapping it SHALL resume that level. The row SHALL appear when either module has something in progress.

#### Scenario: Flag off
- **WHEN** `belajar_angka` is off
- **THEN** neither the hub card nor the Angka continue card is shown

#### Scenario: Continue from Beranda
- **WHEN** the child answered 3 of 10 questions in Level 2
- **THEN** Beranda shows "Hitung 1 sampai 10" with "3/10 soal", and tapping it opens question 4

### Requirement: Belajar Angka screen
Belajar Angka SHALL show a back button, the title "Belajar Angka", and the subtitle "Kenal angka dan berhitung, yuk!".

It SHALL show the **Kenal Angka** card ("Ketuk angka untuk dengar bunyinya") with a speaker button and the published numbers as coloured tiles, five per row.

It SHALL show the **Hitung Benda** section ("Hitung gambarnya, lalu ketik jawabannya") with the levels in manifest order. Each level card shows the range badge, "Level n", the name and the best stars (0–3), with one state:
- **Mulai:** not started;
- **Lanjut:** in progress, with a progress bar and "x/10 soal";
- **Main lagi:** done;
- **locked by prerequisite:** a lock and "Selesaikan Level n untuk membuka";
- **locked behind Premium:** a lock, for non-subscribers.

Free items SHALL show a "Gratis" chip to non-subscribers. State SHALL never be shown by colour alone. The screen SHALL support pull-to-refresh and a retry state.

#### Scenario: Non-subscriber view
- **WHEN** a non-subscriber opens Belajar Angka, with Level 1 and numbers 1–5 free
- **THEN** tiles 6–10 and Levels 2–3 show locks, and Level 1 shows "Gratis"

#### Scenario: Locked tap
- **WHEN** a non-subscriber taps number 7 or Level 2
- **THEN** the parental gate opens, followed by the Akses Premium paywall, and on return as a subscriber the items unlock in place

#### Scenario: Prerequisite lock
- **WHEN** a subscriber's child hasn't completed Level 2
- **THEN** Level 3 shows "Selesaikan Level 2 untuk membuka", and tapping it does nothing

### Requirement: Kenal Angka number card
Tapping an unlocked number SHALL open a card with the numeral, the name, and that many copies of the number's object. No audio SHALL play until the child taps the speaker ("Dengarkan"). Then the number audio SHALL play, and the objects SHALL light up one by one while the count audio for 1, 2, … plays. The card SHALL have the speaker, previous and next.

#### Scenario: Quiet on open
- **WHEN** a child taps 3
- **THEN** the card shows 3 and three apples, and nothing plays

#### Scenario: Count aloud
- **WHEN** the child taps the speaker on the card for 3
- **THEN** "tiga" plays, and three apples light up in turn with "satu", "dua", "tiga"

### Requirement: Question screen
The question screen SHALL show:
- a close button, "Level n · Soal k dari N" with a progress bar, and a star counter (the first-try correct answers so far);
- the question text with a speaker button. The question audio SHALL play only when the child taps the speaker or "Dengar soal lagi", never on its own;
- the pictures at the generated positions on a tinted panel;
- a "Jawabanmu" box (a "?" placeholder, at most 2 digits);
- a number pad with 1–9, delete, 0 and "Periksa". The keys are at least 56 px, and Periksa is disabled while the box is empty.

Tapping a picture SHALL mark it with the next number and play that number's audio. There SHALL be no timers. Closing SHALL keep the session, so "Lanjut" resumes at the first unfinished question.

#### Scenario: Leading zero
- **WHEN** the child types 0 then 7 and presses Periksa on a 7-apple question
- **THEN** the answer is read as 7 and is correct

#### Scenario: Empty answer
- **WHEN** the answer box is empty
- **THEN** Periksa is disabled

### Requirement: Answer feedback and level end
A correct answer SHALL show the success pop-up: the level's success title, "Ada n {benda}. Kamu pintar berhitung!", "+1 bintang" when correct on the first try, "Soal berikutnya" and "Kembali ke menu".

Every wrong answer SHALL show the retry pop-up: the retry title, "Jawabanmu x. Yuk, hitung {benda}nya sekali lagi.", the hint with `{benda}` replaced, "Coba lagi" and "Dengar soal lagi".

There SHALL be no try limit: the child keeps trying until the answer is right, and the app SHALL never reveal the answer. A question answered right after the first try earns no "+1 bintang".

Every try SHALL be sent to the server. After the last question, the app SHALL call complete and show a level pop-up with the stars, "x dari N benar di percobaan pertama", "Level berikutnya" (when one was unlocked), "Main lagi" and "Kembali ke menu". For non-subscribers on the free level it SHALL add "Buka semua level". Stars computed on the device SHALL be replaced by the server's result.

#### Scenario: First wrong answer
- **WHEN** the child answers 6 on a 7-apple question
- **THEN** the retry pop-up shows "Jawabanmu 6" and the hint "Sentuh apel satu per satu sambil menyebut 1, 2, 3…"

#### Scenario: Wrong again
- **WHEN** the child answers wrong a second, third or later time
- **THEN** the retry pop-up shows again, the answer isn't shown, and the question stays until the child answers 7

#### Scenario: Free level finished
- **WHEN** a non-subscriber finishes Level 1
- **THEN** the level pop-up shows the stars and "Buka semua level"

#### Scenario: Complete fails
- **WHEN** complete fails because the device is offline
- **THEN** the pop-up shows provisional stars, and complete is retried the next time Belajar Angka opens

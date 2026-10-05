## ADDED Requirements

### Requirement: Guide path parsing and sampling
The app SHALL parse stroke paths written as a single subpath of absolute `M`, `L`, `Q` and `C` commands on the 300 × 300 grid. It SHALL resample each stroke into points every 4 units, flattening curves, and SHALL reject any other path.

The Go publish validator, the Dart parser and the backoffice TypeScript parser SHALL agree on a shared fixture file of valid and invalid paths.

#### Scenario: Straight stroke sampled
- **WHEN** the path `M150 30 L70 260` is sampled
- **THEN** consecutive samples are 4 ± 0.5 units apart, starting at (150, 30) and ending at (70, 260)

#### Scenario: Shared fixture parity
- **WHEN** each parser runs over `svg_paths.json`
- **THEN** every parser accepts and rejects exactly the paths the fixture marks as valid or invalid

### Requirement: Stroke evaluation
The app SHALL map touch points to the guide grid and drop points closer than 2 units to the previous point. Only the next stroke in `order` SHALL be active. A touch that starts more than `start_tolerance` units from that stroke's start SHALL be ignored, with a gentle shake.

While the finger moves, guide samples within `radius` of the finger SHALL be marked covered and painted in the brand orange. When the finger lifts, the stroke SHALL pass only when all of these hold:
- coverage (covered samples ÷ all samples) is at least `coverage`;
- accuracy (touch points within 2 × `radius` of the guide ÷ all touch points) is at least `accuracy`;
- at least a `direction` share of the projected steps move forward along the guide.

A stroke that fails SHALL reset, and the failure reason SHALL be one of `off_path`, `too_short` or `wrong_direction`. Thresholds SHALL come from the manifest's `tracing_thresholds`, falling back to 22, 0.80, 0.85, 0.70, 30 and 3 when missing.

#### Scenario: Exact trace passes
- **WHEN** the fixture trace follows stroke 1 of A exactly from its start to its end
- **THEN** the stroke passes and stroke 2 becomes active

#### Scenario: Reversed trace fails
- **WHEN** a trace covers stroke 1 of A from its end to its start
- **THEN** the stroke fails with `wrong_direction`

#### Scenario: Half trace fails
- **WHEN** a trace covers only the first 50% of a stroke
- **THEN** the stroke fails with `too_short`

#### Scenario: Touch far from start is ignored
- **WHEN** a touch begins 60 units from the active stroke's start point
- **THEN** nothing is painted and no attempt is counted

### Requirement: Letter tracing result
A letter's tracing SHALL succeed when every upper-case stroke passes, and every lower-case stroke too when `lower_required` is true. The score SHALL be the mean of coverage × accuracy across those strokes, rounded to two decimals.

After `max_failures` failed attempts on the same stroke, the app SHALL show the retry pop-up with the reason's text and "Lihat contoh". "Lihat contoh" SHALL animate a dot along each stroke in order, 600 ms per stroke. "Ulangi" SHALL clear every stroke of the current case.

#### Scenario: Lowercase required
- **WHEN** `lower_required` is true and the child finishes "A"
- **THEN** the canvas switches to "a", and success is shown only after "a" passes

#### Scenario: Three failures
- **WHEN** a child fails stroke 2 three times in a row
- **THEN** the retry pop-up "Belum pas, ayo lagi!" appears with the hint and the "Coba lagi" and "Lihat contoh" buttons

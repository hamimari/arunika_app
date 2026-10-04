## ADDED Requirements

### Requirement: WHO LMS z-score engine
The system SHALL provide a pure classification function in both Go (backend package `growth`) and Dart (app `lib/core/growth/`). It SHALL take sex, birth date, measurement date, height in cm (optional), weight in kg (optional) and position (`standing` or `recumbent`). It SHALL return:
- the age in whole days (`measured_on − birth_date`);
- an age label of the form "{y} tahun {m} bulan", where months = floor(age_days / 30.4375);
- a height-for-age z-score and category, when a height is given;
- a weight-for-age z-score and category, when a weight is given;
- a per-indicator implausible flag.

The z-score SHALL be computed as z = ((X/M)^L − 1)/(L·S), using the L, M and S values of the WHO Child Growth Standards 2006 expanded daily tables for the child's sex and exact age in days. Boys and girls SHALL never share a table. Z-scores SHALL be rounded to 2 decimals.

#### Scenario: Boy at the height median
- **WHEN** a boy aged 36 months (1096 days) is measured standing at 96.1 cm
- **THEN** the height-for-age z-score is 0.00 ± 0.01 and the category is `normal`

#### Scenario: Boy at −2 SD height
- **WHEN** a boy aged 36 months is measured standing at 88.7 cm
- **THEN** the height-for-age z-score is −2.00 ± 0.01 and the category is `normal`

#### Scenario: Only weight given
- **WHEN** a measurement has a weight and no height
- **THEN** only the weight-for-age result is returned and the height-for-age result is absent

### Requirement: Length and height adjustment
The engine SHALL use length (recumbent) as the reference under 731 days and height (standing) from 731 days. A standing measurement under 731 days SHALL have 0.7 cm added before computing the z-score. A recumbent measurement at 731 days or more SHALL have 0.7 cm subtracted. The raw input value SHALL be kept unchanged, and the adjusted value SHALL be returned alongside it.

#### Scenario: Standing measurement at 730 days
- **WHEN** a child aged 730 days is measured standing at 85.0 cm
- **THEN** the z-score is computed from 85.7 cm against the length table

#### Scenario: Recumbent measurement at 731 days
- **WHEN** a child aged 731 days is measured recumbent at 85.0 cm
- **THEN** the z-score is computed from 84.3 cm against the height table

### Requirement: Weight-for-age tail rule
For weight-for-age, when the LMS z-score is above 3 or below −3, the engine SHALL recompute it with the WHO restricted LMS method, where SD_k = M·(1 + L·S·k)^(1/L):
- z* = 3 + (X − SD₃)/(SD₃ − SD₂) when z > 3;
- z* = −3 + (X − SD₋₃)/(SD₋₂ − SD₋₃) when z < −3.

Height-for-age SHALL NOT apply the tail rule.

#### Scenario: Very heavy child
- **WHEN** a weight's LMS z-score is 3.4
- **THEN** the returned weight-for-age z-score is the tail-rule value computed from SD₃ and SD₂, not 3.4

### Requirement: Permenkes 2/2020 categories
The engine SHALL map the rounded z-score to categories.

Height-for-age:
- `severely_stunted` (z < −3)
- `stunted` (−3 ≤ z < −2)
- `normal` (−2 ≤ z ≤ 3)
- `tall` (z > 3)

Weight-for-age:
- `severely_underweight` (z < −3)
- `underweight` (−3 ≤ z < −2)
- `normal` (−2 ≤ z ≤ 1)
- `risk_overweight` (z > 1)

Ages above 1856 days SHALL get no z-score and the category `out_of_range`.

#### Scenario: Exactly −2 SD
- **WHEN** a rounded height-for-age z-score is exactly −2.00
- **THEN** the category is `normal`

#### Scenario: Weight just above +1 SD
- **WHEN** a rounded weight-for-age z-score is 1.01
- **THEN** the category is `risk_overweight`

#### Scenario: Child older than five years
- **WHEN** the age at measurement is 1900 days
- **THEN** no z-score is computed and both categories are `out_of_range`

### Requirement: Implausible value flag
The engine SHALL flag a height-for-age z-score outside −6 to +6, and a weight-for-age z-score outside −6 to +5, as implausible. These are the WHO flag limits.

#### Scenario: Typo in height
- **WHEN** a 3-year-old boy is entered at 9.5 cm
- **THEN** the height-for-age result is flagged implausible

### Requirement: Identical results across runtimes
The Go and Dart engines SHALL load byte-identical copies of one versioned LMS file (`who2006_lms.csv`), and each repository SHALL verify the file's SHA-256 in tests. Both engines SHALL pass a shared golden fixture within ±0.01. The fixture SHALL cover:
- every SD line of the WHO z-score tables for both sexes and both indicators, at monthly ages from 0 to 60 months;
- each category boundary;
- the tail rule;
- the 730 and 731-day adjustment.

#### Scenario: Engines disagree
- **WHEN** the Dart engine returns a z-score that differs from a golden row by more than 0.01
- **THEN** the app test suite fails

#### Scenario: LMS file edited in one repository
- **WHEN** `who2006_lms.csv` changes in one repository and not the other
- **THEN** that repository's checksum test fails

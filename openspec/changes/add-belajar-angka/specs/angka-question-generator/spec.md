## ADDED Requirements

### Requirement: Seeded question generator
The backend (`angkagen`, Go) and the app (`lib/core/angka/`, Dart) SHALL each implement the same pure function. It turns a level's `range`, `question_count`, `layout`, an object id list and a 32-bit seed into `question_count` questions, each `{count, object_id, size, points}`. The function SHALL use only 32-bit integer arithmetic, with mulberry32 as the PRNG, in this fixed order of PRNG use:
1. the remainder shuffle;
2. the bag shuffle;
3. then, per question, the object followed by the positions.

**Counts:**
- With `R = max − min + 1` and `n = question_count`, the bag SHALL hold `n / R` full copies of `min..max`, plus the first `n % R` values of a shuffled `min..max`. The bag is then shuffled.
- The bag SHALL then be re-read in order, each step taking the first remaining value that differs from the previous one. When one value fills more than half of what remains, that value SHALL be taken next.

**Objects:** no object SHALL be used twice in a row when more than one object is available.

#### Scenario: Whole range covered
- **WHEN** a level has range 1–10, 10 questions and any seed
- **THEN** each value 1–10 appears exactly once

#### Scenario: Range larger than the question count
- **WHEN** a level has range 11–20 and 5 questions
- **THEN** the 5 counts are distinct values between 11 and 20

#### Scenario: No back-to-back repeats
- **WHEN** a level has range 6–7, 11 questions and objects apel, bola
- **THEN** no two consecutive questions share a count, and none share an object

#### Scenario: Same seed, same questions
- **WHEN** the generator runs twice with the same input and seed
- **THEN** both outputs are identical

### Requirement: Picture positions
Positions SHALL lie in a 320 × 180 area. The picture size SHALL be 52 for at most 5 pictures, 38 for at most 10, 30 for at most 15, and 26 otherwise.

**Scatter** SHALL place each picture by trying up to 30 integer candidates inside the area. A candidate is accepted when the squared distance to every placed picture is at least `(size + 12)²`. If any picture can't be placed, the question SHALL use the rows layout instead.

**Rows** SHALL use `ceil(n / 5)` centred rows with a 12-unit gap. Earlier rows take the extra picture, so 7 pictures are laid out as 4 + 3.

#### Scenario: Pictures never overlap
- **WHEN** 10,000 random cases are generated
- **THEN** in every scatter question, every pair of pictures is at least `size + 12` apart and inside the area

#### Scenario: Crowded scatter falls back
- **WHEN** a scatter question needs 20 pictures, and one picture can't be placed in 30 tries
- **THEN** that question uses rows, and the following questions are generated as usual

### Requirement: Generator parity fixture
`angkagen/testdata/generator_golden.json` SHALL hold at least 500 cases (input and expected output). The cases SHALL cover every size bucket, `R = 1`, `R > n` and both layouts. The Go tests and the app's tests (using a copy in `test/fixtures/`) SHALL both reproduce every case exactly. Each language SHALL also run property tests over 10,000 random cases.

#### Scenario: Dart drifts from Go
- **WHEN** a change to the Dart generator changes the output for any golden case
- **THEN** `flutter test` fails

## ADDED Requirements

### Requirement: Tracing item list by type
The backend SHALL expose an endpoint to retrieve tracing items filtered by type (alphabet, number, shape). Each item SHALL include its label, guide path JSON, and difficulty.

#### Scenario: Fetch alphabet tracing items
- **WHEN** client sends GET `/tracing/items?type=alphabet`
- **THEN** system returns a list of 26 items (A–Z) with guide_path_json and difficulty

#### Scenario: Fetch items with invalid type
- **WHEN** client sends GET `/tracing/items?type=invalid`
- **THEN** system returns HTTP 400 with a descriptive error message

### Requirement: Canvas-based tracing exercise
The Flutter app SHALL render a tracing exercise screen with a guide path overlay and capture user strokes via a CustomPainter canvas.

#### Scenario: Guide path displayed
- **WHEN** user opens a tracing exercise for letter "A"
- **THEN** the guide path for "A" is drawn on the canvas in a muted colour before the user starts

#### Scenario: User stroke captured
- **WHEN** user draws on the canvas
- **THEN** the stroke is rendered in real-time as the finger moves

### Requirement: Stroke scoring on device
The Flutter app SHALL compute a tracing score (0–100) by comparing the user's stroke to the guide path. A score ≥ 70 SHALL count as passed.

#### Scenario: Score above threshold
- **WHEN** user completes a stroke with score ≥ 70
- **THEN** app shows success animation and sound, marks item as passed

#### Scenario: Score below threshold
- **WHEN** user completes a stroke with score < 70
- **THEN** app shows retry prompt with encouraging message

### Requirement: Tracing progress persistence
The backend SHALL store each tracing attempt (score, passed, child_id, item_id) submitted by the Flutter app.

#### Scenario: Submit tracing result
- **WHEN** client sends POST `/tracing/progress` with valid item_id, score, and passed fields
- **THEN** system saves the record and returns HTTP 201 with the saved progress object

#### Scenario: Submit with missing fields
- **WHEN** client sends POST `/tracing/progress` with missing item_id
- **THEN** system returns HTTP 400

### Requirement: Badge progress update on tracing completion
The backend SHALL check badge thresholds and award badges within the same transaction as saving tracing progress.

#### Scenario: Badge threshold crossed
- **WHEN** a tracing progress submission causes the user's completed count to reach 5
- **THEN** the backend inserts a `user_badges` row for the Beginner badge in the same transaction

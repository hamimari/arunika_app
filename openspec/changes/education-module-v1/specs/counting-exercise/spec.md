## ADDED Requirements

### Requirement: Counting question list by level
The backend SHALL expose an endpoint to retrieve counting questions filtered by level (easy, medium, hard).

#### Scenario: Fetch easy questions
- **WHEN** client sends GET `/counting/questions?level=easy`
- **THEN** system returns questions where the answer is in the range 1–5

#### Scenario: Unauthorised access to hard level
- **WHEN** a free-tier user sends GET `/counting/questions?level=hard`
- **THEN** system returns HTTP 403

### Requirement: Visual counting exercise screen
The Flutter app SHALL display a counting exercise with visual objects (images of fruits or toys) and a tap/select answer UI.

#### Scenario: Objects displayed
- **WHEN** user opens a counting exercise
- **THEN** the screen shows N visual objects matching the question count

#### Scenario: Correct answer selected
- **WHEN** user taps the correct answer option
- **THEN** app shows immediate green feedback and advances to the next question

#### Scenario: Wrong answer selected
- **WHEN** user taps an incorrect answer option
- **THEN** app shows red feedback and allows retry

### Requirement: Counting progress persistence
The backend SHALL store each counting answer (correct/incorrect, child_id, question_id) submitted by the Flutter app.

#### Scenario: Submit correct answer
- **WHEN** client sends POST `/counting/progress` with is_correct: true
- **THEN** system saves the record and returns HTTP 201

#### Scenario: Submit with invalid question_id
- **WHEN** client sends POST `/counting/progress` with a non-existent question_id
- **THEN** system returns HTTP 404

### Requirement: Badge progress update on counting completion
The backend SHALL check and award counting badges within the same transaction as saving counting progress.

#### Scenario: Explorer badge awarded
- **WHEN** a counting progress submission causes completed count to reach 15
- **THEN** backend inserts a `user_badges` row for the counting Explorer badge

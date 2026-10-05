## ADDED Requirements

### Requirement: Starting a session
`POST /children/:childId/angka/sessions {level_id, restart?}` SHALL check, in this order:
1. the child belongs to the caller and is not deleted (404);
2. the level is published and visible (404);
3. access (402 `PREMIUM_REQUIRED`);
4. the prerequisite is completed by the child (`409 LEVEL_LOCKED`). A missing, hidden or unpublished prerequisite counts as met.

If the child has an in-progress session for the level, touched in the last 7 days, and `restart` is not true, the server SHALL return that session. Otherwise it SHALL mark any older session `abandoned` and create a new one with:
- the current published version;
- a random 32-bit seed;
- a snapshot of the level's objects that are currently published and not hidden.

It SHALL respond `{session_id, seed, level_version, object_ids, answers}`.

#### Scenario: Resume with Lanjut
- **WHEN** a child answered 3 of 10 questions yesterday and starts the same level again
- **THEN** the same session is returned with its seed and 3 answers

#### Scenario: Prerequisite not done
- **WHEN** a subscriber's child who hasn't completed Level 2 starts Level 3
- **THEN** the server responds 409 `LEVEL_LOCKED`

#### Scenario: Hidden object skipped
- **WHEN** "Bebek" is hidden and a new session of Level 2 (Apel, Bola, Ikan, Bebek) starts
- **THEN** the session's `object_ids` exclude Bebek

#### Scenario: Level edited mid-play
- **WHEN** a publisher publishes v2 of Level 2 while a child has a v1 session in progress
- **THEN** the child's session keeps v1's questions and thresholds, and the next new session uses v2

### Requirement: Recording tries
`PATCH /children/:childId/angka/sessions/:id {q, try, answer}` SHALL record an answer (0–99) for question `q`, try `try`. A repeated `(q, try)` with the same answer SHALL be a no-op. The server SHALL respond `422 INVALID_TRY` to any of these:
- a different answer for a recorded try;
- a skipped try;
- a try after a correct answer;
- a wrong try after 50 wrong tries on that question (only the right answer is then stored, so a child can always finish);
- any try on a completed session.

PATCH and complete SHALL check only child ownership, not premium access, so a level started before the subscription ended can be finished.

#### Scenario: Retry after a network failure
- **WHEN** the app sends the same `{q: 3, try: 1, answer: 6}` twice
- **THEN** one try is stored and both requests succeed

#### Scenario: Subscription expires mid-level
- **WHEN** a subscription expires while a child is on question 5 of Level 2
- **THEN** the remaining tries and complete succeed, and the next start of Level 2 responds 402

### Requirement: Completing a session and stars
`POST /children/:childId/angka/sessions/:id/complete` SHALL regenerate the questions from the session's version, seed and object snapshot. It SHALL respond `422 SESSION_INCOMPLETE` unless every question has a correct try. There is no try limit: a question stays open until it is answered correctly.

`first_correct` SHALL be the number of questions answered correctly on try 1. Stars SHALL be:
- 3 when `first_correct ≥ stars.three`;
- 2 when `first_correct ≥ stars.two`;
- 1 otherwise.

The server SHALL set `best_stars` to the larger of the stored and new value, set `completed`, and clear `current_session_id`. It SHALL respond `{stars, first_correct, best_stars, unlocked_level_ids}`. Completing again SHALL return the same result.

#### Scenario: Threshold boundary
- **WHEN** a Level 2 session (three = 9, two = 7) ends with 9 first-try correct answers
- **THEN** stars is 3

#### Scenario: Replay keeps best
- **WHEN** a child with 3 best stars replays Level 1 and earns 1 star
- **THEN** `best_stars` stays 3

#### Scenario: Next level unlocked
- **WHEN** a child completes Level 2 for the first time and Level 3 requires Level 2
- **THEN** `unlocked_level_ids` contains Level 3

#### Scenario: Server scoring wins
- **WHEN** the app shows 3 provisional stars but the recorded tries give 7 first-try correct answers out of thresholds 9 and 7
- **THEN** the server stores and returns 2 stars

### Requirement: Angka progress
`GET /children/:childId/angka/progress` SHALL return, per level:
- `best_stars` and `completed`;
- the current in-progress session (`id`, `level_version`, `seed`, `object_ids`, `answers`, `updated_at`), if any.

Sessions not touched for 7 days SHALL be returned as abandoned and not current. The route SHALL respond 404 unless the child belongs to the caller.

#### Scenario: Another parent's child
- **WHEN** parent A requests parent B's child's Angka progress
- **THEN** the server responds 404

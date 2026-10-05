## ADDED Requirements

### Requirement: Admin letter list and draft editing
These endpoints SHALL require an admin JWT and work for both the `editor` and `publisher` roles.

`GET /admin/huruf/letters` SHALL return every letter with:
- `upper`, `sort_order`, `is_free` and `status`;
- `has_unpublished_changes`;
- the published `version` number;
- the draft's word and image URL;
- an audio count (0–2) and an upper-case stroke count;
- `updated_by` (email) and `updated_at`.

`GET /admin/huruf/letters/:id/draft` SHALL return the draft and `draft_rev`.

`PUT /admin/huruf/letters/:id/draft` SHALL accept the draft and its `draft_rev`:
- when the rev matches, it SHALL save the draft, increment `draft_rev` and set `updated_by` and `updated_at`;
- otherwise it SHALL respond `409 DRAFT_CONFLICT` without saving.

Saving a draft SHALL NOT change what the app sees. `has_unpublished_changes` SHALL be true when the letter has no published version or when the canonical draft JSON differs from the published content.

#### Scenario: Draft save does not publish
- **WHEN** an editor changes A's word to "Anggur" and saves the draft
- **THEN** the manifest still shows "Apel" and the admin list shows A with `has_unpublished_changes: true`

#### Scenario: Concurrent editors
- **WHEN** two admins load A's draft at rev 5, and the first saves (rev becomes 6) before the second saves with rev 5
- **THEN** the second save responds 409 `DRAFT_CONFLICT`

### Requirement: Publish with validation
`POST /admin/huruf/letters/:id/publish` SHALL require the `publisher` role. It SHALL validate the draft and, on success, in one transaction:
- insert `letter_versions` with the next version number and the draft as `content`;
- set `published_version_id` and `status = 'published'`;
- write an audit entry.

Validation SHALL fail with `422 {"code": "VALIDATION_FAILED", "fields": [{"path", "code"}]}` when any of these holds:
- the word is missing, longer than 20 characters, or its highlighted positions are outside the word or are not the letter;
- the image, letter audio or word audio is missing or not an asset of the right kind;
- the upper strokes are empty, or the lower strokes are empty while `lower_required` is true;
- a stroke's `order` values are not unique and contiguous from 1;
- a stroke path does not parse as a single absolute `M`/`L`/`Q`/`C` subpath with coordinates within 0–300;
- a feedback text is empty or too long.

#### Scenario: Valid publish
- **WHEN** a publisher publishes B, whose last version is 2, and the draft is valid
- **THEN** version 3 is created and the manifest shows B with `version: 3`

#### Scenario: Missing audio
- **WHEN** a publisher publishes D, whose draft has no word audio
- **THEN** the server responds 422 with field `dengar.word_audio_id` and code `REQUIRED`, and no version is created

#### Scenario: Unsupported path command
- **WHEN** a stroke path is `M10 10 A5 5 0 0 1 20 20`
- **THEN** publish responds 422 with code `INVALID_PATH` for that stroke

#### Scenario: Editor cannot publish
- **WHEN** an admin with role `editor` calls publish
- **THEN** the server responds 403 and nothing changes

### Requirement: Versions and rollback
`GET /admin/huruf/letters/:id/versions` SHALL list versions, newest first, with `version`, `published_by` (email) and `published_at`.

`POST /admin/huruf/letters/:id/rollback/:version` SHALL require `publisher`. It SHALL copy that version's content into a new version (the next number), make it the published version, and also replace the draft with it. Existing versions SHALL never be modified or deleted.

#### Scenario: Roll back to v1
- **WHEN** A has versions 1–3 and a publisher rolls back to version 1
- **THEN** version 4 exists with version 1's content, the manifest shows `version: 4`, and versions 1–3 are unchanged

### Requirement: Visibility, free letter and order
These endpoints SHALL require `publisher`:
- `POST /admin/huruf/letters/:id/hide` SHALL set the status to `hidden` and keep `published_version_id`.
- `POST /admin/huruf/letters/:id/unhide` SHALL restore `published`, or `draft` if the letter was never published.
- `POST /admin/huruf/letters/:id/set-free` SHALL, in one transaction, clear `is_free` on every other letter and set it on this one.
- `POST /admin/huruf/letters/:id/unset-free` SHALL clear `is_free` on this letter. No letter is free afterwards if it was the free one.
- `PUT /admin/huruf/order` SHALL accept the full list of letter ids and rewrite `sort_order` 1..n in that order. It SHALL respond 422 if the list is not exactly the set of all letters.

Hiding a letter SHALL keep children's progress rows.

#### Scenario: Move the free letter
- **WHEN** A is free and a publisher sets B free
- **THEN** only B has `is_free = true`, and non-subscribers see A locked and B open

#### Scenario: No free letter
- **WHEN** B is free and a publisher unsets it
- **THEN** no letter has `is_free = true`, and non-subscribers see every letter locked

#### Scenario: Hidden letter keeps progress
- **WHEN** a child finished H and a publisher hides H
- **THEN** H disappears from the manifest and the child's H progress row still exists

#### Scenario: Incomplete order list
- **WHEN** the order request lists 25 of the 26 letter ids
- **THEN** the server responds 422 and the order is unchanged

### Requirement: External media URLs
Each draft media slot (`kenali.image`, `dengar.letter_audio`, `dengar.word_audio`) SHALL hold either an uploaded asset id (`*_asset_id` / `*_audio_id`) or an external URL (`image_url`, `letter_audio_url`, `word_audio_url`) for a file the content team hosts themselves, such as on R2. On save the server SHALL trim URLs and drop a URL whose slot also has an asset id. The asset id SHALL win when both are present.

Publishing SHALL accept a slot with only a URL if it is an absolute `https` URL, and SHALL otherwise report `INVALID_URL` at the URL's path. The URL is not fetched or checked for size, type or duration. The manifest, letter content, preview and admin list SHALL return the URL unchanged as the slot's URL, and the audio count SHALL count URL slots.

#### Scenario: Publish with URLs
- **WHEN** a draft has no uploaded assets but https URLs for the image and both audio slots, and a publisher publishes it
- **THEN** the publish succeeds, and the app receives those URLs as `image_url`, `letter_audio_url` and `word_audio_url`

#### Scenario: Cleartext URL refused
- **WHEN** the letter audio URL is `http://media.example.com/a.mp3`
- **THEN** publish responds 422 with `dengar.letter_audio_url` `INVALID_URL`

#### Scenario: Upload replaces a URL
- **WHEN** a slot has a URL and an editor uploads a file for it and saves
- **THEN** the stored draft has the asset id and no URL for that slot

### Requirement: Draft preview data
`POST /admin/huruf/letters/:id/preview` SHALL accept a draft body and return it with asset ids resolved to URLs, without saving anything, so the backoffice preview can render unsaved changes.

#### Scenario: Preview an unsaved image
- **WHEN** an editor uploads a new image and requests a preview before saving
- **THEN** the response contains the new image URL and the stored draft is unchanged

## ADDED Requirements

### Requirement: Admin asset upload
`POST /admin/assets` SHALL accept a multipart `file` and a `kind` (`image` or `audio`). It SHALL require an admin JWT, with either the `editor` or `publisher` role.

The server SHALL decide the file type from its bytes, never from the filename or the declared content type, and SHALL accept only these files:
- **Image:** PNG or WebP, at most 500 KB, square, between 256 and 2048 px on a side.
- **Audio:** MP3 or AAC (ADTS), at most 300 KB, with a duration computed from its frames of at most 10 seconds.

Otherwise it SHALL respond `422 {"code": "INVALID_ASSET", "reason": ...}`, where `reason` is one of `UNSUPPORTED_TYPE`, `TOO_LARGE`, `NOT_SQUARE`, `TOO_LONG` or `UNREADABLE`.

On success it SHALL respond 201 with `{id, kind, url, mime, bytes, width, height, duration_ms, original_name}`.

#### Scenario: Valid image
- **WHEN** an editor uploads a 512 × 512 WebP of 180 KB as `image`
- **THEN** the server responds 201 with a URL under the media base URL and `width: 512`

#### Scenario: Renamed file
- **WHEN** a JPEG renamed to `apel.png` is uploaded as `image`
- **THEN** the server responds 422 `UNSUPPORTED_TYPE`

#### Scenario: Audio too long
- **WHEN** a 12-second MP3 of 200 KB is uploaded as `audio`
- **THEN** the server responds 422 `TOO_LONG`

#### Scenario: Non-square image
- **WHEN** a 600 × 400 PNG is uploaded as `image`
- **THEN** the server responds 422 `NOT_SQUARE`

### Requirement: Content-addressed storage
Each accepted file SHALL be stored under the key `huruf/<sha256>.<ext>` through a storage driver. A `content_assets` row SHALL record the `id`, `kind`, `storage_key`, a unique `sha256`, `bytes`, `mime`, `width`, `height`, `duration_ms`, `original_name`, `created_by` and `created_at`.

Uploading bytes whose SHA-256 already exists SHALL return the existing asset without writing again. Public URLs SHALL be `MEDIA_PUBLIC_BASE_URL` followed by the key.

The `r2` driver SHALL write to S3-compatible storage configured by the `MEDIA_S3_*` variables. The `local` driver SHALL write to `MEDIA_LOCAL_DIR` and serve the files at `/media/huruf/:file`. The server SHALL refuse to start in production unless the driver is `r2` and `MEDIA_PUBLIC_BASE_URL` is set and is not an `r2.dev` host.

#### Scenario: Duplicate upload
- **WHEN** the same MP3 is uploaded twice
- **THEN** both responses return the same asset `id` and one object exists in storage

#### Scenario: Production misconfiguration
- **WHEN** the server starts with `APP_ENV=production` and `MEDIA_DRIVER=local`
- **THEN** startup fails with a configuration error

#### Scenario: Blocked media host
- **WHEN** the server starts in production with `MEDIA_PUBLIC_BASE_URL=https://pub-123.r2.dev/`
- **THEN** startup fails with a configuration error

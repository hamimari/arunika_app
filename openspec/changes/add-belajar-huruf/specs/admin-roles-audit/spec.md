## ADDED Requirements

### Requirement: Admin content roles
`admin_users` SHALL have a `role` that is either `editor` or `publisher`. The migration SHALL set every existing admin to `publisher`, and new rows SHALL default to `publisher`.

Admin login and refresh responses SHALL include `role`. Publisher-only routes SHALL read the caller's role from the database on every request and respond 403 for an `editor`. The publisher-only routes are:
- Huruf publish, hide, unhide, set-free, reorder and rollback;
- changing a role.

All other existing admin routes SHALL keep accepting any admin.

#### Scenario: Existing admin after migration
- **WHEN** the migration runs on a database with `admin@arunika.id`
- **THEN** that admin has role `publisher` and can still use every existing backoffice page

#### Scenario: Demotion takes effect immediately
- **WHEN** a publisher is demoted to editor while holding a valid access token
- **THEN** their next publish call responds 403

### Requirement: Role management
`GET /admin/admins` SHALL list non-deleted admins with `id`, `email` and `role`, for any admin role, so editors can see who can publish. `PATCH /admin/admins/:id/role` SHALL set the role and SHALL require `publisher`. A change that would leave no publisher SHALL respond `409 LAST_PUBLISHER`.

#### Scenario: Last publisher protected
- **WHEN** the only publisher tries to make themselves an editor
- **THEN** the server responds 409 `LAST_PUBLISHER` and the role is unchanged

#### Scenario: Editor cannot change roles
- **WHEN** an editor calls `PATCH /admin/admins/:id/role`
- **THEN** the server responds 403

### Requirement: Admin audit log
An `admin_audit_log` row SHALL be written in the same transaction as every one of these actions:
- a Huruf draft save, publish, rollback, hide, unhide, set-free or reorder;
- an asset upload;
- a role change.

Each row SHALL record `admin_id`, `action`, `entity_type`, `entity_id`, a `before` and `after` JSON value, and `created_at`. Consecutive `draft.save` entries by the same admin on the same letter within 10 minutes SHALL update the latest entry's `after` instead of adding a row.

`GET /admin/audit-log?entity_type=&entity_id=` SHALL return the entries, newest first and paginated, with the admin's email. If the audit write fails, the action SHALL fail too.

#### Scenario: Publish is logged
- **WHEN** a publisher publishes B
- **THEN** one audit entry exists with action `publish`, entity `letter`/B's id, and an `after` that holds the new version number

#### Scenario: Autosave coalesced
- **WHEN** an editor's draft autosaves five times within three minutes
- **THEN** the audit log has one `draft.save` entry for that letter, whose `after` matches the last save

#### Scenario: Role change logged
- **WHEN** a publisher changes an editor to publisher
- **THEN** an entry with action `role.change`, `before.role` `editor` and `after.role` `publisher` exists

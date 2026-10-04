# backend-database-tests Specification

## Purpose
TBD - created by archiving change add-automation-testing-strategy. Update Purpose after archive.
## Requirements
### Requirement: Data-integrity behaviour is tested against real PostgreSQL
Any behaviour whose correctness depends on the database — constraints, unique indexes, foreign keys, transactions, soft deletion, query shape — SHALL be tested against a real PostgreSQL instance provisioned by Testcontainers with the repository's actual migrations applied. SQL-mocking SHALL NOT be used to assert such behaviour.

#### Scenario: Container is provisioned automatically
- **WHEN** a database test package runs
- **THEN** a PostgreSQL container starts once for the package, migrations are applied to a template database, and no manual database setup is required

#### Scenario: Mocked SQL is not accepted for integrity guarantees
- **WHEN** a test asserts that a duplicate insert is rejected, that a foreign key is enforced, or that a transaction rolls back
- **THEN** it runs against real PostgreSQL rather than asserting against a mocked driver's expectation list

#### Scenario: Mocking remains acceptable where the database is incidental
- **WHEN** a test only verifies that a service propagates an error returned by its data layer
- **THEN** a mocked data layer remains acceptable, since no database behaviour is under test

### Requirement: Entitlement data layer test coverage
The `models` package, which currently has no tests, SHALL have database-backed tests for the entitlement and ownership helpers, including `GrantEntitlement`, `HasEntitlement`, `FindPackageItems` and the revocation helpers.

#### Scenario: Granting the same entitlement twice creates one row
- **WHEN** `GrantEntitlement` is called twice for the same user and product
- **THEN** exactly one `user_entitlements` row exists, and the guarantee is enforced by the real unique index rather than by a mock

#### Scenario: Entitlement requires a real order
- **WHEN** an entitlement is inserted referencing a `source_order_id` that does not exist
- **THEN** the database rejects it by foreign key

#### Scenario: Package items resolve to every product
- **WHEN** `FindPackageItems` is called for a content package containing three products
- **THEN** all three product IDs are returned

#### Scenario: Revoking by order expires only that order's entitlements
- **WHEN** `RevokeEntitlementForOrder` is called for one order
- **THEN** only entitlements whose `source_order_id` matches are expired, and entitlements from other orders remain active

### Requirement: Subscription and order constraint coverage
Database tests SHALL cover the order status lifecycle, the uniqueness constraints on subscriptions and purchase tokens, and the transactional integrity of entitlement granting.

#### Scenario: One subscription row per user
- **WHEN** a second `user_subscriptions` row is inserted for a user who already has one
- **THEN** the database rejects it by unique index

#### Scenario: Purchase token cannot be reused across orders
- **WHEN** a purchase token already recorded against one order is written to a second order
- **THEN** the database rejects it by unique constraint

#### Scenario: Partial grant failure rolls back entirely
- **WHEN** granting a multi-item package fails partway through the transaction
- **THEN** no entitlement from that package remains, and the order is not left marked paid

### Requirement: Migration suite verification
Database tests SHALL verify that the full migration set applies cleanly from an empty database and that repeatable migrations can be re-applied.

#### Scenario: Migrations apply from empty
- **WHEN** the full `db/migrations` set is applied to an empty database
- **THEN** every migration succeeds and the resulting schema matches what the models expect

#### Scenario: Repeatable migrations are idempotent
- **WHEN** a repeatable migration is applied a second time
- **THEN** it succeeds and leaves the same schema and seed state

### Requirement: Query behaviour coverage
Pagination, filtering, sorting and soft-delete behaviour on content list queries SHALL be tested against real data rather than by asserting the SQL string a query builder emits.

#### Scenario: Pagination returns the correct page
- **WHEN** a list query requests the second page of a seeded set
- **THEN** the returned rows are the correct slice and the total count reflects the full filtered set

#### Scenario: Soft-deleted and hidden rows are excluded
- **WHEN** a content list query runs over a set containing soft-deleted and hidden rows
- **THEN** neither appears in the result

#### Scenario: Refactoring the query does not break the test
- **WHEN** a query is rewritten to produce different SQL with identical results
- **THEN** the test still passes, because it asserts returned data rather than emitted SQL


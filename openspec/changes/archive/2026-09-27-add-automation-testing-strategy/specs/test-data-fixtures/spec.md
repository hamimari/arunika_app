## ADDED Requirements

### Requirement: Tests never depend on manually created data
No automated test SHALL depend on data created by hand, on a developer's local database, or on state left behind by another test. Every test SHALL create the data it needs, or rely on a versioned seed set checked into the repository.

#### Scenario: Clean checkout runs the suite
- **WHEN** a developer clones a repository with only Docker installed and runs the test command
- **THEN** the suite provisions its own database, applies migrations and passes, with no manual setup step

#### Scenario: Test order does not affect results
- **WHEN** the suite is run with a randomised or reversed test order
- **THEN** the results are identical to a sequential run

### Requirement: Factories and builders over static fixtures
Test data SHALL be constructed by factory/builder helpers that supply valid defaults and accept explicit overrides for the fields a test cares about. Large static JSON fixture files SHALL NOT be used for domain objects.

#### Scenario: Test states only what it cares about
- **WHEN** a test needs a user with a specific email
- **THEN** it calls a factory with that one override and every other field receives a valid default

#### Scenario: Schema change breaks one factory, not every test
- **WHEN** a migration adds a required column
- **THEN** only the factory constructing that entity needs updating, and tests that never referenced the column keep passing

#### Scenario: Composite entity is built in one call
- **WHEN** a test needs a content package containing three products
- **THEN** a single builder call produces the package, its products and its `premium_package_items` rows

### Requirement: Real migrations are the schema source of truth
Tests requiring a database SHALL apply the repository's actual Flyway migrations from `db/migrations`. A separate or hand-maintained test schema SHALL NOT exist.

#### Scenario: Missing migration fails the test
- **WHEN** code references a column that no migration creates
- **THEN** the database-backed test fails, rather than passing against a mock or a hand-written schema

#### Scenario: Repeatable migrations re-apply cleanly
- **WHEN** the `R__` repeatable migrations are applied twice
- **THEN** both applications succeed and produce the same schema state

### Requirement: Per-test isolation that permits parallel execution
Database-backed tests SHALL be isolated so they can run in parallel: repository tests SHALL run inside a transaction that is rolled back at test end, and API and E2E tests SHALL each receive a fresh database cloned from a migrated template.

#### Scenario: Repository test leaves no trace
- **WHEN** a repository test inserts rows and completes
- **THEN** its transaction is rolled back and no row it created is visible to any other test

#### Scenario: API tests run concurrently
- **WHEN** two API tests marked parallel write to the same table
- **THEN** each writes to its own cloned database and neither observes the other's rows

#### Scenario: Cloning is cheap
- **WHEN** a test requests a fresh database
- **THEN** it is cloned from the already-migrated template rather than re-running the full migration set

### Requirement: Deterministic named seed corpus for end-to-end tests
A versioned seed set SHALL exist for the docker-compose test stack, containing named, stable entities covering the free/paid and entitled/unentitled axes: users with differing access, AR cards and dongeng both free and paid, a content package with multiple items, a subscription package, and an admin. Tests SHALL reference these by named constants, never by literal UUIDs.

#### Scenario: Seed covers access permutations
- **WHEN** the seed set is applied
- **THEN** it contains a user with no entitlements, a user entitled to a single product, and a user with an active subscription

#### Scenario: Tests reference entities by name
- **WHEN** an end-to-end test needs the multi-item content package
- **THEN** it refers to it through a named constant, so a reader can tell which entity is meant without querying the database

#### Scenario: Seed changes are reviewable
- **WHEN** the seed corpus changes
- **THEN** the change appears as a reviewable diff in version control alongside the tests that depend on it

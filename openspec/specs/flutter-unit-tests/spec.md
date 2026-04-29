## ADDED Requirements

### Requirement: BLoC unit test coverage
Every BLoC/Cubit class in the app SHALL have a corresponding unit test file that covers at minimum one happy-path scenario and one error/failure scenario per event or method.

#### Scenario: Happy path event produces expected state
- **WHEN** a BLoC receives a valid event
- **THEN** the bloc emits the expected state sequence as verified by `bloc_test`'s `expect`

#### Scenario: Error path event produces failure state
- **WHEN** a BLoC receives an event and the underlying use-case or repository throws
- **THEN** the bloc emits an error or failure state

### Requirement: Repository unit test coverage
Every repository implementation SHALL have unit tests that mock the remote data source (HTTP client) and verify both successful data mapping and error propagation.

#### Scenario: Repository returns mapped model on success
- **WHEN** the remote data source returns a valid response
- **THEN** the repository parses and returns the corresponding domain model

#### Scenario: Repository propagates exception on failure
- **WHEN** the remote data source throws a network or parse exception
- **THEN** the repository re-throws or wraps the exception as a domain failure

### Requirement: Use-case unit test coverage
Every use-case class SHALL have unit tests mocking its repository dependency and covering at least a success and a failure scenario.

#### Scenario: Use-case returns result on success
- **WHEN** the mocked repository returns a valid value
- **THEN** the use-case returns the expected result

#### Scenario: Use-case propagates failure
- **WHEN** the mocked repository throws or returns a failure
- **THEN** the use-case propagates the failure to the caller

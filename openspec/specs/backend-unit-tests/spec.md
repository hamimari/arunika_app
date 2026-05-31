## ADDED Requirements

### Requirement: Service layer unit test coverage
Every backend service class SHALL have unit tests that mock repository/database dependencies and cover at minimum one happy-path and one failure scenario per public method. This requirement explicitly includes `AnimalService`, `PaymentService`, and `PremiumPackService`, which previously lacked test files. Each of these SHALL have a dedicated `*_test.go` file in the `services/` package.

#### Scenario: Service method returns result on success
- **WHEN** the mocked repository returns a valid entity
- **THEN** the service method returns the expected result

#### Scenario: Service method handles repository failure
- **WHEN** the mocked repository throws or returns an error
- **THEN** the service method propagates or transforms the error appropriately

#### Scenario: AnimalService returns all animals on success
- **WHEN** `GetAllAnimals` is called and the DB mock returns a slice of animal rows
- **THEN** the service returns a slice of `Animal` models with no error

#### Scenario: AnimalService propagates DB error
- **WHEN** `GetAllAnimals` is called and the DB mock returns an error
- **THEN** the service returns a non-nil error and an empty/nil slice

#### Scenario: PaymentService creates payment record on success
- **WHEN** `CreatePayment` is called with valid input and the DB mock inserts successfully
- **THEN** the service returns the created payment with a non-empty ID and no error

#### Scenario: PaymentService returns error on DB failure
- **WHEN** `CreatePayment` is called and the DB mock returns an error
- **THEN** the service returns a non-nil error

#### Scenario: PremiumPackService returns all packs on success
- **WHEN** `GetAllPacks` is called and the DB mock returns pack rows
- **THEN** the service returns the full list with no error

#### Scenario: PremiumPackService propagates error
- **WHEN** `GetAllPacks` is called and the DB mock returns an error
- **THEN** the service returns a non-nil error

### Requirement: Controller layer unit test coverage
Every backend controller/route handler SHALL have unit tests that mock the service layer and verify correct HTTP responses for valid and invalid inputs. This requirement explicitly includes `AnimalHandler`, `AuthHandler`, `BannerHandler`, `CategoryHandler`, `DongengHandler`, `PaymentHandler`, and `UserHandler`, each of which SHALL have at least one happy-path and one error-path test covering each public route.

#### Scenario: Controller returns 200 for valid request
- **WHEN** the mocked service returns a valid result
- **THEN** the controller responds with the appropriate success status and body

#### Scenario: Controller returns error status on service failure
- **WHEN** the mocked service throws a known error
- **THEN** the controller (or error middleware) responds with the correct error status and body

#### Scenario: AnimalHandler GET /animals returns 200 with animal list
- **WHEN** a GET request is made to the animals endpoint and `AnimalService.GetAllAnimals` returns a list
- **THEN** the response status is 200 and the body is a JSON array of animals

#### Scenario: AnimalHandler returns 500 on service error
- **WHEN** a GET request is made to the animals endpoint and `AnimalService.GetAllAnimals` returns an error
- **THEN** the response status is 500

#### Scenario: AuthHandler POST /login returns 200 on valid credentials
- **WHEN** a POST request is made with valid email and password
- **THEN** the response status is 200 and the body contains a token

#### Scenario: AuthHandler POST /login returns 401 on invalid credentials
- **WHEN** a POST request is made with wrong credentials
- **THEN** the response status is 401

### Requirement: Repository / data-access unit test coverage
Every backend repository class SHALL have unit tests that mock the database client and verify both successful data operations and error propagation.

#### Scenario: Repository returns mapped entity on success
- **WHEN** the mocked database client returns a valid record
- **THEN** the repository returns the corresponding domain entity

#### Scenario: Repository propagates database error
- **WHEN** the mocked database client throws
- **THEN** the repository re-throws or wraps the error for the caller

### Requirement: All scenarios covered
Every test suite SHALL include tests for edge cases and boundary conditions (e.g. empty collections, null/undefined fields, concurrent requests) in addition to the standard happy and error paths.

#### Scenario: Edge case — empty result set
- **WHEN** the data source returns an empty list
- **THEN** the service and controller return the correct empty-state response without errors

#### Scenario: Edge case — invalid data types
- **WHEN** a request or data source provides a field with the wrong data type
- **THEN** validation or mapping logic rejects the data and an appropriate error is returned

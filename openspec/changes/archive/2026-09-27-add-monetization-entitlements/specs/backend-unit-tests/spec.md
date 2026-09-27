## MODIFIED Requirements

### Requirement: Service layer unit test coverage
Every backend service class SHALL have unit tests that mock repository/database dependencies and cover at minimum one happy-path and one failure scenario per public method. This requirement explicitly includes `AnimalService`, `PaymentService` (including `CreateSnapTransaction` and `HandleWebhook`, which previously had zero coverage despite being the core payment-settlement logic), `PremiumPackService`, and the new `ProductService`, `OrderService`, and `EntitlementService` introduced for the monetization data model. Each of these SHALL have a dedicated `*_test.go` file in the `services/` package.

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

#### Scenario: PaymentService.CreateSnapTransaction creates an order before calling Midtrans
- **WHEN** `CreateSnapTransaction` is called with a valid user and package
- **THEN** an `orders` row SHALL be created with status `PENDING` before the Midtrans HTTP call is made, and the returned Midtrans order id SHALL be derived from the created order's id

#### Scenario: PaymentService.HandleWebhook grants entitlements exactly once
- **WHEN** `HandleWebhook` is called twice with the same settled notification for a `content`-type package order
- **THEN** the order SHALL transition to `PAID` on the first call, remain `PAID` on the second call, and exactly one set of `user_entitlements` rows SHALL exist (no duplicates)

#### Scenario: PaymentService.HandleWebhook rejects invalid signature
- **WHEN** `HandleWebhook` is called with a notification whose signature does not match
- **THEN** the service SHALL return an error and SHALL NOT modify order, payment, or entitlement state

#### Scenario: PremiumPackService returns all packs on success
- **WHEN** `GetAllPacks` is called and the DB mock returns pack rows
- **THEN** the service returns the full list with no error

#### Scenario: PremiumPackService propagates error
- **WHEN** `GetAllPacks` is called and the DB mock returns an error
- **THEN** the service returns a non-nil error

#### Scenario: PremiumPackService returns packs of all types when no type filter given
- **WHEN** `GetActivePacks` is called with an empty `packType` argument
- **THEN** the service returns active packages of every type, not an empty list

#### Scenario: EntitlementService resolves access from entitlements and subscriptions
- **WHEN** `HasAccess` is called for a user with an active `user_entitlements` row for the product
- **THEN** the service returns `true`; when called for a user with no entitlement and no active subscription, it returns `false`

### Requirement: Controller layer unit test coverage
Every backend controller/route handler SHALL have unit tests that mock the service layer and verify correct HTTP responses for valid and invalid inputs. This requirement explicitly includes `AnimalHandler`, `AuthHandler`, `BannerHandler`, `CategoryHandler`, `DongengHandler`, `PaymentHandler`, `UserHandler`, and the new `OrderHandler`, each of which SHALL have at least one happy-path and one error-path test covering each public route.

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

#### Scenario: OrderHandler GET /orders/:id returns 404 for another user's order
- **WHEN** a GET request is made for an order id owned by a different user
- **THEN** the response status is 404

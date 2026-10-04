## MODIFIED Requirements

### Requirement: BLoC unit test coverage
Every BLoC/Cubit class in the app SHALL have a corresponding unit test file that covers at minimum one happy-path scenario and one error/failure scenario per event or method. This requirement explicitly includes `HomeDongengSectionBloc`, `HomeBannerCubit`, and `PremiumPackCubit`, which previously lacked test files, and the payment screen's order-status polling logic introduced by this change.

#### Scenario: Happy path event produces expected state
- **WHEN** a BLoC receives a valid event
- **THEN** the bloc emits the expected state sequence as verified by `bloc_test`'s `expect`

#### Scenario: Error path event produces failure state
- **WHEN** a BLoC receives an event and the underlying use-case or repository throws
- **THEN** the bloc emits an error or failure state

#### Scenario: HomeDongengSectionBloc loads items on success
- **WHEN** `LoadHomeDongeng` event is dispatched and the repository returns a non-empty list
- **THEN** the bloc emits `HomeDongengLoading` followed by `HomeDongengLoaded` with the item list

#### Scenario: HomeDongengSectionBloc emits error on failure
- **WHEN** `LoadHomeDongeng` event is dispatched and the repository throws
- **THEN** the bloc emits `HomeDongengLoading` followed by `HomeDongengError`

#### Scenario: HomeBannerCubit loads banners on success
- **WHEN** `loadBanners` is called and the repository returns a list of banners
- **THEN** the cubit emits `HomeBannerLoading` followed by `HomeBannerLoaded`

#### Scenario: HomeBannerCubit emits error on failure
- **WHEN** `loadBanners` is called and the repository throws
- **THEN** the cubit emits `HomeBannerLoading` followed by `HomeBannerError`

#### Scenario: PremiumPackCubit loads packs on success
- **WHEN** `loadPacks` is called and the repository returns a list of premium packs
- **THEN** the cubit emits a loaded state containing the pack list

#### Scenario: PremiumPackCubit emits error state on failure
- **WHEN** `loadPacks` is called and the repository throws
- **THEN** the cubit emits an error state

#### Scenario: Order-status polling reaches PAID
- **WHEN** the payment screen's polling logic queries order status and the mocked repository returns `PENDING` then `PAID`
- **THEN** the screen's state transitions to a confirmed/navigable state only after `PAID` is observed, not on the first `PENDING` response

#### Scenario: Order-status polling times out
- **WHEN** the mocked repository returns `PENDING` for every poll until the configured timeout
- **THEN** the screen's state transitions to a timeout/retry state, not a success state

## ADDED Requirements

### Requirement: Order repository unit test coverage
The repository responsible for fetching order status (`GET /orders/:id`) SHALL have unit tests mocking the HTTP client, covering successful status retrieval, a network/parse error, and each terminal status (`PAID`, `FAILED`, `EXPIRED`).

#### Scenario: Repository maps each order status correctly
- **WHEN** the mocked HTTP client returns a response with `status: "PAID"`
- **THEN** the repository returns a domain value representing `PAID`, and analogously for `FAILED`/`EXPIRED`/`PENDING`

#### Scenario: Repository propagates fetch error
- **WHEN** the mocked HTTP client throws a network error
- **THEN** the repository re-throws or wraps it as a domain failure

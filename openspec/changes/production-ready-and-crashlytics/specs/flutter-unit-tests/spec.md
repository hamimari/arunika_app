## MODIFIED Requirements

### Requirement: BLoC unit test coverage
Every BLoC/Cubit class in the app SHALL have a corresponding unit test file that covers at minimum one happy-path scenario and one error/failure scenario per event or method. This requirement explicitly includes `HomeDongengSectionBloc`, `HomeBannerCubit`, and `PremiumPackCubit`, which previously lacked test files.

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

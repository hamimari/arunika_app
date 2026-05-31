## ADDED Requirements

### Requirement: Home banner carousel is data-driven
The system SHALL fetch active banners from `GET /banners` and render them as a horizontally swipeable carousel on the home screen. Each banner SHALL support a `type` field (`promo`, `daily_animal`, `feature`) that controls its visual rendering. When no banners are returned or an error occurs, the home screen SHALL hide the carousel section gracefully without showing an error state to the user.

#### Scenario: Banners load successfully
- **WHEN** the home screen is opened and `GET /banners` returns a non-empty list
- **THEN** the carousel SHALL display the banners in the order returned by the API

#### Scenario: Daily animal banner type rendered
- **WHEN** a banner has `type: "daily_animal"` 
- **THEN** it SHALL render with the animal emoji, name, and fact fields from the banner payload

#### Scenario: Banners are empty or API fails
- **WHEN** `GET /banners` returns an empty list or a network error
- **THEN** the carousel section SHALL be hidden entirely from the home screen

#### Scenario: Backend hides a banner
- **WHEN** a banner's `is_active` flag is set to false in the backend
- **THEN** that banner SHALL NOT appear in the carousel on the next app refresh

### Requirement: Home banner replaces Hewan Hari Ini card
The system SHALL remove the standalone "Hewan Hari Ini" widget from the home screen. Its content SHALL instead be delivered as a banner with `type: "daily_animal"` from the `/banners` API.

#### Scenario: Daily animal shows via banner
- **WHEN** the backend publishes a banner of type `daily_animal`
- **THEN** the home screen SHALL render it inside the banner carousel, not as a separate card

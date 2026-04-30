## ADDED Requirements

### Requirement: Growth record submission
The backend SHALL expose POST `/growth` to store a weight and height record for a child, associated with the logged-in parent's child.

#### Scenario: Valid growth record submitted
- **WHEN** parent sends POST `/growth` with valid weight_kg, height_cm, and recorded_at
- **THEN** system saves the record and returns HTTP 201 with the saved object

#### Scenario: Missing required field
- **WHEN** POST `/growth` is submitted without height_cm
- **THEN** system returns HTTP 400

### Requirement: Growth history retrieval
The backend SHALL expose GET `/growth` returning all growth records for the child of the authenticated parent, ordered by `recorded_at` ascending.

#### Scenario: Parent fetches history
- **WHEN** authenticated parent calls GET `/growth`
- **THEN** response contains all records for their child ordered oldest-first

### Requirement: Growth input form
The Flutter app SHALL provide a form on the Profile page for parents to input the child's current weight and height, with date selection defaulting to today.

#### Scenario: Valid input submitted
- **WHEN** parent enters 15.5 kg and 98 cm and taps Save
- **THEN** app sends POST `/growth` and shows a success message

#### Scenario: Invalid input
- **WHEN** parent leaves the weight field empty
- **THEN** form shows a validation error before making any API call

### Requirement: Growth chart display
The Flutter Profile page SHALL display two line charts (weight over time, height over time) using fl_chart, rendered below the profile info cards.

#### Scenario: Chart with multiple records
- **WHEN** user has 3 or more growth records
- **THEN** both charts render as smooth line graphs with date on the x-axis

#### Scenario: Chart with fewer than 2 records
- **WHEN** user has 0 or 1 growth records
- **THEN** charts are hidden and a "Add more records to see growth chart" message is shown

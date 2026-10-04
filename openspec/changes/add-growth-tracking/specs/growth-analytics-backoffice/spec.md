## ADDED Requirements

### Requirement: Aggregate growth metrics endpoint
`GET /admin/analytics/growth?days=N` SHALL require admin auth and return aggregate counts only, with no child names, dates of birth, measurement values or ids. The fields SHALL be:
- `active_parents`: parents with a session in the window;
- `activated_parents` and `activation_rate`: parents with at least one measurement created in the window;
- `habit_rate`: the share of activated parents with another measurement within 45 days of their first;
- `corrections_per_100`: rows edited after creation plus rows soft-deleted, per 100 rows created in the window;
- `outlier_confirmed_share`: flagged rows as a share of rows created;
- `category_distribution`: counts of children per latest height and weight category.

`days` SHALL default to 30. Results SHALL be cached in Redis for 10 minutes.

#### Scenario: Admin loads metrics
- **WHEN** an admin calls `GET /admin/analytics/growth?days=30`
- **THEN** the response contains the aggregate fields and no per-child data

#### Scenario: Non-admin caller
- **WHEN** a parent token calls the endpoint
- **THEN** the server responds 401 or 403

### Requirement: Tumbuh Kembang analytics card
The backoffice Dashboard SHALL show a "Tumbuh Kembang (30 days)" card. It SHALL show activation (count and rate), habit rate, corrections per 100 and confirmed-outlier share as statistics, and a height and weight category distribution, for the last 30 days. The card SHALL note that retention lift and blocked saves are not tracked yet. No backoffice page SHALL show an individual child's measurements.

#### Scenario: No measurements yet
- **WHEN** no measurement has been created in the range
- **THEN** the card shows zeros and an empty distribution, without errors

#### Scenario: Day range requested
- **WHEN** the card is rendered for a 30-day range
- **THEN** it requests `GET /admin/analytics/growth?days=30`

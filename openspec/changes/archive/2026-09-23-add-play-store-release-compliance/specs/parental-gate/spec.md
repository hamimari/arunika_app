## ADDED Requirements

### Requirement: A parental gate blocks access to purchase entry points
The app SHALL show a parental-gate challenge (e.g. a simple arithmetic question) before allowing navigation into the premium/purchase screens (`/premium`, `/payment`). The gate SHALL only need to be passed once per app session; passing it SHALL allow navigation to those screens for the remainder of the session.

#### Scenario: First attempt to open premium screen this session
- **WHEN** a user navigates to `/premium` for the first time since the app was launched
- **THEN** the parental-gate challenge SHALL be shown before the premium screen is displayed

#### Scenario: Gate already passed this session
- **WHEN** a user has already passed the parental gate once during the current app session and navigates to `/premium` or `/payment` again
- **THEN** the gate SHALL NOT be shown again and the screen SHALL open directly

#### Scenario: Incorrect answer blocks entry
- **WHEN** a user answers the parental-gate challenge incorrectly
- **THEN** the premium/purchase screen SHALL NOT open and the user SHALL remain on the gate

#### Scenario: Gate resets on app restart
- **WHEN** the app is fully closed and reopened
- **THEN** the parental gate SHALL be required again before the next access to `/premium` or `/payment`

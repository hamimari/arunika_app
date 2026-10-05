## ADDED Requirements

### Requirement: Account deletion removes letter progress
Account deletion SHALL hard-delete every `letter_progress` row of the account's children, in the same transaction as the rest of the deletion.

#### Scenario: Parent deletes account
- **WHEN** a parent whose child finished letters A and B deletes their account
- **THEN** no `letter_progress` rows remain for that child

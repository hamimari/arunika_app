## ADDED Requirements

### Requirement: Account deletion removes Angka progress
Account deletion SHALL hard-delete every `angka_sessions` and `angka_level_progress` row of the account's children, in the same transaction as the rest of the deletion.

#### Scenario: Parent deletes account
- **WHEN** a parent whose child completed Level 1 and has a Level 2 session in progress deletes their account
- **THEN** no Angka session or progress rows remain for that child

## ADDED Requirements

### Requirement: Release build targets a compliant Android API level and produces an App Bundle
The Android release build SHALL produce an Android App Bundle (`.aab`) via `flutter build appbundle`, and its `targetSdkVersion` SHALL meet Google Play's minimum target API level requirement in effect at the time of release.

#### Scenario: Release build succeeds and is an app bundle
- **WHEN** `flutter build appbundle` is run for a release build
- **THEN** it SHALL succeed and produce a `.aab` artifact suitable for upload to Play Console

#### Scenario: Target SDK meets Play's minimum
- **WHEN** the release build's `targetSdkVersion` is checked against Play's current minimum target API requirement
- **THEN** it SHALL be at or above that minimum

### Requirement: Data Safety form has a documented source of truth
A `docs/play-store-data-safety.md` document SHALL exist, mapping every data type Arunika actually collects (parent name/email, child name/birthdate, device identifiers, crash diagnostics, purchase history) to the Play Console Data Safety form's categories (collected vs. shared, purpose, optional vs. required, encrypted in transit, user-deletable).

#### Scenario: Data Safety doc reflects actual collection
- **WHEN** `docs/play-store-data-safety.md` is compared against what the app and backend actually collect (as of this change)
- **THEN** every data type actually collected SHALL appear in the document with its Play Console category mapping

### Requirement: Content rating questionnaire has a documented recommendation
A `docs/play-store-content-rating.md` document SHALL exist with recommended answers to Play Console's IARC content rating questionnaire, based on the app's actual content (no violence, no user-generated content or chat, educational content aimed at children).

#### Scenario: Content rating doc exists and matches app content
- **WHEN** `docs/play-store-content-rating.md` is reviewed against the app's actual features
- **THEN** its recommended answers SHALL be consistent with the app having no violence, no user-generated content, no chat, and a children's educational target audience

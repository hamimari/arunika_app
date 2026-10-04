## MODIFIED Requirements
### Requirement: Landing site hosts a public Privacy Policy page
The landing site SHALL have a publicly accessible Privacy Policy page (no login or app install required). It SHALL accurately describe the data Arunika collects, including child profile data (name, birthdate, gender). It SHALL link to the account-deletion request page and to the Terms page. Its content SHALL be identical to the latest version file `legal/privacy/<version>.html`, which is what the app shows. This page's URL is the one submitted as the app's privacy policy in Google Play Console. Every published version file SHALL remain publicly accessible at its versioned URL.

#### Scenario: Visitor reads the privacy policy without the app
- **WHEN** someone visits the landing site's privacy policy page directly
- **THEN** the page SHALL render without requiring login or app installation, and SHALL describe the collection of parent and child data

#### Scenario: Privacy policy links to account deletion
- **WHEN** the privacy policy page is viewed
- **THEN** it SHALL contain a link to the account-deletion request page

#### Scenario: Web and app versions match
- **WHEN** `legal_check.sh` runs
- **THEN** it SHALL fail if `privacy-policy.html` differs from the latest `legal/privacy/` version file

#### Scenario: Old version still retrievable
- **WHEN** a newer privacy version has been published
- **THEN** the older version file SHALL still be served unchanged at its versioned URL

### Requirement: Landing site hosts a public Terms page
The landing site SHALL have a publicly accessible Syarat & Ketentuan page whose content is identical to the latest version file `legal/terms/<version>.html`, which is what the app shows. The page SHALL be linked from the site footer and from the privacy policy page.

#### Scenario: Visitor reads the terms without the app
- **WHEN** someone opens the landing site's terms page directly
- **THEN** the page SHALL render without login and SHALL show the same version as the in-app Syarat & Ketentuan

#### Scenario: Terms page drifts from its version file
- **WHEN** `terms.html` is edited without publishing a new version
- **THEN** `legal_check.sh` SHALL fail

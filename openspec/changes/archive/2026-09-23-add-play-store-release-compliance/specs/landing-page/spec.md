## ADDED Requirements

### Requirement: Landing site hosts a public Privacy Policy page
The landing site SHALL have a publicly accessible Privacy Policy page (no login or app install required) that accurately describes the data Arunika collects, including child profile data (name, birthdate), and links to the account-deletion request page. This page's URL is the one submitted as the app's privacy policy in Google Play Console.

#### Scenario: Visitor reads the privacy policy without the app
- **WHEN** someone visits the landing site's privacy policy page directly
- **THEN** the page SHALL render without requiring login or app installation, and SHALL describe the collection of parent and child data

#### Scenario: Privacy policy links to account deletion
- **WHEN** the privacy policy page is viewed
- **THEN** it SHALL contain a link to the account-deletion request page

### Requirement: Landing site hosts a public account & data deletion request page
The landing site SHALL have a publicly accessible page (no login or app install required) where a user can request deletion of their account and data, satisfying Google Play's requirement for a web-based deletion option in addition to the in-app one.

#### Scenario: Visitor requests deletion from the landing site
- **WHEN** someone visits the landing site's account-deletion page and submits a deletion request (form submission or a documented contact method)
- **THEN** the request SHALL be captured (e.g. sent to a monitored support address or recorded) without requiring the visitor to log in or install the app

#### Scenario: Page states the expected handling time
- **WHEN** the account-deletion page is viewed
- **THEN** it SHALL state how the request will be processed and within what timeframe data will be deleted

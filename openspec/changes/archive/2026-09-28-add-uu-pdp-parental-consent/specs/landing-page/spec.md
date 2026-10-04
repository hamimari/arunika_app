## MODIFIED Requirements

### Requirement: Landing site hosts a public Privacy Policy page
The landing site SHALL have a publicly accessible Privacy Policy page (no login or app install required). It SHALL accurately describe the data Arunika collects, including child profile data (name, birthdate, gender). It SHALL link to the account-deletion request page and to the Terms page. Its content and version SHALL match the in-app Kebijakan Privasi, including the UU PDP disclosures defined in the `parental-consent` capability. This page's URL is the one submitted as the app's privacy policy in Google Play Console.

#### Scenario: Visitor reads the privacy policy without the app
- **WHEN** someone visits the landing site's privacy policy page directly
- **THEN** the page SHALL render without requiring login or app installation, and SHALL describe the collection of parent and child data

#### Scenario: Privacy policy links to account deletion
- **WHEN** the privacy policy page is viewed
- **THEN** it SHALL contain a link to the account-deletion request page

#### Scenario: Web and app versions match
- **WHEN** the privacy policy page is viewed
- **THEN** it SHALL show the same version and effective date as the in-app Kebijakan Privasi

## ADDED Requirements

### Requirement: Landing site hosts a public Terms page
The landing site SHALL have a publicly accessible Syarat & Ketentuan page whose content and version match the in-app Syarat & Ketentuan. The page SHALL be linked from the site footer and from the privacy policy page.

#### Scenario: Visitor reads the terms without the app
- **WHEN** someone opens the landing site's terms page directly
- **THEN** the page SHALL render without login and SHALL show the same version as the in-app Syarat & Ketentuan

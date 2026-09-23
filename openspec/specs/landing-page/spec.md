# landing-page Specification

## Purpose
TBD - created by archiving change add-landing-page-product-showcase. Update Purpose after archive.
## Requirements
### Requirement: Landing page visually matches the app's theme
The landing page SHALL use the app's visual language — orange `#F59E0B` primary accent, cream `#FFFBF5` background, rounded cards (20-32px radius), Poppins typeface — and SHALL be a static site with no build step (plain HTML/CSS/JS).

#### Scenario: Page uses app color tokens
- **WHEN** the landing page is loaded
- **THEN** its primary accent color SHALL be `#F59E0B` and its background SHALL use the `#FFFBF5` cream tone, matching the app's palette

#### Scenario: Page has no build dependency
- **WHEN** the site is deployed
- **THEN** it SHALL be servable as static files (`index.html`, `styles.css`, `script.js`, assets) with no compilation or bundling step required

### Requirement: Landing page shows live membership/bundle products
The landing page SHALL fetch `GET {API_BASE_URL}/premium/packs` on load and render one card per package returned, showing the package's image, name, description, formatted price (`Rp` + thousands separators), and a type/best-value badge. Cards SHALL be rendered in the order returned by the API.

#### Scenario: Active packages render as cards
- **WHEN** `GET /premium/packs` returns 3 active packages
- **THEN** the landing page SHALL render exactly 3 product cards, each showing that package's name, description, price and image

#### Scenario: Best-value package is visually highlighted
- **WHEN** a returned package has `is_best_value: true`
- **THEN** its card SHALL render with a highlighted border and a "Best Value" badge

#### Scenario: Subscription vs content packages are labeled
- **WHEN** a returned package has `type: "subscription"`
- **THEN** its card SHALL show a "Langganan" badge; a `type: "content"` package SHALL show a "Paket Konten" badge instead

### Requirement: Product display degrades gracefully without live data
The landing page SHALL NOT show a blank or broken product section when the API is unreachable, times out, or returns an empty list. It SHALL show a static fallback message instead. A package with a missing `image_url` SHALL render a themed placeholder image instead of a broken image icon; a package with a missing `description` SHALL fall back to displaying its `subtitle`.

#### Scenario: API request fails
- **WHEN** the `GET /premium/packs` request fails or times out
- **THEN** the product section SHALL show a static "available in the app" fallback message instead of an empty or broken section

#### Scenario: Empty package list
- **WHEN** `GET /premium/packs` returns an empty array
- **THEN** the product section SHALL show the same static fallback message

#### Scenario: Package missing an image
- **WHEN** a returned package has `image_url: null`
- **THEN** its card SHALL render a themed placeholder graphic instead of a broken `<img>` element

### Requirement: Products are informational only, not purchasable on the web
Product cards SHALL NOT include a buy, checkout, or add-to-cart control. The page's only purchase-adjacent call to action SHALL remain the existing "get the app" CTA (Play Store / WhatsApp), unchanged in purpose.

#### Scenario: No buy button on product cards
- **WHEN** the product section renders
- **THEN** no card SHALL contain a control that initiates a purchase or payment flow

#### Scenario: Get-the-app CTA remains the only action
- **WHEN** a visitor wants to obtain a package
- **THEN** the only actionable control available to them SHALL be the existing CTA directing them to install/open the app

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


# dongeng-page-image-check Specification

## Purpose
Stops dongeng page images that the landscape reader would crop badly from being saved in the backoffice, and gives a way to audit existing ones.

## Requirements
### Requirement: Backoffice checks a dongeng page image before saving
In the fairy tale page form, when the Image URL is not empty, the backoffice SHALL load the image and check its pixel size. The page SHALL NOT be saved unless the image loads, its width ÷ height is between 1.70 and 2.00 inclusive, and it is at least 1280 px wide. An empty Image URL SHALL skip the check.

#### Scenario: Correctly shaped image is accepted
- **WHEN** the admin enters the URL of a 1408×768 image (ratio 1.83) and saves
- **THEN** the check passes and the page is saved

#### Scenario: 4:3 image is rejected
- **WHEN** the admin enters the URL of a 2400×1792 image (ratio 1.34) and saves
- **THEN** the page is not saved, and the Image URL field shows an error that gives the size (2400×1792) and says the image is too tall for a landscape page and should be cropped to about 16:9

#### Scenario: Too-wide image is rejected
- **WHEN** the image's ratio is above 2.00, for example 3000×1000
- **THEN** the page is not saved and the error says the image is too wide

#### Scenario: Small image is rejected
- **WHEN** the image has the right shape but is narrower than 1280 px, for example 960×540
- **THEN** the page is not saved and the error says the image must be at least 1280 px wide

#### Scenario: Image that can't be loaded is rejected
- **WHEN** the URL returns an error or is not an image
- **THEN** the page is not saved and the error says "Could not load this image — check the URL or your network"

#### Scenario: Empty Image URL
- **WHEN** the Image URL field is left empty
- **THEN** no image check runs and saving behaves as it does today

### Requirement: Page form previews how the image will be cropped
Once the Image URL loads, the page form SHALL show a preview of the image, its pixel size, and the area that a 2:1 landscape phone screen crops away, dimmed.

#### Scenario: Preview shows the cropped band
- **WHEN** a 1408×768 image loads in the form
- **THEN** the preview shows "1408 × 768", and the thin top and bottom strips that a 2:1 screen crops are dimmed

### Requirement: Existing page images can be audited against the same rule
The project SHALL provide a one-off way to list the existing fairy tale page images that fail the check (can't load, wrong shape, or too small), together with the fairy tale title and page number, so that they can be fixed by hand.

#### Scenario: Audit finds the kancil page
- **WHEN** the audit is run against the current data
- **THEN** the page that uses `kancil-1.jpeg` is listed as too tall (2400×1792)


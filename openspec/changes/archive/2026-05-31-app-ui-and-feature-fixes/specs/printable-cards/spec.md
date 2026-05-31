## ADDED Requirements

### Requirement: Backend printable card PDF generation
The backend SHALL expose `GET /ar/printable-pdf?category_id=<uuid>` that returns an A4 PDF file containing AR card images for all cards in the given category. Each card cell SHALL be 75×110 mm. The layout SHALL pack as many cards as possible per page (2 columns × 2 rows = 4 cards per page with 2 mm gutters). Each cell SHALL include the card image centred within the cell and the card title below the image. The response SHALL set `Content-Type: application/pdf` and `Content-Disposition: attachment; filename="kartu-ar.pdf"`.

#### Scenario: PDF generated for a valid category
- **WHEN** a client calls `GET /ar/printable-pdf?category_id=<valid-uuid>`
- **THEN** the server returns HTTP 200 with a valid A4 PDF binary containing card cells for all cards in that category

#### Scenario: Card image fetch failure is handled gracefully
- **WHEN** a card's `file_url` image cannot be fetched within 5 seconds during PDF generation
- **THEN** the card cell is rendered with a grey placeholder rectangle and the card title; the PDF is still returned successfully

#### Scenario: Unknown category returns 404
- **WHEN** a client calls `GET /ar/printable-pdf?category_id=<non-existent-uuid>`
- **THEN** the server returns HTTP 404 with an error message

### Requirement: Flutter printable cards screen download
The printable cards screen SHALL replace the share icon/button with a download icon/button. When tapped, the app SHALL call the backend PDF endpoint for the current category and save or open the returned PDF using the device's native file handler.

#### Scenario: Download icon triggers PDF download
- **WHEN** the user taps the download icon on the printable cards screen
- **THEN** the app fetches the PDF from the backend, saves it to the device's downloads directory, and opens it with the system PDF viewer

#### Scenario: Download failure shows error
- **WHEN** the PDF download fails (network error or server error)
- **THEN** a user-friendly error snackbar is shown and no partial file is saved

# dongeng-categories-backoffice Specification

## Purpose
TBD - created by archiving change add-dongeng-categories. Update Purpose after archive.
## Requirements
### Requirement: Backoffice has a Dongeng Categories management page
The system SHALL have a `/content/dongeng-categories` route in the backoffice that renders a `DongengCategoriesPage` listing all dongeng categories (including hidden ones) in an Ant Design `Table`, mirroring the existing `ArCardCategoriesPage`. The page SHALL be accessible from the sidebar "Content" menu group as a "Dongeng Categories" item.

#### Scenario: Page accessible from menu
- **WHEN** an admin clicks "Dongeng Categories" under Content in the sidebar
- **THEN** the browser SHALL navigate to `/content/dongeng-categories` and the table SHALL load all dongeng categories

### Requirement: Admin can create, edit, delete, and hide a dongeng category
The `DongengCategoriesPage` SHALL provide an "Add" action opening a modal form (Name, Image URL) calling `POST /admin/content/dongeng-categories`; an "Edit" action per row pre-filling the same form and calling `PUT /admin/content/dongeng-categories/:id`; a "Delete" action per row, guarded by a confirmation dialog, calling `DELETE /admin/content/dongeng-categories/:id`; and a visibility toggle per row calling `PATCH /admin/content/dongeng-categories/:id/visibility`.

#### Scenario: Category created
- **WHEN** the admin fills the Add form and submits
- **THEN** `POST /admin/content/dongeng-categories` SHALL be called and the new category SHALL appear in the table

#### Scenario: Category updated
- **WHEN** the admin edits a row and submits
- **THEN** `PUT /admin/content/dongeng-categories/:id` SHALL be called and the table SHALL reflect the new values

#### Scenario: Category deleted after confirmation
- **WHEN** the admin confirms deletion of a row
- **THEN** `DELETE /admin/content/dongeng-categories/:id` SHALL be called and the row SHALL disappear from the table

### Requirement: Admin can link a dongeng entry to a category and sub-category
The Fairy Tales edit/create form SHALL provide "Category" and, when the selected category has children, "Sub-category" `Select` fields, populated from the dongeng categories API, bound to the dongeng's `dongeng_category_id`/`dongeng_sub_category_id`.

#### Scenario: Category assigned to a dongeng
- **WHEN** the admin selects a category in the Fairy Tales form and saves
- **THEN** the dongeng's `dongeng_category_id` SHALL be updated to match the selection

#### Scenario: Sub-category options depend on the selected category
- **WHEN** the admin selects a top-level category that has sub-categories
- **THEN** the Sub-category field SHALL appear, offering only that category's children


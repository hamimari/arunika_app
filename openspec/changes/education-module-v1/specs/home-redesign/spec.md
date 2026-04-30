## ADDED Requirements

### Requirement: Primary feature navigation cards
The Flutter home screen SHALL display three large, icon-based navigation cards as the primary content: Dongeng, Tracing, and Counting.

#### Scenario: Navigation cards displayed
- **WHEN** user opens the home screen
- **THEN** three cards (Dongeng, Tracing, Counting) are visible in the top section

#### Scenario: Tapping Tracing card
- **WHEN** user taps the Tracing card
- **THEN** app navigates to the tracing exercise list screen

### Requirement: "Continue Learning" section
The home screen SHALL display a "Continue Learning" section showing the user's most recently accessed tracing or counting exercise.

#### Scenario: Recent activity present
- **WHEN** user has previous tracing or counting activity
- **THEN** the section shows the last accessed item with a "Continue" button

#### Scenario: No prior activity
- **WHEN** user has no prior activity
- **THEN** the section is hidden or shows a "Start Learning" prompt

### Requirement: Child-friendly layout principles
The home screen SHALL use large tap targets (minimum 56 dp height), minimal text, and bright Arunika orange/warm colour palette consistent with the existing design system.

#### Scenario: Layout on small screen
- **WHEN** home screen is rendered on a 360 dp width device
- **THEN** all navigation cards are fully visible without horizontal scrolling

## MODIFIED Requirements

### Requirement: Home page greeting
The home page greeting section SHALL remain at the top of the screen and continue to show the child's name, but SHALL be visually integrated with the new feature card layout rather than standing alone above the story list.

#### Scenario: Greeting with child name
- **WHEN** user opens home screen with a logged-in profile
- **THEN** greeting text shows the child's name in the header area above the feature cards

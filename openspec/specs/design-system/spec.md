## ADDED Requirements

### Requirement: Color palette constants
The app SHALL define a shared color palette in `lib/constants/app_colors.dart` with: primary orange (#FF6B35 or similar), cream/warm white background, deep brown for headings, accent gold, muted blue, and semantic colors (success green, lock grey).

#### Scenario: Colors used consistently
- **WHEN** any screen widget references a brand color
- **THEN** it uses the constant from `AppColors` rather than a hardcoded hex value

### Requirement: Typography constants
The app SHALL define text styles in `lib/constants/app_text_styles.dart` using Poppins or Nunito as the primary font, with sizes for headings (24sp), subheadings (18sp), body (14sp), and captions (12sp), all with rounded feel.

#### Scenario: Typography applied app-wide
- **WHEN** the app renders any text widget
- **THEN** the font family matches the defined typography constants

### Requirement: Rounded corners and soft shadows
All card widgets and buttons SHALL use `BorderRadius.circular(16)` or larger, and cards SHALL apply a soft box shadow (color: black 8% opacity, blur 12, offset y:4).

#### Scenario: Card corners are rounded
- **WHEN** any card or button is rendered
- **THEN** corners are visibly rounded with radius ≥ 16dp

### Requirement: Large touch targets
All interactive elements (buttons, list rows, tab icons) SHALL have a minimum touch target size of 48×48dp.

#### Scenario: Buttons meet minimum size
- **WHEN** any tappable widget is rendered
- **THEN** its hit area is at least 48dp in both dimensions

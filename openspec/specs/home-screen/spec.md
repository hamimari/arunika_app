## MODIFIED Requirements

### Requirement: Dongeng populer lock state for authenticated users
The home screen SHALL display a semi-transparent grey overlay and a lock icon badge on paid dongeng cards in the "Dongeng Populer" section when the user is logged in. When the user is not logged in, no overlay or lock badge is shown (guest users see all content without lock indication).

#### Scenario: Logged-in user sees lock overlay on paid dongeng
- **WHEN** the user is logged in and a dongeng card's `isFree` is false
- **THEN** the card image has a semi-transparent grey overlay (`Colors.black` at 35% opacity) and a lock icon badge at the bottom-right

#### Scenario: Guest user sees no lock overlay
- **WHEN** the user is not logged in
- **THEN** no grey overlay or lock badge is shown on any dongeng card

#### Scenario: Free dongeng has no lock overlay regardless of auth state
- **WHEN** a dongeng card's `isFree` is true
- **THEN** no grey overlay or lock badge is displayed

## MODIFIED Requirements

### Requirement: AR card category images on home
The home screen AR category section SHALL display each category using its `imageUrl` image (via `Image.network`) instead of an emoji. If `imageUrl` is empty or fails to load, the category emoji text SHALL be shown as a fallback.

#### Scenario: Category with imageUrl shows image
- **WHEN** an AR card category has a non-empty `imageUrl`
- **THEN** the category rail item displays the network image, not the emoji

#### Scenario: Category without imageUrl falls back to emoji
- **WHEN** an AR card category has an empty `imageUrl`
- **THEN** the category rail item displays the emoji text

## ADDED Requirements

### Requirement: Dongeng pages turn with a page curl that follows the finger
The dongeng reader SHALL turn pages with a book-style page curl. During a horizontal drag, the current page's image SHALL curl along a fold that follows the finger, and the neighbouring page's image SHALL show underneath.

#### Scenario: Swipe forward to the next page
- **WHEN** the reader is on page 2 of 5 and the user drags right-to-left past 35% of the screen width and releases
- **THEN** the curl completes, page 3 is shown, and the page counter reads "3 / 5"

#### Scenario: Swipe back to the previous page
- **WHEN** the reader is on page 3 and the user drags left-to-right past 35% of the screen width and releases
- **THEN** page 2 curls back in over page 3 and page 2 is shown

#### Scenario: Short drag springs back
- **WHEN** the user drags less than 35% of the width and releases with a fling speed below 800 px/s
- **THEN** the page springs back flat and the current page does not change

#### Scenario: Quick fling turns the page
- **WHEN** the user flings in the turn direction at 800 px/s or faster, even after a short drag
- **THEN** the turn completes

#### Scenario: No turn past the ends
- **WHEN** the reader is on the first page and the user drags left-to-right, or it is on the last page and the user drags right-to-left
- **THEN** no curl starts and the page does not change

### Requirement: Page changes land once, when the turn completes
The reader SHALL change the current page only when a turn completes. The subtitle, the page counter and the audio stop SHALL all update at that point, and a turn that springs back SHALL change none of them. While a turn is animating, further drags and arrow taps SHALL be ignored.

#### Scenario: Audio stops only on a completed turn
- **WHEN** a page's audio is playing and the user starts a drag, then releases it so the page springs back
- **THEN** the audio keeps playing and the subtitle is unchanged

#### Scenario: Input during a turn is ignored
- **WHEN** the user taps the next arrow twice quickly
- **THEN** exactly one page is turned

### Requirement: Arrow buttons play the same curl
The previous and next arrow buttons SHALL turn the page with the same curl animation, lasting about 450 ms. They SHALL keep their existing safe-area placement and enabled or disabled state.

#### Scenario: Next arrow curls the page
- **WHEN** the user taps the next arrow on page 1 of 3
- **THEN** page 1 curls away from the bottom-right corner and page 2 is shown

### Requirement: Overlays stay fixed while pages turn
The title bar, arrows, subtitle panel and controls bar SHALL stay above the curl and SHALL NOT move with it. A drag that starts on one of these controls SHALL NOT start a turn.

#### Scenario: Subtitle stays readable during a drag
- **WHEN** the user is midway through dragging a page
- **THEN** the subtitle panel and controls bar are still shown in place above the curling image

### Requirement: Neighbouring pages are ready before they are revealed
The reader SHALL precache the images of the pages before and after the current page, so that the page shown under the fold is the picture and not a loading spinner.

#### Scenario: Page underneath is already drawn
- **WHEN** the current page has loaded and the user starts dragging to the next page
- **THEN** the next page's image, not a spinner, shows under the fold

### Requirement: Reduced motion keeps the cross-fade
When the platform asks for reduced motion (`MediaQuery.disableAnimations`), the reader SHALL change pages with the existing cross-fade instead of the curl. Swipes and arrows SHALL still change the page.

#### Scenario: Reduce motion is on
- **WHEN** reduce motion is on and the user swipes right-to-left past the threshold
- **THEN** the next page is shown with a cross-fade and no curl is drawn

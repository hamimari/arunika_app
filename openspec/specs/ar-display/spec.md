## Requirements

### Requirement: AR model displays automatically after QR scan
After a QR code is successfully scanned and the model URL is resolved, the AR session SHALL place the 3D model on the first detected upward-facing horizontal plane without requiring any user interaction.

#### Scenario: Model placed on first plane detection
- **WHEN** the AR session detects the first upward-facing horizontal plane after navigating to the AR screen
- **THEN** the system SHALL automatically anchor and display the 3D model centered on that plane

#### Scenario: No double placement
- **WHEN** the AR session detects additional planes after the model has already been placed
- **THEN** the system SHALL NOT place additional copies of the model

#### Scenario: Placement hint shown before detection
- **WHEN** the AR screen is active and no horizontal plane has been detected yet
- **THEN** the system SHALL display a visual hint (e.g., overlay text or animated indicator) prompting the user to point the camera at a flat surface

### Requirement: AR model entrance zoom-in animation
When the AR model is first placed, the system SHALL animate the model scaling from zero to its target size with a smooth entrance animation.

#### Scenario: Entrance animation plays on placement
- **WHEN** the AR model anchor is created and the model is placed for the first time
- **THEN** the model SHALL animate from scale 0 to full scale over approximately 600ms using an elastic-out easing curve

#### Scenario: Animation completes before gestures are active
- **WHEN** the entrance animation is in progress
- **THEN** gesture inputs (pinch/rotate) SHALL be ignored until the animation completes

### Requirement: Free rotation of AR model via drag gesture
The placed AR model SHALL support free Y-axis rotation via a single-finger horizontal drag gesture.

#### Scenario: Horizontal drag rotates model
- **WHEN** the user performs a single-finger horizontal drag on the AR view while a model is placed
- **THEN** the model SHALL rotate around its Y axis proportional to the drag distance

#### Scenario: No rotation without placed model
- **WHEN** the user drags on the AR view before a model has been placed
- **THEN** the system SHALL ignore the drag gesture

### Requirement: Pinch-to-zoom on AR model
The placed AR model SHALL support scale changes via a two-finger pinch gesture.

#### Scenario: Pinch-in shrinks model
- **WHEN** the user performs a pinch-in gesture on the AR view while a model is placed
- **THEN** the model SHALL scale down, with a minimum scale floor preventing it from disappearing

#### Scenario: Pinch-out enlarges model
- **WHEN** the user performs a pinch-out gesture on the AR view while a model is placed
- **THEN** the model SHALL scale up, with a maximum scale ceiling preventing unbounded growth

#### Scenario: Scale is clamped within bounds
- **WHEN** the user pinches beyond the minimum or maximum scale boundary
- **THEN** the model scale SHALL be clamped to the boundary value and SHALL NOT exceed it

### Requirement: Gesture updates applied without excessive jank
Transform updates (scale, rotation) SHALL be applied with a maximum frame update frequency such that visible jank or node flickering is minimized.

#### Scenario: Gesture debounce prevents rapid node recreation
- **WHEN** the user performs a continuous pinch or drag gesture
- **THEN** node transform updates SHALL be throttled to no more than once per 30ms to prevent excessive ARNode recreation overhead

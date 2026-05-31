## ADDED Requirements

### Requirement: Scan screen camera viewfinder
The scan screen SHALL display a full-screen camera viewfinder with an animated card-shaped scan guide overlay and a help (?) and flashlight icon.

#### Scenario: Camera viewfinder is active
- **WHEN** the user opens the Scan screen
- **THEN** the camera feed is displayed with an animated scan frame overlay

### Requirement: AR experience screen
After a successful scan, the app SHALL display the AR experience screen showing the 3D animal model in AR with action buttons: Info, Suara, Tari, Makan.

#### Scenario: AR model appears after scan
- **WHEN** a valid AR card is scanned
- **THEN** the 3D animal appears in AR with an idle animation and the action buttons are shown

#### Scenario: Action buttons trigger interactions
- **WHEN** the user taps "Tari" or "Makan"
- **THEN** the corresponding animal animation plays

### Requirement: Fun fact overlay after interaction
After the user interacts with the AR animal, the app SHALL display a "Tahukah kamu?" fun fact overlay card with educational text and a sound button.

#### Scenario: Fun fact card displayed
- **WHEN** the user taps the AR animal
- **THEN** a fun fact overlay appears with an educational fact about the animal

### Requirement: Reward screen after AR session
After completing an AR interaction, the app SHALL display a reward screen showing "+10 ⭐" stars earned and a "Lihat Koleksiku" button.

#### Scenario: Reward screen shown
- **WHEN** the AR session ends (animal successfully interacted with)
- **THEN** a celebration reward screen shows stars earned and a button to view the collection

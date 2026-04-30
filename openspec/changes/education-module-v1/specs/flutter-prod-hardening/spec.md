## ADDED Requirements

### Requirement: AppRouter routes for new screens
The AppRouter SHALL include named routes for all new education module screens: tracing list, tracing exercise, counting list, counting exercise, badge gallery, notification list, growth tracking, and payment WebView.

#### Scenario: Navigate to tracing list
- **WHEN** user taps the Tracing card on the home screen
- **THEN** go_router navigates to `/tracing` without pushing a full-screen replacement

#### Scenario: Navigate to notification list
- **WHEN** user taps the notification bell icon
- **THEN** go_router navigates to `/notifications`

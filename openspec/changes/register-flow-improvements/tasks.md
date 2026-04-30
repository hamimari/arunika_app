## 1. Branch Setup

- [x] 1.1 Create feature branch `feature/register-flow-improvements` on Flutter repo
- [x] 1.2 Create feature branch `feature/register-flow-improvements` on backend repo

## 2. Fix Back Navigation on Register Screen

- [x] 2.1 In `signup_screen.dart`, replace the default `BackButton` with an explicit `IconButton` that calls `context.go('/signin')` on press
- [x] 2.2 Verify tapping back on `/signup` navigates to `/signin` without exiting the app

## 3. Redesign Terms & Conditions Screen

- [x] 3.1 Add a branded header section to `terms_and_condition_screen.dart` (logo/icon, title, last-updated date)
- [x] 3.2 Wrap each TnC section in a styled `Card` with a section title and body text using proper typography hierarchy
- [x] 3.3 Add a sticky bottom bar or footer with an "Saya Mengerti" acknowledge button

## 4. Redesign Privacy Policy Screen

- [x] 4.1 Apply the same branded header and card-section layout to `privacy_policy_screen.dart` (mirror TnC structure)
- [x] 4.2 Ensure consistent typography, padding, and color usage between TnC and Privacy Policy screens

## 5. Improve Register Form UI

- [x] 5.1 Add `prefixIcon` to each field in `signup_screen.dart` (person icon for name, email icon, phone icon, location icons, lock icon for password)
- [x] 5.2 Reorder fields: Name → Email → Phone → City → Address → Password
- [x] 5.3 Add a `tncAccepted` boolean field to `SignupBloc` / `SignupState`
- [x] 5.4 Add a TnC checkbox row above the submit button ("Saya setuju dengan Syarat & Ketentuan dan Kebijakan Privasi" with tappable links)
- [x] 5.5 Disable the submit button when `tncAccepted` is false
- [x] 5.6 Add `TncAcceptedChanged` event to `SignupEvent` and handle it in `SignupBloc`

## 6. Congratulations Modal on Successful Registration

- [x] 6.1 Create `lib/presentation/screens/widgets/registration_success_dialog.dart` with a modal widget (icon, title "Selamat Bergabung!", message, primary CTA button)
- [x] 6.2 In the `SignupBloc` listener (or `BlocListener` in `child_signup_screen.dart`), detect registration success state and call `RegistrationSuccessDialog.show(context)`
- [x] 6.3 Set `barrierDismissible: false` so the modal cannot be dismissed by tapping outside
- [x] 6.4 On CTA button tap inside the modal, dismiss dialog and navigate to `/parent-signup-success` or `/home`

## 7. Verification

- [x] 7.1 Run `flutter analyze` on all modified files and resolve any errors
- [x] 7.2 Manually test the full registration flow: back nav → form fill → TnC checkbox → submit → modal → next screen
- [x] 7.3 Manually test TnC and Privacy Policy screens for visual correctness on both small and large screens

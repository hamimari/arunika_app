## Why

The onboarding flow (registration + forgot password) has several UX and security issues that create friction and risk for users. The register back navigation is broken, the legal pages are unpolished, the form lacks clarity, there is no success feedback after registration, and the forgot/reset password flow has both UX gaps and concrete security vulnerabilities. These issues reduce trust, increase drop-off, and expose user accounts to unnecessary risk.

## What Changes

**Registration flow:**
- Fix back navigation on the register/signup screen so users can return to the login screen
- Redesign the Terms & Conditions (`terms_and_condition_screen.dart`) and Privacy Policy (`privacy_policy_screen.dart`) pages to be elegant and professional
- Redesign the register form UI (`signup_screen.dart`) for improved clarity, usability, and visual cleanliness (field icons, logical ordering, TnC checkbox)
- Add a congratulations modal/dialog on successful registration

**Forgot password flow — UX:**
- `forgot_password_screen.dart`: add email format validation before submitting, add loading state on button, replace success message shown via `AppErrorSheet` (semantically wrong — it's an error widget) with a proper success state or dialog
- `reset_password.html`: translate labels to Indonesian (consistent with app), add password strength indicator, add redirect to app deep link after success

**Forgot password flow — Security:**
- Backend `ForgotPassword`: fix user enumeration vulnerability — currently returns `"user not found"` error, which lets attackers probe which emails are registered; MUST always return success regardless of whether the email exists
- `reset_password.html`: remove `console.log(token)` (leaks token to browser console/DevTools)
- `reset_password.html`: replace hardcoded `http://localhost:8080` API URL with environment-aware config
- `reset_password.html`: send token in request body (already done via `?token=` query param in POST — move to body or keep as query param but document the decision)

## Capabilities

### New Capabilities
- `register-success-modal`: Congratulations pop-up modal shown to users upon successful registration, confirming account creation and guiding next steps
- `reset-password-page`: Improved reset password web page with proper UI, Indonesian labels, password strength indicator, and no token leakage

### Modified Capabilities
- (none — existing capability specs unchanged; security fix is a backend behavior change with no spec-level requirement previously defined)

## Impact

- Flutter: `lib/presentation/screens/signup/` — back nav, form redesign, success modal
- Flutter: `lib/presentation/screens/forgotpassword/forgot_password_screen.dart` — email validation, loading state, success feedback fix
- Flutter: `lib/presentation/navigation/app_router.dart` — back navigation fix
- Web: `arunika/reset_password.html` — UI/UX improvements, security fixes
- Backend: `arunika backend/services/auth_service.go` — `ForgotPassword` user enumeration fix
- No breaking API contract changes

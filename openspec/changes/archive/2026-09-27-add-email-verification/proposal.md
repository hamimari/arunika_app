# Change: Non-blocking email verification

## Why

Arunika never verifies that a registrant owns the email address they sign up with. `POST /auth/signup` creates the account and issues tokens immediately, with no confirmation step anywhere in the flow.

There is OTP scaffolding, but it is **inert on every layer**, and its existence is actively misleading:

- `SendOTPEmail` generates a code and writes it to Redis under `otp:<email>` — and **nothing in the codebase ever reads that key back**. The only `redis.Get` in the repo is the analytics cache (`services/admin_analytics_service.go:35`).
- There is no verify-OTP route in `routes/router.go`.
- The Flutter `OtpBloc` handles `VerifyButtonPressed` by emitting `NavigateToChildRegistrationPage()` **without comparing the entered code to anything**.
- The app never calls `/auth/send-otp` (no such entry in `lib/constants/api_paths.dart`) and never navigates to the `/otp` route.

So the product presents a verification step it does not perform. This was discovered while auditing an unrelated finding: OTPs were generated with `math/rand` seeded from the wall clock, which looked like a serious predictability bug until it turned out the codes gated nothing at all. That near-miss is the clearest argument for removing the scaffolding rather than leaving it to imply a control that does not exist.

Two consequences today:

1. An account can be registered against an email address the registrant does not own — including someone else's.
2. **Password reset delivers to an unverified address.** `ForgotPassword` emails a reset link to whatever is on the account, which is the one place unverified email genuinely matters.

The obvious fix — require verification before registration completes — introduces a worse failure than the one it solves: it puts SMTP, a third-party dependency, on the critical path of account creation, so any mail outage becomes a total signup outage. This change therefore verifies email **without ever blocking registration**.

## What Changes

- **Schema**: add `email_verified BOOLEAN NOT NULL DEFAULT false` to `parents`, and a `email_verification_tokens` table mirroring `password_reset_tokens` (hashed token, `user_id`, `expires_at`).
- **Existing accounts are grandfathered as verified** in the same migration. They predate the feature; marking them unverified would immediately gate password-reset delivery for the entire live user base — locking existing users out of account recovery to fix a problem they do not have. **BREAKING for the security model**: verification is only ever enforced for accounts created after this change ships.
- **Signup stays non-blocking**: `POST /auth/signup` continues to create the account and issue tokens exactly as today. The verification email is dispatched best-effort and asynchronously, following the `sendNotificationAsync` pattern — failures are logged with `user_id`, never propagated to the caller.
- **New endpoints**: `GET /auth/verify-email?token=` consumes a token and renders a confirmation page (mirroring the existing `GET /reset-password` server-rendered page); `POST /auth/resend-verification` re-issues one, rate-limited via the existing `RateLimitMiddleware`.
- **Verification by link, not by code** — reusing the `PasswordResetToken` mechanism (SHA-256-hashed at rest, expiring, prior tokens invalidated on reissue) rather than building OTP verification, replay protection and rate limiting from scratch. See `design.md`.
- **Gating is deliberately narrow**: only password-reset delivery requires a verified address. Login, content access, AR cards, dongeng and **all purchase and entitlement flows remain completely unaffected** — entitlements key off `user_id`, never email, so a parent who never verifies still receives everything they paid for.
- **Verification state is exposed** on the user profile response so the app can surface it.
- **Flutter**: a dismissible banner on the home screen for unverified accounts, with a rate-limited "Resend" action. The app never blocks navigation, content or purchases on verification state.
- **Removes the dead OTP scaffolding**: `generateOtp`, `saveOtpToRedis`, `SendOTPEmail`, `AuthService.SendOtp`, `AuthHandler.SendOtp`, the `POST /auth/send-otp` route, `templates/otp_email.html`, and on the app side `OtpBloc`/`OtpScreen`/`OtpEvent`/`OtpState` and the unreachable `/otp` route. None of it is reachable today.

## Capabilities

### New Capabilities
- `email-verification`: backend token lifecycle, non-blocking signup dispatch, consumption and resend endpoints, the password-reset gate, and grandfathering of pre-existing accounts
- `email-verification-app`: how the Flutter app surfaces unverified state and offers resend, and what it must never gate on it

## Impact

- **New backend migration**: `V55__add_email_verification.sql` (adds `parents.email_verified`, creates `email_verification_tokens`, backfills existing rows to `true`)
- **New backend files**: `models/email_verification_token.go`, `templates/verification_email.html`, `templates/email_verified.html`
- **Changed backend**: `services/auth_service.go` (issue/consume/resend, reset gate), `services/email_service.go` (send verification email; delete `generateOtp`/`saveOtpToRedis`/`SendOTPEmail`), `handlers/auth_handler.go` (two new handlers, delete `SendOtp`), `routes/router.go` (two routes added, one removed), `services/user_service.go` (expose `email_verified`)
- **Changed app**: `lib/data/models/response/*` (carry `email_verified`), a new verification banner widget, `lib/presentation/screens/home/*` (host the banner), `lib/data/api/auth_api.dart` + `lib/constants/api_paths.dart` (resend endpoint), deletion of `lib/presentation/screens/otp/*` and its route in `lib/presentation/navigation/app_router.dart`
- **No change to**: purchase, entitlement, AR, dongeng or admin flows
- **Depends on**: nothing. Independent of `add-automation-testing-strategy` and `add-monetization-entitlements`, though it closes follow-up **F7** recorded in the former.

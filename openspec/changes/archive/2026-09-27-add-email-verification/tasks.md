# Tasks: Non-blocking email verification

Ordered so that each stage is independently shippable and leaves every suite green. The password-reset gate is deliberately **last** — enabling it before users can verify would strand anyone who signed up in between.

---

## 1. Schema

- [x] 1.1 Add `db/migrations/V55__add_email_verification.sql`: add `parents.email_verified BOOLEAN NOT NULL DEFAULT false`; create `email_verification_tokens` (`id`, `user_id` FK → `parents(id)` indexed, `token` unique, `expires_at`, `created_at`/`updated_at`) mirroring `password_reset_tokens`
- [x] 1.2 In the same migration, after the column exists, `UPDATE parents SET email_verified = true` to grandfather pre-existing accounts (design D4) — with a comment stating this is why the guarantee is forward-looking
- [x] 1.3 Add `models/email_verification_token.go` mirroring `models/password_reset_token.go`, including the doc comment explaining that only a hash is stored
- [x] 1.4 Add `EmailVerified bool` to `models.Parent`
- [x] 1.5 Verify the migration applies cleanly from empty and that the backfill runs after the column is added

## 2. Token lifecycle

- [x] 2.1 Generalise `utils.HashResetToken` into a shared token hash helper (or add a sibling), keeping the existing reset behaviour byte-identical
- [x] 2.2 Add `AuthService.IssueEmailVerificationToken(user)` — generate via `uuid.NewString()` (crypto/rand-backed, as the reset flow already does), store the hash with a **24h** expiry (design D2), delete any prior tokens for that user
- [x] 2.3 Add `AuthService.ConsumeEmailVerificationToken(token)` — hash, look up, reject expired/unknown, set `email_verified = true`, delete the token so it is single-use
- [x] 2.4 Unit tests: hash-not-plaintext stored, single-use, expiry rejection, unknown-token rejection, reissue invalidates prior, already-verified is idempotent

## 3. Sending

- [x] 3.1 Add `templates/verification_email.html` with the verification link
- [x] 3.2 Add `SendVerificationEmail(to, link)` in `services/email_service.go`, reusing the `SendGenericEmail` gomail path (**not** the legacy `utils.SendEmail`, which reads an `SMTP_PASSWORD` variable set nowhere — see the comment in `ForgotPassword`)
- [x] 3.3 Dispatch from `AuthHandler.SignUp` asynchronously and best-effort, following the `sendNotificationAsync` pattern in `handlers/payment_handler.go`: log failure with `user_id`, never propagate
- [x] 3.4 Test: signup still returns its normal success response, and the account is still created, when the mail path errors
- [x] 3.5 Test: signup response shape is unchanged from before this change

## 4. Endpoints

- [x] 4.1 Add `templates/email_verified.html` rendering all three outcomes — verified, already verified, expired/invalid — with a resend affordance on the expired case; self-contained, no third-party resources, and it must not echo the token (design D2, D6)
- [x] 4.2 Add `GET /auth/verify-email?token=` → `AuthHandler.VerifyEmail`, rendering that page, mirroring the existing `GET /reset-password` page pattern
- [x] 4.3 Add `POST /auth/resend-verification` behind `JWTAuthMiddleware` + `RateLimitMiddleware(rdb, "resend-verification", 5, 15*time.Minute)`, matching the `forgot-password` limit
- [x] 4.4 Resend on an already-verified account is a no-op that issues no token
- [x] 4.5 Register both routes in `routes/router.go`; update `routes/router_test.go` (99.5% covered — it will fail until updated)
- [x] 4.6 Handler tests: valid token verifies; second use rejected; expired rejected; unknown rejected; resend rate limit returns the limited status

## 5. Expose state to clients

- [x] 5.1 Include `email_verified` in the authenticated profile response from `UserService.GetUserByID`
- [x] 5.2 Test the field is present and correct for both verified and unverified accounts
- [x] 5.3 Add `email_verified` to the app's user response model and its `fromJson`
- [ ] 5.4 *(deferred at archive — optional follow-up, not a bug)* **Consider** surfacing verification state read-only on the backoffice user detail page — it is the first thing support will ask when a reset is refused (design open question)

## 6. App prompt

- [x] 6.1 Add `ApiPaths.resendVerification` and the client method in `lib/data/api/auth_api.dart` + repository
- [x] 6.2 Add a dismissible verification banner widget stating that password recovery requires a verified email, with a resend action
- [x] 6.3 Host it on the home screen, shown only when the profile reports unverified
- [x] 6.4 Distinguish resend outcomes: success, rate-limited (explain, don't show a generic error), and failure (keep the action available)
- [x] 6.5 Widget tests: shown when unverified, absent when verified, dismissible, and each of the three resend outcomes
- [x] 6.6 Test that navigation, content and purchase flows are unaffected by verification state

## 7. Remove the dead OTP scaffolding

- [x] 7.1 Backend: delete `generateOtp`, `saveOtpToRedis`, `SendOTPEmail`, `AuthService.SendOtp`, `AuthHandler.SendOtp`, the `POST /auth/send-otp` route and `templates/otp_email.html`
- [x] 7.2 Delete the now-orphaned OTP tests in `services/email_service_test.go` (`TestGenerateOtp_*`)
- [x] 7.3 App: delete `lib/presentation/screens/otp/` and its `/otp` route in `lib/presentation/navigation/app_router.dart`; delete `test/presentation/screens/otp/otp_bloc_test.dart`
- [x] 7.4 Confirm nothing references the removed symbols — all of it is provably unreachable today, so failures here are compile errors, not behaviour changes
- [x] 7.5 Note the coverage-baseline movement: removing untested-but-counted app code and tested backend code shifts both ratchets; re-record with `make coverage-baseline` in each repo

## 8. Enable the password-reset gate (ship last)

- [x] 8.1 In `AuthService.ForgotPassword`, return without sending when the account is unverified — creating no reset token
- [x] 8.2 **Preserve non-enumeration.** The unverified path must be indistinguishable from the unknown-email path and the verified path in status and body. `TestForgotPassword_UnknownEmail_ReturnsNilWithoutEnumeration` must still pass, and a new test must assert the unverified response matches the unknown-email response exactly. This is the easiest thing in the change to get wrong (design D3)
- [ ] 8.3 *(deferred at archive — optional follow-up, not a bug)* **Consider** putting the gate behind `app_feature_flags` so it can be switched off without a deploy — it is the only user-blocking behaviour here (design open question)
- [x] 8.4 Test: verified account still receives a reset link; unverified account receives none and gets no reset token row

## 9. Validation

- [x] 9.1 `go test ./...` green; `golangci-lint run` reports 0 issues
- [x] 9.2 `flutter test` and `flutter analyze --no-fatal-infos` green
- [x] 9.3 Coverage ratchets re-recorded in both repos and no unintended regression
- [ ] 9.4 *(not performed at archive — needs a real mail provider; do before release)* Manual: register → receive email → click link → confirmation page → banner disappears on next profile fetch
- [ ] 9.5 *(not performed at archive — needs a real mail provider; do before release)* Manual: click the same link twice; let one expire and use the resend path from the expired page

---

## Follow-ups deliberately out of scope

- **Email-change flow.** None exists today. If one is added it MUST reset `email_verified` to false, or verification silently becomes meaningless.
- **Verifying pre-existing accounts.** Grandfathered by design (D4); any retrofit is an opt-in campaign, not a migration default.
- **Deliverability** (SPF/DKIM/DMARC) — infrastructure, not application behaviour.
- **Excluding unverified addresses from promo campaigns** to protect sender reputation (design open question).
- **Time-delayed hard gate.** Revisit only if unverified accounts become a measurable support problem.

---

## Implementation notes

- **Verified against real PostgreSQL.** All 55 versioned migrations were applied to a throwaway `postgres:15-alpine` container from empty, then V55's behaviour was checked directly: a pre-existing account is grandfathered to `email_verified = true`, while an account created afterwards starts `false`.
- **V55 was rewritten to be genuinely idempotent.** The first draft ran a bare `UPDATE parents SET email_verified = true` guarded by a meaningless `WHERE created_at < NOW()`. Re-applying it silently marked *every* unverified account verified — handing password recovery to addresses nobody had proven they control. The backfill now sits inside a `DO $$ ... $$` block that only runs when the column is actually created, and re-running is a verified no-op. Flyway does not re-run versioned migrations, but this must not depend on that: test harnesses and manual recovery steps do.
- **Fixed unrelated blocking corruption.** `V49__add_description_image_to_premium_packages.sql` ended with a stray `®` (bytes `c2 ae`), which made the whole migration set fail on a fresh apply — so no new environment could be provisioned. It was presumably applied cleanly before an editor mishap corrupted the file. Removed.
- **Fixed an unrelated credential leak.** `handlers.userResponse` embeds `*models.Parent`, whose `Password` field was tagged `json:"password"` — so `GET /user/:id` returned the account's bcrypt hash, which the app then persisted in local profile storage. Now `json:"-"`. No client ever read it, and the only inbound JSON bind into `Parent` was `SendOtp`, removed by this change. Covered by `TestUserResponse_ExposesVerificationState_AndNeverThePasswordHash`.
- **`UserResponseConverter` sets `emailVerified: false`.** It builds the profile cached immediately after signup; inheriting the `true` default would have hidden the prompt from exactly the users who need it. The `true` default remains correct elsewhere, so a profile from a backend predating the field never nags an existing user.
- **Test counts:** backend 485 → 489, app 193 → 202. Both ratchets green, `golangci-lint` 0 issues, `flutter analyze --no-fatal-infos` clean (9 pre-existing infos).

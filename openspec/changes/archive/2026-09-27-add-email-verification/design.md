# Design: Non-blocking email verification

## Context

Arunika is a parent-facing early-childhood app with Google Play Billing. Accounts are created by `POST /auth/signup`, which creates the `parents` row and immediately issues an access token and a DB-persisted refresh token. Password recovery is `POST /forgot-password` → emailed link → `POST /reset-password`.

There is no email verification anywhere. The OTP scaffolding that exists is inert on every layer (see `proposal.md` for the specific call sites). The audit that surfaced this also found that the reset-token mechanism is already well built — hashed at rest, 15-minute expiry, prior tokens invalidated on reissue — which shapes the decisions below.

**Constraint that drives everything here:** SMTP is a third-party dependency that fails independently of Arunika. Any design that makes account creation depend on successful mail delivery converts an email outage into a signup outage.

## Goals / Non-Goals

**Goals**
- Establish that a registrant controls the email address on their account.
- Close the one place where unverified email causes real harm: password-reset delivery.
- Keep registration succeeding when email delivery fails.
- Stop shipping scaffolding that implies a verification control the system does not perform.

**Non-Goals**
- Blocking login, content, AR, dongeng, purchases or entitlements on verification.
- Re-verification on email change (no email-change flow exists today; noted as a follow-up).
- Email deliverability engineering (SPF/DKIM/DMARC alignment) — infrastructure, not application behaviour.
- Verifying phone numbers.
- Retrofitting verification onto accounts that predate this change.

## Decisions

### D1. Verify without blocking registration — a soft gate

**Decision.** `POST /auth/signup` keeps its current behaviour exactly: create the account, issue tokens, return 201. The verification email is dispatched in a goroutine, best-effort, following the `sendNotificationAsync` pattern already used for payment notifications — the error is logged with `user_id` and never propagated.

**Why.** A hard gate ("you cannot register until you click the link") puts SMTP on the critical path of account creation. Mail providers rate-limit, credentials expire, and this codebase has already shipped a bug where *every* password-reset email silently failed because the sending path read an env var that was never set (see the comment in `ForgotPassword`). Under a hard gate that class of bug is a full signup outage; under a soft gate it is a degraded-but-working service and a log line.

The soft gate is safe here specifically because **entitlements key off `user_id`, never email** (`user_entitlements.user_id`, `user_subscriptions.user_id`). An unverified parent still receives every AR card, dongeng and subscription they paid for. Verification carries no authorization weight, so withholding it costs the user nothing they paid for.

**Alternatives considered.**
- *Hard gate at registration.* Rejected — trades a moderate problem for an outage-shaped one.
- *Hard gate at login.* Rejected — for a paid app this is a support burden with no security payoff: the attacker who registered under someone else's address already knows the password they set. It punishes the legitimate user, not the attacker.
- *Time-delayed hard gate (verify within N days or lose access).* Rejected for now: it reintroduces the outage risk on a delay and needs a whole lapse/restore flow. Revisit only if unverified accounts become a real support problem.

### D2. A verification link, not an OTP code

**Decision.** Email a one-time link containing an opaque token. Reuse the `password_reset_tokens` design: store only `sha256(token)`, set an expiry, invalidate prior tokens for that user on reissue.

**Why.** Three reasons, in order of weight:

1. **The mechanism already exists and is correct.** `utils.HashResetToken`, the `PasswordResetToken` model, prior-token invalidation and the server-rendered `templates/reset_password.html` page are all in place and tested. A link reuses all of it. An OTP would mean building verification, single-use enforcement, replay protection and per-account rate limiting from scratch — and the existing OTP code proves that half-built verification is worse than none.
2. **One tap versus code entry.** The signup flow is a parent registering on a phone, often one-handed. Tapping a link beats reading six digits back into a form.
3. **No shared-secret window.** An emailed code sits in an inbox as a reusable secret until it expires; a single-use link is consumed on first click.

**Expiry: 24 hours**, deliberately longer than the reset token's 15 minutes. A reset token is a live credential for changing a password, so it should be short-lived. A verification token only asserts mailbox control, and people check email hours later — a 15-minute window would generate resend traffic for no security gain.

**Token in URL.** A token in a query string can leak via `Referer` when the landing page loads third-party resources. The confirmation page must therefore be self-contained (no external requests) and must not echo the token back into the page.

### D3. Gate exactly one thing: password-reset delivery

**Decision.** `ForgotPassword` refuses to send a reset link to an unverified address. Nothing else consults `email_verified`.

**Why.** This is the only place where an unverified address causes real harm today: sending a password-reset link to an address nobody has proven they control is the actual vulnerability, and it is also the mechanism by which the *legitimate* owner of a squatted address could take over an account they never created.

Everything else — login, content, AR, dongeng, purchases, entitlements — is left alone on purpose. Gating more would cost real users access for a threat model that does not justify it.

**Non-enumeration must be preserved.** `ForgotPassword` currently returns `nil` for an unknown email so that responses are indistinguishable (there is a test for this: `TestForgotPassword_UnknownEmail_ReturnsNilWithoutEnumeration`). The unverified case must behave identically — same response, no new signal — or this change hands attackers an "is this address verified?" oracle. This is the single easiest thing to get wrong here.

### D4. Grandfather existing accounts as verified

**Decision.** The migration backfills `email_verified = true` for all pre-existing `parents` rows.

**Why.** The alternative — defaulting everyone to unverified — would immediately gate password-reset delivery for the entire live user base, locking existing users out of account recovery to solve a problem they do not have. It would also show a verification banner to every user at once.

**Trade-off, stated plainly:** existing accounts are never actually verified. Verification is enforced only for accounts created after this ships. That is the correct call for a live product, but it means the guarantee is forward-looking, not universal. If existing addresses ever need verifying, that is a separate, opt-in campaign — not a migration default.

### D5. Resend is rate-limited by the existing middleware

**Decision.** `POST /auth/resend-verification` sits behind `RateLimitMiddleware(rdb, "resend-verification", 5, 15*time.Minute)`, matching the limit already applied to `forgot-password`.

**Why.** Without a limit the endpoint is a mail-bombing primitive aimed at any address. The existing middleware is per-IP and fails open on Redis errors, which is the right posture: a Redis outage should not disable resend, only its limiting.

### D6. Confirmation is a server-rendered page, not a deep link

**Decision.** `GET /auth/verify-email?token=` renders an HTML confirmation page, mirroring `GET /reset-password` → `templates/reset_password.html`.

**Why.** The link is opened from a mail client, which may be on a different device from the app, or on desktop. A server-rendered page works everywhere with no platform plumbing. App deep-linking can be layered on later without changing the token mechanism.

The page must render a clear outcome for all three cases — verified, already verified, expired/invalid — and must offer a resend path for the expired case, or the user hits a dead end.

### D7. Delete the OTP scaffolding in this change

**Decision.** Remove `generateOtp`, `saveOtpToRedis`, `SendOTPEmail`, `AuthService.SendOtp`, `AuthHandler.SendOtp`, `POST /auth/send-otp`, `templates/otp_email.html`, and the app's `OtpBloc`/`OtpScreen`/`OtpEvent`/`OtpState` plus the unreachable `/otp` route.

**Why.** Leaving dead OTP code beside a live verification flow guarantees future confusion about which one is real. It is all unreachable, so removal carries no behavioural risk. It belongs in *this* change rather than a separate cleanup because the two would otherwise drift: a reviewer seeing OTP code and verification code side by side cannot tell which is authoritative.

This scaffolding already caused one concrete near-miss — a weak-randomness finding in `generateOtp` was initially assessed as a live OTP-predictability vulnerability, and only a full trace of the call graph showed the codes gated nothing.

## Risks / Trade-offs

- **A user who never verifies cannot use password reset.** → The banner explains why and offers resend; verification remains available indefinitely. This is the intended cost of D3, and it only affects post-launch accounts (D4).
- **Verification emails land in spam.** → Deliverability is infrastructure (D-non-goal), but the resend path and the indefinite verification window mean spam-filtering degrades the experience rather than breaking the account.
- **The reset gate could leak verification state.** → Explicitly called out in D3; the spec requires the unverified and unknown-email responses to be byte-identical, and this needs a test asserting exactly that.
- **Grandfathered accounts are unverified in reality.** → Stated in D4. Accepted deliberately; revisit only as an opt-in campaign.
- **Removing OTP code touches the app's router.** → All of it is provably unreachable (no caller, no navigation), so the risk is a compile error, not a behaviour change.

## Migration Plan

1. `V55__add_email_verification.sql` — add the column with `DEFAULT false`, create the token table, then `UPDATE parents SET email_verified = true` to grandfather existing rows. Order matters: backfill after the column exists and before any new signup can write `false`.
2. Ship backend issuance + endpoints. New accounts begin receiving emails; nothing is gated yet.
3. Ship the app banner.
4. Enable the reset gate **last**, once verification has been reachable for at least one release cycle — turning it on before users can verify would strand anyone who signed up in between.

Rollback at any step is independent: the gate is a single conditional, the banner is a widget, and the column is additive with a safe default.

## Open Questions

- Should the reset gate ship behind the existing `app_feature_flags` mechanism so it can be switched off without a deploy? (Recommendation: yes — it is the only user-blocking behaviour in the change.)
- Should verification state appear in the backoffice user detail page, so support can see why a reset was refused? (Recommendation: yes, read-only; it is the first question support will ask.)
- Is there an email-change flow planned? If one is added later it must re-set `email_verified = false`, or verification silently becomes meaningless.
- Should an unverified account be excluded from promo campaign sends (`admin_campaign_service`), to protect sender reputation from bouncing at unowned addresses?

## Context

The registration flow consists of:
- `/signup` → `SignupScreen` (parent form) inside a `ShellRoute` wrapping `SignupNavigator` with a shared `SignupBloc`
- `/signup/child` → `ChildSignupScreen` (child profile form)
- `/parent-signup-success` → `ParentRegistrationSuccessScreen` (post-registration)
- `/tnc` and `/privacy-policy` → static content screens

**Current back-navigation bug**: `SignupScreen` is a nested route under `ShellRoute`. The `AppBar` back button uses Flutter's default `Navigator.pop`, but GoRouter's `ShellRoute` does not push a route onto the Navigator stack — it wraps a shell. As a result, tapping back on `/signup` exits the app or does nothing instead of going to `/signin`. Fix: explicitly set `onPressed: () => context.go('/signin')` on the leading `BackButton`, or use `canPop`/`GoRouter.of(context).canPop()` logic in the AppBar.

**TnC / Privacy Policy**: Currently plain `ListView` with unstyled text. Need header branding, section cards, proper typography hierarchy.

**Register form**: Already has a white card with shadow. Improvements: add section labels/icons per field, improve spacing and field ordering, add a TnC checkbox before the submit button.

**Success modal**: Currently navigates to a separate `ParentRegistrationSuccessScreen`. Instead, show an in-flow `showDialog` congratulations modal with animation (Lottie or simple icon + text), then navigate to home or child setup from the modal action button.

## Goals / Non-Goals

**Goals:**
- Fix back navigation from `/signup` → `/signin`
- Redesign TnC and Privacy Policy screens (professional layout)
- Improve register form visual design (icons, spacing, TnC checkbox)
- Add congratulations modal on successful registration (replaces or augments success screen)
- Keep `SignupBloc` logic unchanged; UI-only changes where possible

**Non-Goals:**
- Changing registration API contract or adding new fields
- Redesigning the child signup screen (out of scope unless trivially aligned)
- Backend changes (not required; registration response is unchanged)

## Decisions

### 1. Back navigation fix: `context.go('/signin')` over system pop
The `ShellRoute` wrapping `SignupNavigator` means there is no Navigator stack entry for `/signin` below `/signup`. Using `context.go('/signin')` is the correct GoRouter-idiomatic approach. Alternative (`WillPopScope`/`PopScope`) is more complex and not needed.

### 2. Success: modal dialog over full-screen route
A `showDialog` modal with a congratulations animation is more delightful and keeps the user in context. The existing `ParentRegistrationSuccessScreen` can remain as a fallback but the primary path becomes a modal. This avoids adding a new route and reduces navigation complexity.

### 3. TnC / Privacy Policy redesign: no new dependencies
Use Flutter's built-in widgets (`Card`, `Divider`, `ExpansionTile` or simple sections) to achieve a clean professional look. No new packages needed.

### 4. Register form improvements: inline icons + TnC checkbox
Add `prefixIcon` to each `AppTextField`, reorder fields logically (name → email → phone → city → address → password), add a `Row` checkbox for TnC agreement before the submit button. The checkbox state lives in `SignupBloc` as a new boolean field `tncAccepted`.

## Risks / Trade-offs

- [TnC checkbox added to SignupBloc] → Minor bloc change required; low risk as it's an additive field with no backend impact
- [Modal replaces success screen] → If deep-link to `/parent-signup-success` is used anywhere, it still works; modal is an overlay on top of the existing flow

## Migration Plan

1. Create feature branch `feature/register-flow-improvements`
2. Apply Flutter UI changes (no migration needed — pure UI)
3. Test registration flow end-to-end on device/emulator
4. No backend deployment required

## Open Questions

- Should the congratulations modal auto-navigate after a timeout, or require the user to tap a button? → Prefer explicit button tap for accessibility.
- Should the child signup screen also get the form redesign? → Deferred; out of scope for this change.

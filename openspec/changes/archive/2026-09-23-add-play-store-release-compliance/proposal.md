# Add Google Play Store Release Compliance

## Why
Arunika is preparing for its first Google Play Store release. Passing Play review requires more than feature completeness. An audit of the current app against Google Play's Developer Program Policies found five concrete gaps:

1. **Payments**: premium packages/subscriptions are purchased through a Midtrans webview checkout. Google Play's Payments Policy requires apps to use Google Play's Billing System for digital content consumed inside the app (flashcard/AR unlocks, dongeng audio, subscriptions) — using an external payment processor for this is very likely to get the app rejected or later suspended.
2. **Account deletion**: the app supports account creation (parent + child profile) but has no way for a user to delete their account or data, in-app or otherwise. Play's User Data policy requires both an in-app deletion option and a web-accessible one that doesn't require installing or logging into the app.
3. **Families Policy / parental gate**: Arunika is directed at children (a parent creates an account, then a child profile with name and birthdate). Nothing currently stops a child from completing a purchase unsupervised — Play's Families Policy requires a parental gate in front of purchase flows in children's apps.
4. **Privacy policy**: a privacy policy screen exists inside the app, but Play Console requires a **public, hosted URL** for the privacy policy (reachable without installing the app), and it must accurately describe the child data collected.
5. **Console-only requirements**: the Data Safety form and content rating questionnaire in Play Console must be filled out accurately; there's currently no source-of-truth document mapping what the app actually collects to those forms, and the release build's target API level / Android App Bundle output hasn't been verified against Play's current requirements.

## What Changes
- **Google Play Billing with User Choice Billing**: add Google Play Billing, under Play Console's User Choice Billing program, as the purchase mechanism for premium packages/subscriptions bought from the Android app. Google Play presents the user a choice between Google Play and Arunika's alternative billing (Midtrans) in a Google-rendered selection screen; the backend verifies Google Play purchases via the Play Developer API, and reports Midtrans purchases made via the alternative option back to Google (required under User Choice Billing so Play can calculate its service fee). Existing Midtrans order/payment infrastructure is reused as-is for the alternative-billing path and for admin-issued manual grants.
- **Account deletion**: add an in-app "Delete Account" flow (Profile screen) backed by a new authenticated backend endpoint that deletes/anonymizes the user's data, including their child profile. Add a public, no-login-required account-deletion request page to the landing site.
- **Parental gate**: add a simple challenge screen in front of the premium/purchase entry points so a child can't complete a purchase without an adult.
- **Public privacy policy page**: add a Privacy Policy page to the landing site (arunika-landing) that mirrors the in-app policy, accurately discloses child data collection, and links to the account-deletion page — this becomes the URL submitted in Play Console.
- **Release readiness documentation**: verify the release build's target Android API level and Android App Bundle (`.aab`) output, and produce reference documents mapping Arunika's actual data collection to the Play Console Data Safety form and a recommended content-rating questionnaire.

## Impact
- **Affected capabilities**: `google-play-billing` (new), `account-deletion` (new), `parental-gate` (new), `play-store-release-readiness` (new), `landing-page` (modified)
- **Affected code**: `arunika_app` (Flutter/Android), `arunika-backend` (Go), `arunika-landing` (static site)
- **Out of scope**: iOS/App Store release requirements; migrating or backfilling historical Midtrans order data; adding ads (the app has none, so "Contains ads: No" is unaffected).

# Play Console Content Rating — Recommended Answers

This document gives recommended answers to Google Play Console's IARC content rating questionnaire, based on
Arunika's actual content as of the `add-play-store-release-compliance` change. Play Console path:
**App content → Content ratings**. The final questionnaire is completed in Play Console by whoever holds
account access — this is a reference, not a substitute for actually filling it in there.

## App category

Select **Education** (or **Education / Reference**, whichever the current IARC questionnaire flow offers) —
Arunika is a children's educational flashcard/AR and audio-story app.

## Recommended questionnaire answers

| Question | Answer | Why |
|---|---|---|
| Violence | None | No violent content anywhere in the app. |
| Sexuality | None | No sexual content. |
| Language (profanity) | None | No profanity; all copy is child-appropriate Indonesian. |
| Controlled substances (references to drugs, alcohol, tobacco) | None | Not present. |
| Gambling (simulated or real-money) | None | Not present. |
| User-generated content | No | Users cannot post, upload, or share content visible to other users. |
| User-to-user interaction / communication (chat, comments, etc.) | No | No chat, comments, or messaging between users of any kind. |
| Shares user's location | No | The app does not collect or share location. |
| Digital purchases | Yes | The app sells premium content packs/subscriptions (via Google Play Billing and, for legacy/manual flows, Midtrans). |
| Unrestricted internet access | Yes (functional necessity) | The app needs internet access for content delivery, purchases, and notifications; no unmoderated open web browsing is exposed to the child. |

## Expected outcome

Based on the above, Arunika should receive the most permissive content rating available in each region's
scheme (e.g., **PEGI 3**, **ESRB Everyone**, ratings equivalent to "suitable for all ages") — consistent with
an ad-free, chat-free children's educational app whose only mature-adjacent flag is "contains digital
purchases."

## Re-run when content changes

Re-answer the questionnaire in Play Console (not just this doc) if any of the following change:
- New content categories are added that could include violence, scary imagery, or mature themes (e.g. a new
  story category).
- Any form of user-to-user communication, comments, or shared/public content is introduced.
- An ads SDK is integrated.

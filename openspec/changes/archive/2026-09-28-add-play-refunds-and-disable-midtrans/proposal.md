# Change: Turn off Midtrans checkout and add Google Play refunds from the backoffice

## Why
**Midtrans and Google Play's rules.** Arunika sells digital content (AR cards, dongeng, content packages and subscriptions) in an app distributed on Google Play. Google Play's Payments policy requires Google Play's billing system for this kind of purchase. The only way to accept another payment method is an enrolled alternative-billing program. In Indonesia that means **User Choice Billing**, which comes with these conditions:
- only non-gaming apps are eligible
- the developer must enroll in Play Console and be registered as a business
- Google Play Billing must be offered alongside the alternative for every purchase
- every alternative-billing transaction must be reported to Google within 24 hours

Today the app does two things:
1. It offers Midtrans as the User Choice Billing alternative for items mapped to a Play product. This is allowed only while the app is enrolled in User Choice Billing.
2. It sends any item **without** a Play product mapping straight to a Midtrans checkout, on Android, iOS and web. On Android this is a standalone alternative biller with no Google Play choice, which the Indonesian program does not allow. On iOS, Apple's App Store Guideline 3.1.1 similarly requires in-app purchase for digital content.

Midtrans isn't used today. So the safe default is to turn it off everywhere, and keep the code behind a switch in case User Choice Billing is formally adopted later.

**Refunds.** Google Play refunds currently happen only outside the product, in Play Console or through Google support. The backend learns about them later, from the voided-purchases reconcile job or RTDN, and records nothing beyond the order becoming `REFUNDED`. The Android Publisher API supports refunds directly:
- `orders.refund`, with `revoke`, for one-time purchases
- `purchases.subscriptionsv2.revoke` with a full or prorated refund, for subscriptions

This means support staff can refund from the backoffice, and every refund can be audited.

## What Changes
- **Alternative billing switch (default off).** Add a new feature flag, `alternative_billing`, seeded **off**. Unlike the other flags, the app treats it as off when the flag is unknown or the backend is unreachable. While it's off:
  - **App:** Google Play Billing is the only payment path on Android, and User Choice Billing isn't enabled. An item without a Play product isn't sold: its option isn't shown, and a single product without one shows "Belum tersedia". iOS and web show that purchases aren't available on this device, and never open Midtrans. The Midtrans code stays in the app, reachable only when the flag is on.
  - **Backend:** `POST /payment/create` and `POST /payment/create-product` (the Midtrans checkout) return 403 `ALTERNATIVE_BILLING_DISABLED`. The Midtrans webhook and the admin "Sync Midtrans" action keep working, so existing Midtrans orders still settle.
- **Refund a Google Play order from the backoffice.** Add `POST /admin/orders/:id/refund` for `PAID` Google Play orders:
  - A one-time purchase (single product or content package) is refunded with `orders.refund?revoke=true`.
  - A subscription is refunded with `purchases.subscriptionsv2.revoke`, where the admin chooses a **full** or **prorated** refund.
  - On success, the order becomes `REFUNDED` and access is removed immediately (the existing entitlement and subscription revocation).
  - A reason is required. The admin who issued the refund is recorded.
- **Record every refund.** A new `order_refunds` table records each refund. That includes admin refunds and refunds Google reports on its own (a user refunding through Google, or a chargeback) via the voided-purchases reconcile job or RTDN. Each record holds:
  - the source and who issued it
  - the refund type and whether access was revoked
  - the Play order ID and purchase token
  - the order amount
  - Google's refunded total, tax and refund reason (read back with `orders.get`)
  - Google's order state and voided source/reason, where applicable
  - the status, any error, and the raw Google response
- **Backoffice Orders page:**
  - A "Refund" action on refundable Google Play orders opens a modal showing a summary, the refund type (subscriptions only), a required reason and a confirmation checkbox.
  - A "Refunds" detail view on any order with refund records.
- **Dropped from the previous version of this proposal:** Midtrans refund webhook handling and `orders.granted_days`. With Midtrans off they have no current use. If alternative billing is turned on later, that work comes back, together with reporting refunds of external transactions to Google (`externaltransactions.refund`).

## Impact
- Affected specs: `google-play-billing`, `app-feature-flags`, `payment-screen`, `monetization-orders-payments`, `premium-package-backoffice`
- Affected code:
  - **arunika-backend:**
    - migrations: seed the `alternative_billing` flag; create `order_refunds`
    - `services/google_play_verifier.go`: `RefundOrder`, `RevokeSubscription`, `GetOrder`
    - `services/payment_service.go`: refund, recording from the voided reconcile job and RTDN
    - `handlers/admin_order_handler.go` and routes: the refund and refund-list endpoints
    - `handlers/payment_handler.go`: the flag gate on the Midtrans endpoints
    - `openapi.yaml` and tests
  - **arunika-backoffice:** `pages/orders/OrdersPage.tsx` (Refund modal, refund details), the API client and types, tests and a Playwright spec
  - **arunika_app:**
    - `payment_screen.dart` and `payment_options_cubit.dart`: hide items without a Play product, and never use the Midtrans path while the flag is off
    - `google_play_billing_service.dart`: enable User Choice Billing only when the flag is on
    - feature flag handling for the new off-by-default flag
    - tests and integration flows
- **Behaviour change:** while the flag is off, items that have no Play product are no longer purchasable on any platform. iOS and web users can't buy anything until an in-app purchase path exists there. Ops must map every sellable item to a Play product in Play Console and the backoffice.
- Replaces the uncommitted `add-midtrans-refund-handling` proposal.

## Context
**Policy findings (researched 2026-09-28).** Sources: [Payments policy](https://support.google.com/googleplay/android-developer/answer/9858738), [User choice billing](https://support.google.com/googleplay/android-developer/answer/13821247), [Enrolling in user choice billing](https://support.google.com/googleplay/android-developer/answer/12570971), [June 2026 billing changes](https://android-developers.googleblog.com/2026/06/play-expanded-billing.html).
- Play-distributed apps must use Google Play's billing system for digital goods, content and subscriptions, unless the purchase goes through an enrolled alternative-billing program.
- In Indonesia, User Choice Billing is available to **non-gaming** apps. The developer must enroll (Play Console, Settings, Alternative billing), be registered as a business, and provide customer support.
- Google Play Billing **must be offered alongside** the alternative for every purchase. A standalone alternative is only possible in the EEA.
- Alternative-billing transactions must be reported through the external-transactions API within 24 hours. The service fee is 4% lower on those transactions.
- The June 2026 "expanded billing choice" (alternative billing or external links alongside Play) currently covers the UK, EEA and US, not Indonesia.
- Google's pages say nothing specific about Families (children's) apps and User Choice Billing. This has to be confirmed in Play Console before the flag is ever turned on.
- Apple's App Store Guideline 3.1.1 requires in-app purchase for digital content on iOS.

**What the code does today.**
- `payment_screen.dart` uses Play Billing on Android only when the item has a `play_product_id`. Every other case (unmapped items on Android, all of iOS and web) opens Midtrans Snap.
- `GooglePlayBillingService` always enables `BillingChoiceMode.userChoiceBilling`.

## Goals / Non-Goals
- **Goals:**
  - Midtrans is unreachable by default, on the client and the server.
  - Admins can refund Google Play orders with a reason.
  - Every refund (admin-issued or Google-initiated) is recorded with the data needed for support and accounting.
- **Non-Goals:**
  - Deleting the Midtrans code.
  - Midtrans refunds.
  - Reporting external-transaction refunds (both come back if the flag is ever turned on).
  - Partial refunds of one-time purchases (`orders.refund` doesn't support them).
  - An in-app purchase path on iOS.
  - Admin roles.

## Decisions

### 1. `alternative_billing` flag
- It's an `app_feature_flags` row, seeded `is_enabled = false`, so it appears on the backoffice App Features page.
- **It defaults to off wherever its state is unknown.** Other flags fail open in the app (a missing flag or an unreachable backend means "enabled"). This one fails closed: a fail-open would re-open a non-compliant payment path.
- **Backend gate:** `POST /payment/create` and `/payment/create-product` return 403 `{"code":"ALTERNATIVE_BILLING_DISABLED"}` while the flag is off. The webhook, `SyncOrderStatus` and admin sync stay open for historical orders.
- **App, while the flag is off:**
  - `GooglePlayBillingService` doesn't call `setBillingChoice(userChoiceBilling)`, so Play shows its normal sheet and never returns `userChoseAlternativeBilling`.
  - `PaymentOptionsCubit` drops packages without `play_product_id`.
  - A single product without one is shown with "Belum tersedia di perangkat ini" and no Bayar button.
  - On iOS and web, the whole payment screen shows an unavailable state.
- **When the flag is on:** User Choice Billing is enabled on Android, so Google Play's own choice screen can offer Midtrans as the alternative.
- **As implemented (stricter than "today's behaviour"):** an item is purchasable only when it's mapped to a Play product and Google Play Billing is available (Android). That holds whether the flag is on or off. User Choice Billing requires Google Play Billing alongside the alternative for every purchase, so a standalone Midtrans checkout for an unmapped item is never compliant. Midtrans is reachable only as the alternative inside Google Play's choice screen.
- **Renewals:** a Midtrans subscription can only be renewed in-app through the Midtrans checkout. So while the flag is off, the backend reports `can_renew = false` for Midtrans subscriptions, and the "Perpanjang" button doesn't appear.

### 2. Refund API mapping
| Order | Google call | Effect |
|---|---|---|
| One-time (product or content package) | `POST …/orders/{playOrderId}:refund?revoke=true` | Full refund. The item is revoked by Google, and locally with `RevokeEntitlementForOrder`. |
| Subscription | `POST …/purchases/subscriptionsv2/tokens/{token}:revoke` with `revocationContext.fullRefund` or `proratedRefund` | Subscription ended and refunded. Locally: `RevokeSubscription`. |

- **Identifiers used:**
  - `playOrderId` is the `GPA.…` id saved in `payments.provider_order_id` when the purchase was verified.
  - `token` is `orders.purchase_token`.
  - Subscriptions use the token rather than an order ID, because every renewal has its own `GPA.…` order ID.
- **Preconditions:** the order is `PAID`, `provider = google_play`, has a purchase token (plus the Play order ID for one-time purchases), and is less than 3 years old. Google refuses anything older.
- **Order of operations:**
  1. Insert an `order_refunds` row with status `REQUESTED` (this also blocks a second concurrent refund, see below).
  2. Call Google.
  3. On success, in one transaction: set the order to `REFUNDED`, revoke access, and mark the refund `SUCCEEDED`.
  4. On failure, mark it `FAILED` with Google's error. The order stays `PAID`.
- **Filling in the amounts:** Google's refund calls return an empty body. After success, call `orders.get` (one-time: `playOrderId`; subscription: the latest order in `payments`) and store `refunded_total`, `refunded_tax`, `currency`, the Google order state and the refund reason.
  - This is best effort. If it fails, the refund still counts, and the admin "Sync refund details" action retries it.
- **Idempotency:** a partial unique index on `order_refunds(order_id) WHERE status IN ('REQUESTED','SUCCEEDED')` prevents two refunds of the same order. If Google reports the order is already refunded, the refund is recorded as `SUCCEEDED` with a note, and access is revoked.

### 3. `order_refunds` table
```
id UUID PK
order_id UUID FK → orders            provider VARCHAR  ('google_play')
source  VARCHAR  CHECK IN ('ADMIN','GOOGLE_VOIDED','GOOGLE_RTDN')
refund_type VARCHAR CHECK IN ('FULL','PRORATED')     revoked BOOLEAN
reason TEXT (required for ADMIN)      admin_id UUID NULL → admin_users
play_order_id TEXT                     purchase_token TEXT
order_amount_idr BIGINT                (the amount charged, copied from the order)
refunded_total NUMERIC NULL, refunded_tax NUMERIC NULL, currency VARCHAR NULL   (from orders.get)
play_order_state VARCHAR NULL          (e.g. REFUNDED, PENDING_REFUND)
play_refund_reason VARCHAR NULL        (OTHER | CHARGEBACK)
voided_source INT NULL, voided_reason INT NULL   (voided-purchases API)
status VARCHAR CHECK IN ('REQUESTED','SUCCEEDED','FAILED')
error TEXT NULL, raw_response JSONB NULL
requested_at TIMESTAMPTZ, completed_at TIMESTAMPTZ NULL
```
- The existing `ReconcileVoidedPurchases` job, and RTDN `SUBSCRIPTION_REVOKED`, insert a `SUCCEEDED` row with source `GOOGLE_VOIDED` or `GOOGLE_RTDN` whenever they move an order to `REFUNDED`.
- An admin refund that Google later also reports doesn't create a second row, because the order is already `REFUNDED` and those paths skip it.

### 4. Backoffice
- **Orders table:** a danger "Refund" button appears on rows where `provider = google_play`, `status = PAID` and `has_purchase_token = true`.
- **The modal:**
  - order summary (user, item, amount, Play order ID)
  - for subscriptions, a refund-type radio (Full / Prorated, default Full)
  - a required reason (at least 10 characters)
  - a required checkbox: "Uang dikembalikan ke pengguna dan aksesnya dicabut sekarang"
- **Result handling:** a success message, or Google's error text on failure.
- **Refund history:** orders with refund rows get a "Refunds" link. It opens a drawer listing each row: source, admin, time, type, amounts, Google state, and status or error. A "Sync refund details" button re-reads `orders.get`.

## Risks / Trade-offs
- **Unmapped items stop selling while the flag is off.** Ops needs to map items to Play products before release. The app hides these items rather than showing them broken.
- **iOS and web can't purchase** until an in-app purchase path exists. This is the compliant option, and it was an accepted consequence of turning Midtrans off.
- **Any admin can refund,** because there are no roles. This is mitigated by the required reason, the confirmation, and the audit trail (`admin_id`). Roles are an open question.
- **A Google call can succeed while the local update fails.** The row stays `REQUESTED`, and the voided-purchases reconcile (plus the admin "Sync") later moves the order to `REFUNDED`, and the row to `SUCCEEDED`. The UI shows `REQUESTED` rows as "Menunggu konfirmasi".

## Open Questions
- Should refunds be limited to a subset of admins? (The app has no admin roles today.)
- Is Arunika enrolled in User Choice Billing in Play Console? It only matters if the flag is ever turned on. Confirm eligibility for a Families app at that point.

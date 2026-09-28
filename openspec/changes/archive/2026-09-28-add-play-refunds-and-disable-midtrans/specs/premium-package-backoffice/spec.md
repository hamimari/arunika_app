## RENAMED Requirements
- FROM: `### Requirement: Backoffice has a read-only Orders view`
- TO: `### Requirement: Backoffice has an Orders view with Google Play refunds`

## MODIFIED Requirements

### Requirement: Backoffice has an Orders view with Google Play refunds
The system SHALL provide an "Orders" view listing `orders` with `user`, `product`/`package` reference, `amount_idr`, `status`, and `created_at`, filterable by `status`. Rows with `provider = google_play`, `status = PAID` and a purchase token SHALL have a "Refund" action. It SHALL open a modal with:
- the order summary (user, item, amount, Play order id)
- for subscriptions, a Full / Prorated choice
- a required reason of at least 10 characters
- a required confirmation that the money is returned and access removed

Submitting SHALL call `POST /admin/orders/:id/refund`, and SHALL show Google's error message if it fails. An order with refund records SHALL have a "Refunds" view listing each record (source, admin, time, type, amounts, Google state, status or error), with a "Sync refund details" action.

#### Scenario: Orders list is filterable by status
- **WHEN** the admin filters the Orders view by `status = PAID`
- **THEN** only orders with `status = 'PAID'` SHALL be shown

#### Scenario: Refund offered only for refundable Play orders
- **WHEN** the Orders view shows a `PAID` Google Play order with a purchase token, a Midtrans order, and a `REFUNDED` order
- **THEN** only the first SHALL have a "Refund" action

#### Scenario: Admin refunds a subscription with a prorated refund
- **WHEN** the admin opens Refund on a subscription order, chooses Prorated, enters a reason, ticks the confirmation and submits
- **THEN** `POST /admin/orders/:id/refund` SHALL be sent with `refund_type: "PRORATED"` and the reason, and the row SHALL show `REFUNDED` afterwards

#### Scenario: Submit blocked until reason and confirmation
- **WHEN** the reason is shorter than 10 characters or the confirmation is unticked
- **THEN** the modal SHALL NOT submit

## ADDED Requirements

### Requirement: No new orders for active subscribers except renewals in the window
Every order-creating endpoint (`POST /payment/create`, `POST /payment/create-product`, and the Google Play Billing order/verification entry point) SHALL respond 409 with error code `SUBSCRIPTION_ACTIVE`, and SHALL NOT create an order or start a charge, when the requesting user has an active subscription (`status = 'premium'`, `expires_at` in the future). The only exception SHALL be a `subscription`-type package order via `POST /payment/create` when all of the following hold:
- the subscription is renewable (`auto_renew = false` and now ≥ `expires_at` − 7 days)
- its `provider` is not `google_play`

Google Play auto-renewals reconciled via Real-time Developer Notifications SHALL NOT be affected, because they do not create orders through these endpoints.

#### Scenario: Subscriber tries to buy a single product
- **WHEN** a user with an active subscription calls `POST /payment/create-product`
- **THEN** the server SHALL respond 409 `SUBSCRIPTION_ACTIVE` and no `orders` row SHALL be created

#### Scenario: Subscriber tries to renew too early
- **WHEN** a Midtrans subscriber whose subscription expires in 20 days calls `POST /payment/create` for a subscription package
- **THEN** the server SHALL respond 409 `SUBSCRIPTION_ACTIVE`

#### Scenario: Subscriber renews inside the window
- **WHEN** a Midtrans subscriber whose subscription expires in 5 days calls `POST /payment/create` for a subscription package
- **THEN** the order SHALL be created normally

#### Scenario: Subscriber tries to buy a content package inside the window
- **WHEN** a subscriber inside the renewal window calls `POST /payment/create` for a `content`-type package
- **THEN** the server SHALL respond 409 `SUBSCRIPTION_ACTIVE`

#### Scenario: Play subscriber cannot renew through a new order
- **WHEN** a subscriber whose subscription `provider = 'google_play'` is inside the window and attempts a new subscription order
- **THEN** the server SHALL respond 409 `SUBSCRIPTION_ACTIVE`

#### Scenario: Expired subscriber can buy
- **WHEN** a user's subscription `expires_at` is in the past and they call `POST /payment/create`
- **THEN** the order SHALL be created normally

## ADDED Requirements

### Requirement: Midtrans checkout is closed while alternative billing is off
While the `alternative_billing` feature flag is off, `POST /payment/create` and `POST /payment/create-product` SHALL respond 403 with code `ALTERNATIVE_BILLING_DISABLED`, and SHALL NOT create an order or a Midtrans transaction. The Midtrans webhook, order status sync and admin order sync SHALL keep working, so Midtrans orders created earlier still settle.

#### Scenario: Checkout refused while the flag is off
- **WHEN** the flag is off and a user calls `POST /payment/create-product`
- **THEN** the server SHALL respond 403 `ALTERNATIVE_BILLING_DISABLED`, and no `orders` row SHALL be created

#### Scenario: Earlier Midtrans order still settles
- **WHEN** the flag is off and a Midtrans settlement webhook arrives for an order created before
- **THEN** the order SHALL be processed as usual

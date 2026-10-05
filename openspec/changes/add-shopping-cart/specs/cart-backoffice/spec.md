## ADDED Requirements

### Requirement: Staff can browse cart and single-item orders
The existing Orders list SHALL serve as "Pesanan": it SHALL show cart orders with their items, total, channel, status and the "Dibayar, belum diberikan" phase, filterable by status (including paid-not-granted), cart-only and date range, behind the existing staff login and role checks. The admin orders API SHALL include `order_items` for cart orders.

#### Scenario: Filter by status
- **WHEN** staff filter the list by "dibayar" (paid, not granted)
- **THEN** only paid orders with no grant SHALL be listed

#### Scenario: Cart order shows items
- **WHEN** staff open a cart order
- **THEN** the detail SHALL list every item with its locked price and the store transaction id

### Requirement: Staff can regrant a paid order
The order list SHALL offer "Berikan ulang" for orders paid in the store but not granted (phase `diproses`). It SHALL call the same grant function as settlement, and every use SHALL be written to the admin audit log with the staff id.

#### Scenario: Regrant
- **WHEN** staff press "Berikan ulang" on a paid ungranted order
- **THEN** the items SHALL be granted and an audit entry with the staff id SHALL exist

#### Scenario: Not offered when granted
- **WHEN** an order is already granted
- **THEN** the action SHALL not be shown and the API SHALL refuse it

### Requirement: Price fields enforce the Rp 1.000 step
The price field for Kartu AR and Dongeng SHALL accept only whole multiples of Rp 1.000, with a message when it does not, and SHALL show that the maximum cart total is Rp 500.000.

#### Scenario: Invalid price
- **WHEN** staff enter 1500
- **THEN** the form SHALL show an error and not submit

### Requirement: Produk toko page shows coverage
A "Produk toko" page SHALL list `store_products` and flag totals from Rp 1.000 to Rp 500.000 that have no active product.

#### Scenario: Gap flagged
- **WHEN** the product for Rp 77.000 is missing
- **THEN** the page SHALL list Rp 77.000 as missing

## ADDED Requirements

### Requirement: Buyable item cards show Beli and an add-to-cart button
Every item card on the Kartu AR and Dongeng lists that is paid, sold singly and not owned SHALL show a "Beli" button and an add-to-cart icon button. (Locked items have no detail screen in the app today — tapping one opens the purchase — so there is no detail bottom bar to extend.) "Beli" keeps the existing single-item purchase. Free items SHALL show "Buka"; owned items SHALL show "Buka" with the label "Dimiliki"; Premium-only content SHALL show its usual Premium button and no cart control. Premium subscribers SHALL see no cart buttons. All visible text SHALL be Indonesian and use the design system tokens.

#### Scenario: Paid unowned card
- **WHEN** a paid card the user does not own is listed
- **THEN** the card SHALL show "Beli" and the add-to-cart icon

#### Scenario: Owned card
- **WHEN** a listed card is owned
- **THEN** it SHALL show the "Dimiliki" label and "Buka AR" and no cart button

#### Scenario: Subscriber
- **WHEN** the user has Akses Premium
- **THEN** no card SHALL show "Beli" or the cart button

### Requirement: Adding gives immediate feedback and can be undone
Tapping the add icon SHALL add the item optimistically, show the toast "Ditambahkan ke keranjang" with a "Lihat" link, turn the icon green with a check, and show "Di keranjang · Lihat" under the card. Tapping the green icon SHALL remove the item with a toast. An item SHALL never be added twice. If the add fails the UI SHALL roll back and show the reason. When the cart is full or at the total limit, the icon SHALL show "Keranjang penuh".

#### Scenario: Add
- **WHEN** the user taps the cart icon on a paid card
- **THEN** the toast and the green check SHALL appear and the header badge SHALL increase by one

#### Scenario: Add fails
- **WHEN** the add call fails with a network error
- **THEN** the icon SHALL return to its normal state and a message SHALL be shown

#### Scenario: Cart full
- **WHEN** the cart holds 20 items
- **THEN** the cart icon on other cards SHALL show "Keranjang penuh" and SHALL not add

### Requirement: List headers show a cart badge
The headers of the Kartu AR and Dongeng lists SHALL show a cart icon with a count badge from 1 to 20, hidden when the cart is empty, and tapping it SHALL open the cart. The cart SHALL load from the server when the app opens and after sign-in.

#### Scenario: Empty cart
- **WHEN** the cart is empty
- **THEN** the badge SHALL be hidden

#### Scenario: Badge count
- **WHEN** the cart holds 3 items
- **THEN** the badge SHALL read 3

### Requirement: Keranjang screen lists items and totals
The cart screen SHALL list each item with picture, type label (Kartu AR or Dongeng), title, current price and, when on promo, the crossed-out price; show "Rincian harga" with the count of items at normal price, "Hemat promo" and the total; and a bottom bar with the item count, the total as the only bold number, the saving and the "Bayar" button. It SHALL state that Akses Premium is bought separately. An empty cart SHALL show the empty state with links to Kartu AR and Dongeng. Anyone SHALL be able to browse the cart without the parental gate.

#### Scenario: Cart with a promo
- **WHEN** an item has a strike price
- **THEN** its row SHALL show the strike price and the saving SHALL be reflected in "Hemat promo"

#### Scenario: Empty cart
- **WHEN** the cart has no items
- **THEN** the screen SHALL show "Keranjangmu masih kosong" with links to Kartu AR and Dongeng

### Requirement: Items can be deleted with undo
Each row SHALL have a delete button. Deleting SHALL remove the row at once and show "Item dihapus" with "Urungkan" for 5 seconds; tapping it SHALL add the item back. "Hapus semua" SHALL ask for confirmation before clearing.

#### Scenario: Undo
- **WHEN** the user deletes an item and taps "Urungkan" within 5 seconds
- **THEN** the item SHALL be back in the cart

#### Scenario: Undo expires
- **WHEN** 5 seconds pass without tapping "Urungkan"
- **THEN** the item SHALL stay removed

#### Scenario: Hapus semua confirmation
- **WHEN** the user taps "Hapus semua" and cancels the dialog
- **THEN** the cart SHALL be unchanged

### Requirement: Changes found on the server are shown before paying
When the cart or `POST /orders` reports changes, the cart SHALL show a banner "Ada perubahan sejak kamu menambahkan item" listing what happened (owned item removed, promo ended, item free, item no longer available), mark price-changed rows with "Harga naik dari ..." and unavailable rows with "Tidak tersedia lagi", exclude unavailable rows from the total, and change the button to "Bayar lagi". Paying SHALL need another tap.

#### Scenario: Owned item removed
- **WHEN** the server removed an owned item
- **THEN** the banner SHALL mention it by name and "Bayar lagi" SHALL be shown

#### Scenario: Item unavailable
- **WHEN** an item is off sale
- **THEN** its row SHALL be greyed with "Tidak tersedia lagi" and SHALL not count toward the total

### Requirement: Payment needs the parental gate and a summary
"Bayar" SHALL always open the parental gate, even if it was passed earlier in the session, then create the order and show "Ringkasan pembayaran" (items, prices, total, saving, "Dibayar lewat Google Play. Sekali bayar, bukan langganan." and "Item jadi milik akun ini selamanya") with "Bayar Rp ..." and "Kembali ke keranjang". Only then SHALL the Google Play sheet open, for the product the server returned. One payment SHALL cover all items.

#### Scenario: Child taps Bayar
- **WHEN** the parental gate is answered wrongly
- **THEN** no order SHALL be created and no payment sheet SHALL open

#### Scenario: Summary then store
- **WHEN** the gate is passed and the order is created
- **THEN** the summary SHALL show the order's items and total before the Play sheet opens

### Requirement: Payment results have their own screens
After payment: "Berhasil" ("Hore, N item sudah jadi milikmu!") SHALL list every item with "Buka" or "Baca" and the cart SHALL drop only those items; a cancelled or failed payment SHALL show "Pembayaran dibatalkan" with "Tidak ada biaya yang ditagih", keep the cart as it was and offer "Coba bayar lagi"; a paid but ungranted order SHALL show "Pembayaranmu sedang kami proses", poll `GET /orders/:id` every 5 seconds for 1 minute, and the app SHALL receive a push when it is granted. Unfinished purchases SHALL be reported to the server at app start. After a grant the Kartu AR and Dongeng lists SHALL reload so the items show as owned.

#### Scenario: Success
- **WHEN** the order is granted
- **THEN** the Berhasil screen SHALL list every item and the cart SHALL no longer contain them

#### Scenario: Cancel
- **WHEN** the parent cancels the Play sheet
- **THEN** the Dibatalkan screen SHALL show and the cart SHALL be unchanged

#### Scenario: Grant delayed
- **WHEN** payment succeeded but the order is not yet granted
- **THEN** the Sedang diproses screen SHALL show and polling SHALL continue for 1 minute

#### Scenario: App restarted after payment
- **WHEN** the app starts with an unconsumed cart purchase from Google Play
- **THEN** it SHALL send the purchase to `/orders/:id/verify`

### Requirement: Cart actions are tracked
The app SHALL emit the events `cart_add`, `cart_remove`, `cart_undo`, `cart_view`, `checkout_start`, `parent_gate_pass`, `payment_success`, `payment_cancel`, `payment_fail` and `grant_complete`, each with item ids, item count and total, through one replaceable sink (the structured log until an analytics SDK is added).

#### Scenario: Add event
- **WHEN** an item is added
- **THEN** a `cart_add` event SHALL be emitted with the item id, count and total

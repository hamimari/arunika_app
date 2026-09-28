## MODIFIED Requirements

### Requirement: AR cards show ownership and a Beli or Buka AR action
Each AR card in the Koleksi grid SHALL be a card with its picture on top, then its title and one action.
- A locked card SHALL show its picture in greyscale with a lock badge, and, when it has a `price_idr`, its price formatted as "Rp 15.000" (with `strike_price_idr` crossed out beside it when non-null) and a "Beli" button with a cart icon. A locked card on promo (non-null `strike_price_idr` and `discount_percent`) SHALL also show a "-N%" badge over the picture.
- An unlocked card SHALL show its picture in full colour with no dimming, no badge over the picture, a status chip under its title, and a "Buka AR" button. It SHALL NOT show a price, and SHALL NOT show any other caption under its title.
- The status chip of an unlocked card that has a product (it was bought) SHALL read "Dimiliki", in grey with a check icon. The status chip of an unlocked card without a product (free content) SHALL read "Gratis", in green with a gift icon.

Tapping the card or its button SHALL open the card when unlocked. When locked, it SHALL open the purchase for that card, passing its product id, price, strike price and Google Play product id, or ask a signed-out user to sign in first.

#### Scenario: Locked card with a promo
- **WHEN** a locked AR card has `price_idr = 15000`, `strike_price_idr = 30000` and `discount_percent = 50`
- **THEN** the card SHALL show "Rp 15.000", a crossed-out "Rp 30.000", a "-50%" badge, a lock badge, a greyscale picture and a "Beli" button

#### Scenario: Locked card without a promo
- **WHEN** a locked AR card has `price_idr = 20000` and no strike price
- **THEN** the card SHALL show only "Rp 20.000" and a "Beli" button, with no "%" badge

#### Scenario: Beli starts the purchase with the Play product id
- **WHEN** a signed-in user taps "Beli" on a locked card whose `play_product_id` is `sku_frog`
- **THEN** the app SHALL open the payment screen for that card's product with `sku_frog` set

#### Scenario: A signed-out user taps Beli
- **WHEN** a signed-out user taps "Beli"
- **THEN** the app SHALL ask them to sign in and SHALL NOT open the payment screen

#### Scenario: Bought card
- **WHEN** an AR card is unlocked for the user and has a product
- **THEN** its picture SHALL be in full colour with no badge over it, a "Dimiliki" chip SHALL sit under the title, "Buka AR" SHALL be shown, and there SHALL be no lock badge, price or "Sudah jadi milikmu" caption; "Buka AR" SHALL open the card

#### Scenario: Free card
- **WHEN** an AR card is unlocked and has no product
- **THEN** it SHALL show its picture in full colour with no badge over it, its title, a "Gratis" chip under the title and "Buka AR", and no "Dimiliki" label, whether or not the user is signed in

#### Scenario: Narrow phone with enlarged text
- **WHEN** the grid is shown on a 360-pixel-wide screen with 140% text
- **THEN** the cards SHALL NOT overflow

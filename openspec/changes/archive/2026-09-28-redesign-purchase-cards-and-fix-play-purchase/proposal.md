# Change: Buy buttons on AR cards and dongeng, and a working Google Play purchase for single items

## Why
- **Locked cards and stories had no obvious way to buy them.** The AR grid showed a dimmed card with a small price chip, and dongeng rows a lock icon. The designs put a "Beli" button and the price on each one, and a clear owned state ("Dimiliki" / "Buka AR", "Baca").
- **Paying failed with "Gagal memuat halaman pembayaran".** That single message covered every failure of the Google Play path: no Play Store, a SKU Google doesn't know, an order the backend refused, and a payment Google took but the server couldn't confirm. Nothing was logged, and the last case, where the user has paid, told them to "try again".
- **A single AR card or dongeng could not be bought through Google Play at all.**
  - The AR card and dongeng responses didn't carry the product's `play_product_id`, so the app never knew a single item's SKU.
  - Nothing could set `products.play_product_id` either: no endpoint wrote it, and the Products page had no field. Only packages could be mapped.
  - Turning Midtrans off (`add-play-refunds-and-disable-midtrans`) removed the only route single items had, so they became unbuyable.
  - A single-product purchase interrupted before the app reported it also couldn't be recovered on the next start, because recovery only looked up packages.

## What Changes
- **AR card tile** (`collection-screen`):
  - A white card with the picture on top, then title and action.
  - Locked: greyscale picture, a lock badge, "-N%" when on promo, the price with its crossed-out price, and a "Beli" button.
  - Owned: the picture in full colour with no overlay, a "Dimiliki" badge, "Sudah jadi milikmu" and a "Buka AR" button.
- **Dongeng list** (`dongeng-list-screen`):
  - A featured card with a "Pilihan minggu ini" pill, and title, age/duration and a "Baca" (or "Beli") button below the picture.
  - A locked story is a card with a lock on its thumbnail and a "Hemat N%" pill when on promo, then a dashed rule and its price beside "Beli".
  - An owned or free story stays compact, with "Baca".
  - The existing header, category dropdowns and filter icon are unchanged.
- **Payment failures say why** (`payment-screen`): distinct messages for Play unavailable, product not found in Play, order not created, and paid-but-unconfirmed ("jangan bayar ulang"). The reason is logged.
- **Single items are buyable through Google Play** (`google-play-billing`, `premium-package-backoffice`):
  - AR card and dongeng responses include `play_product_id`, and the app passes it to the payment screen.
  - The backoffice can set it: a "Play Product ID" field on Add and Edit product, and a "Play Billing" column.
  - An update that leaves the field out keeps the mapping. A SKU already used by another product or package is rejected.
  - Recovery of an interrupted purchase now works for single products as well as packages.

## Impact
- Affected specs: `collection-screen`, `dongeng-list-screen`, `payment-screen`, `google-play-billing`, `premium-package-backoffice`
- Affected code:
  - **arunika-backend:** the AR card, dongeng and product services, models, handlers and the payment service
  - **arunika-backoffice:** the Products page and API client
  - **arunika_app:** the collection and dongeng list screens, the payment screen, the billing service, the card and dongeng models, `AppColors` and `AppStrings`
- **Ops:** every AR card and dongeng that is sold needs its Play SKU set on the Products page. Until then it shows "Belum tersedia di perangkat ini" on the payment screen.
- Not changed: the category dropdowns and filter sheet on both list screens.

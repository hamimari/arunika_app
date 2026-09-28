## 1. Backend
- [x] 1.1 Return `play_product_id` on AR card list/detail and dongeng list/detail
- [x] 1.2 Let `POST /admin/products` and `PUT /admin/products/:id` set the product's Play SKU. Absent leaves the mapping unchanged, null or blank clears it, and a SKU already used by another product or package is a 400. The admin list returns `play_product_id`
- [x] 1.3 Recover an interrupted Play purchase of a single product (pending order looked up by SKU across packages and products)
- [x] 1.4 API tests through the real router and database

## 2. Backoffice
- [x] 2.1 Products: "Play Product ID" on Add and Edit, and a "Play Billing" Mapped/Unmapped column
- [x] 2.2 Client, page and API tests, and a Playwright spec that maps a product and checks the public list carries the SKU

## 3. App
- [x] 3.1 `playProductId` on the card and dongeng models, passed through `goToProductPurchase` to the payment screen
- [x] 3.2 Billing outcomes for store unavailable, product not found and order failed, with logging. The payment screen shows a message per cause
- [x] 3.3 AR card tile: Beli / Buka AR, promo and Dimiliki badges, greyscale only while locked
- [x] 3.4 Dongeng list: featured card and story rows per the design, keeping the existing header and filters. Long titles and prices shrink instead of overflowing
- [x] 3.5 Widget tests, including a narrow phone with enlarged text, and emulator flows: buying a mapped card from its tile, and the dongeng list with a promo

## 4. Validation
- [x] 4.1 On the emulator against a fresh e2e stack: all flows pass, and screenshots match the mockups
- [x] 4.2 `openspec validate redesign-purchase-cards-and-fix-play-purchase --strict`

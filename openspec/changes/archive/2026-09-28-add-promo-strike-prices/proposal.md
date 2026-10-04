# Change: Promotional strike prices and a redesigned payment page

## Why
Locked AR cards and dongeng don't show a price anywhere in their lists today. Users only find out what something costs once they're on the payment page. We want lists and package cards to show the real price next to a crossed-out "strike" price. This is a marketing signal that makes the offer look attractive. Marketing also needs to tune that label from the backoffice without a release.

The payment page also has two problems. It still says "Pembayaran diproses melalui Midtrans…", which is no longer accurate. And it sends users to a separate screen to compare premium packages, so upselling from a single item to a package takes an extra step.

## What Changes
- **Strike-price rules (backend + backoffice, new capability `promo-strike-price`)**
  - Global rules for three scopes: `AR_CARD`, `DONGENG` and `PACKAGE`. Each rule has a mode of `NONE`, `PERCENT` or `FIXED` plus a value.
  - An optional per-product and per-package override. It can inherit the global rule, turn the strike price off, or set its own percent or fixed amount.
  - `PERCENT` is a displayed discount: strike = price ÷ (1 − p/100), rounded up to the nearest Rp 1.000. `FIXED` adds an amount: strike = price + amount.
  - **Every strike price is a time-limited promo.** Each rule or override needs an end date, can have an optional start date, and runs for at most 90 days. The strike price disappears automatically when the promo ends, and the app shows "Promo s/d {date}". The UI never calls the strike price "Harga normal". Together these avoid presenting a permanent, never-charged "normal price", which Indonesian consumer-protection law (UU 8/1999) and Google Play policy can treat as misleading.
  - The strike price is display-only. Charged amounts, orders and Google Play prices are unchanged. A real charged discount isn't compatible with Play Console's fixed SKU prices, so it's out of scope (see design §8).
  - Public content and package APIs gain `strike_price_idr`, `discount_percent` and `promo_ends_at`. All three are nullable and computed server-side.
  - The backoffice gets a "Harga Coret" settings page for the global rules (with a promo period picker and an Aktif/Terjadwal/Berakhir status) and strike-price fields in the Product and Package edit modals, with a live preview.
- **App lists**: locked AR cards on the Koleksi screen and paid dongeng on the dongeng list show the price, plus a crossed-out strike price when one exists.
- **Premium upgrade screen**: package cards show the strike price, a discount badge and the promo end date.
- **Payment page redesign**
  - Remove the Midtrans / Google Play info note.
  - Replace the "Ingin lebih hemat?" link-out with a selectable option list shown on the page: "this item only" (for single-product purchases) followed by all active premium packages.
  - Selecting an option updates the price breakdown (strike price, savings and total) and determines what "Bayar Sekarang" pays for.

- **Active subscribers pay nothing, except to renew in the last 7 days**
  - While a subscription is active, the user already has all paid content, so the app shows no prices, packages or purchase buttons. Instead, `/premium` and the payment page show a "Langganan aktif" state.
  - **Renewal window.** In the last 7 days before expiry, a subscription that won't renew by itself becomes renewable:
    - The profile card and `/premium` show "Perpanjang".
    - The payment page offers only subscription packages, with the current plan preselected.
    - The summary shows the new end date, e.g. "Aktif sampai 31 Okt 2026 → 30 Nov 2026".
    - The new period is added from the previous expiry date, so no paid days are lost. The backend already does this stacking (`computeSubscriptionExpiry`). This change specifies it and adds tests.
  - **Google Play subscriptions**:
    - With auto-renew on, they renew by themselves, so there's nothing to buy. The app shows "Diperpanjang otomatis pada {tanggal}".
    - If the user cancelled auto-renew, "Perpanjang" opens Google Play's subscription page to resubscribe. Google keeps the current expiry and bills the next period from it, which is stacking done natively by Play.
    - To support this, the backend starts tracking `auto_renew` and the subscription's `provider`.
  - The backend rejects every order from an active subscriber, except a subscription-package order inside the renewal window of a non-Play subscription. So a subscriber can't be charged by mistake.
  - The backend decides eligibility and returns it on the user profile as `subscription.can_renew`, `renewable_from` and `auto_renew`.

## Impact
- Affected specs: `promo-strike-price` (new), `payment-screen`, `premium-upgrade-screen`, `premium-package-flutter`, `collection-screen`, `dongeng-list-screen`, `monetization-orders-payments`, `user-entitlements`, `google-play-billing`
- Affected code:
  - **arunika-backend**: new migration (rules table + override columns on `products` and `premium_packages`), a new `services/strike_price_service.go`, `ar_service.go`, `dongeng_service.go`, `premium_pack_service.go`, `product_service.go`, `payment_service.go` (active-subscription guard, RTDN auto-renew tracking), `entitlement_service.go`, `handlers/user_handler.go` (renewal fields), a migration adding `provider` to `user_subscriptions`, admin handlers/routes and `openapi.yaml`
  - **arunika-backoffice**: new `pages/settings/StrikePricePage.tsx` and changes to `pages/products/ProductsPage.tsx`, `pages/packages/PremiumPackagesPage.tsx`, the API clients and the sidebar
  - **arunika_app**: `ArCardResponse`, `DongengResponse`, `PremiumPack`, `PurchasableItem`, `collection_screen.dart`, `new_dongeng_list_screen.dart`, `premium_upgrade_screen.dart`, `payment_screen.dart`, `profile_screen.dart`, `SubscriptionInfo`, plus a shared price widget
- **Behaviour change**: today, subscribers can extend at any time. After this change, extending is only possible in the last 7 days before expiry, and the extra days still stack from the previous expiry date.
- Not breaking: all new API fields are additive and nullable. The landing site keeps working without changes.

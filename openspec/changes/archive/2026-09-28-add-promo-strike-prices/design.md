## Context
Pricing is spread across three repos. `products.price_idr` covers single AR cards and dongeng, and it's surfaced on the AR card and dongeng responses. `premium_packages.price_idr` covers packages. The app only shows a price on the payment page and the premium upgrade screen. We need a display-only "strike price" that marketing can set globally or per item, and a payment page that offers packages as in-place alternatives to the single item.

## Goals / Non-Goals
- Goals: backoffice-configurable strike prices (global per scope, plus per-item overrides); consistent display across the app; a payment page where picking a package updates the total and what gets paid for.
- Non-Goals: real discounts or coupons (the charged amount never changes; see §8); showing strike prices on the landing site; changing Google Play Console prices; changing the Midtrans or Play Billing flows themselves.

## Decisions

### 1. Data model
- New table `strike_price_rules`:
  - `scope` VARCHAR(20) PK, CHECK IN (`AR_CARD`, `DONGENG`, `PACKAGE`)
  - `mode` VARCHAR(10) NOT NULL, CHECK IN (`NONE`, `PERCENT`, `FIXED`)
  - `value` INTEGER NOT NULL DEFAULT 0
  - `starts_at` TIMESTAMPTZ NULL (null means it starts immediately), `ends_at` TIMESTAMPTZ NULL
  - CHECK: `mode = 'NONE' OR ends_at IS NOT NULL`
  - `updated_at`
  - Seeded with all three scopes set to `NONE`/`0`, so nothing changes visually until an admin opts in.
- Override columns on both `products` and `premium_packages`:
  - `strike_mode` VARCHAR(10) NULL, CHECK IN (`NONE`, `PERCENT`, `FIXED`)
  - `strike_value` INTEGER NULL
  - `strike_starts_at` / `strike_ends_at` TIMESTAMPTZ NULL, with the same end-date CHECK for `PERCENT`/`FIXED`
  - `NULL` mode means "inherit the global rule". `NONE` means "no strike price for this item, even if the global rule has one".
  - While a `PERCENT`/`FIXED` override is outside its period, the item falls back to the global rule. That way a finished item promo doesn't also cancel a running site-wide promo.
- A product's scope comes from its feature code (`AR_CARD` / `DONGENG`). Every package uses the `PACKAGE` scope.
- Why columns rather than a polymorphic override table: there are exactly two owner tables, and the existing specs already avoid polymorphic `resource_type` references (`monetization-catalog`).

### 2. Computation (backend only)
A single pure function, `ComputeStrikePrice(price, mode, value) (strike *int64, discountPct *int)`:
- `PERCENT` (value 1–90): `strike = ceil(price / (1 - value/100) / 1000) * 1000`
- `FIXED` (value ≥ 1): `strike = price + value`
- The result is `nil` when the mode is `NONE`, the price is ≤ 0, or `strike ≤ price`.
- `discount_percent = round((strike - price) / strike * 100)`, calculated from the final rounded numbers so the badge always matches what's on screen. Example: Rp 39.000 with 20% → strike Rp 49.000, badge −20%.
- Resolution order:
  1. An item override of `NONE` gives no strike price.
  2. Otherwise, use the item's `PERCENT`/`FIXED` override if it's inside its period.
  3. Otherwise, use the scope's global rule if it's inside its period.
  4. Otherwise, there's no strike price.
- "Inside the period" means `coalesce(starts_at, -∞) ≤ now < ends_at`. It's evaluated per request, so a promo ends exactly on time with no cron job or cache invalidation.
- Maximum period: 90 days, validated on save. This is the key safeguard. A strike price can only ever be a time-limited promo, never a permanent fake "normal price". The number lives in one constant and is easy to change.
- The backend computes this so the app, backoffice preview and any future client all agree. The app never does strike-price math.

Rules are read once per request (three rows) and applied in memory when building list responses. There's no N+1 query and no cache layer needed.

### 3. API surface
- Public: `strike_price_idr` (nullable int), `discount_percent` (nullable int) and `promo_ends_at` (nullable ISO-8601) are added to AR card list and detail, dongeng list and detail, and `GET /premium/packs`. They're null together whenever there's no active promo.
- Admin:
  - `GET /admin/strike-price-rules` returns the three rules, including their period and computed status (`ACTIVE`, `SCHEDULED`, `ENDED`, `OFF`).
  - `PUT /admin/strike-price-rules/:scope` takes `{mode, value, starts_at, ends_at}`. It returns 404 for an unknown scope. It returns 400 for a value out of range, a missing or past end date, an end before the start, or a period over 90 days.
  - `PUT /admin/products/:id` and `PUT /admin/premium/packs/:id` accept optional `strike_mode` (`null` means inherit), `strike_value`, `strike_starts_at` and `strike_ends_at`.
  - Admin product and package list responses include the stored override plus the effective `strike_price_idr` and `promo_ends_at`, for table display.

### 4. Backoffice
- New "Harga Coret" page under Settings, next to Feature Flags. It has one card per scope (Kartu AR, Dongeng, Paket Premium). Each card has:
  - a mode selector (Tidak ada / Persen / Nominal)
  - a value input
  - an Ant Design `RangePicker` for the promo period (start optional, end required, WIB, capped at 90 days)
  - an example preview line such as "Rp 39.000 → ~~Rp 49.000~~ · s/d 31 Okt"
  - a status tag (Aktif / Terjadwal / Berakhir / Nonaktif)
- Product edit modal and Package modal: a "Harga coret" select (Ikuti global / Tidak ada / Persen / Nominal), plus a value input and period picker when relevant, and a live preview. The preview is computed client-side with the same formula for instant feedback. The server remains the source of truth.
- The Products and Packages tables get a "Harga coret" column showing the effective strike price and its end date.

### 5. App display
- A shared `PriceTag` widget shows the strike price (grey, line-through) above or beside the real price. It can also show an optional "−20%" pill and an optional "Promo s/d 31 Okt" caption built from `promo_ends_at`. It's reused in the lists, on package cards and on the payment page.
- Koleksi and the dongeng list show a `PriceTag` only on locked items that have a `priceIdr`, without the date caption because the grid tiles are small. Unlocked and free items show nothing new.
- Package cards and the payment page show the "Promo s/d …" caption, so the time limit is visible wherever the user decides to buy.
- The app doesn't re-check `promo_ends_at` itself. It shows whatever the last response returned. A list left open past midnight shows the old strike price until the next refresh, which is acceptable.

### 6. Payment page redesign
Layout, top to bottom:
1. App bar "Pembayaran".
2. **"Pilih paket"** section with a vertical list of selectable option cards (radio-style):
   - When the page was opened for a single product, the first option is "Beli {title} saja" at the product's price.
   - Then all active packages from `GET /premium/packs` (no type filter), ordered by `sort_order`. Each card shows its name, subtitle, badge, `is_best_value` highlight and `PriceTag`.
   - The page opens with the entry item preselected, whether it's the product or the package chosen on `/premium`.
3. A sticky bottom summary:
   - Selected option name
   - The strike price, crossed out, followed by "Hemat Rp X · Promo s/d {date}". This appears only if there's an active promo. We deliberately avoid the label "Harga normal", because the strike price isn't a price anyone is actually charged.
   - **Total**: the real price
   - "Bayar Sekarang 🔒"
- Tapping an option updates the summary instantly. It needs no network call.
- On pay, the page builds the `PurchasableItem` from the selected option. That means `/payment/create` or Play Billing for packages, and `/payment/create-product` or Play Billing for the product. It's the same routing as today, just based on the selection instead of the entry item. `/unlock-success` receives the selected item.
- Selection is disabled while a token or Play purchase is in progress.
- If packages fail to load, the entry item option still shows and can be paid for. A compact "Gagal memuat paket · Coba lagi" row replaces the package list. A skeleton shows while loading.
- The Midtrans / Google Play info note and the "Ingin lebih hemat?" link-out are removed.
- The package list is loaded through the existing `PremiumPackRepository.fetchPacks()` (no type) and its cache.

### 7. Active subscribers
Under `user-entitlements`, an active, unexpired subscription already unlocks every paid AR card and dongeng. There is nothing left for these users to buy, so the purchase surface is hidden entirely.

The one exception is **renewal in the last 7 days**.

**What exists today.** `EntitlementService.upsertSubscription` already stacks: `computeSubscriptionExpiry` extends from `max(now, expires_at)`. What's missing is a rule for *when* renewal is allowed, handling for Play-managed subscriptions, and the UI. Note the actual column names: `user_subscriptions` uses `status IN ('free','premium')` and `expires_at`. The `user-entitlements` spec still says `active`/`end_date`, and this change corrects it.

**Data.** Two things are added to `user_subscriptions`:
- A new `provider` column (`midtrans` | `google_play`), set whenever access is granted: from the order's provider on a purchase, or `google_play` on an RTDN sync.
- Maintenance of the existing but never-written `auto_renew` column:
  - On Play verification, set it from Play's `autoRenewing`.
  - On RTDN `SUBSCRIPTION_CANCELED`, set it to false.
  - On `RESTARTED`, `RENEWED` and `RECOVERED`, set it to true.
  - For Midtrans subscriptions, it's always false.

**Eligibility (backend-computed, one constant `RenewalWindowDays = 7`).**
- `renewable_from = expires_at − 7 days`
- `can_renew = active && !auto_renew && now ≥ renewable_from`

The profile endpoint returns these in `subscription` as `can_renew`, `renewable_from`, `auto_renew` and `provider`, so the app never does date math.

**What the user sees.** The app reads the profile it already loads for the home and profile screens.

| State | Profile card | `/premium` | Payment page |
|---|---|---|---|
| Active, outside window | "Aktif sampai {date}", no button | "Langganan aktif" view, no packages | "Langganan aktif" view |
| Active, Play, `auto_renew = true` | "Diperpanjang otomatis pada {date}", no button | Same view with that text | Same |
| In window, Midtrans | "Perpanjang" → `/premium` (subscription only) | Subscription tab only, with the banner "Masa aktif baru ditambahkan mulai {expiry}" | Subscription packages only, current plan preselected, summary "Aktif sampai {old} → {new}" |
| In window, Play, auto-renew cancelled | "Perpanjang" → Google Play subscription page (`https://play.google.com/store/account/subscriptions?sku={play_product_id}&package={appId}`) | Same button, no in-app packages | Same view (not reachable in normal flow) |
| Expired | Normal purchase flow | Normal | Normal |

- The new end date shown on the payment page is `expires_at + selected package's duration_days`, computed in the app for display only. The backend computes the real value on settlement.
- Switching plans in the window is allowed for Midtrans subscriptions: for example, from Bulanan to Tahunan. The days still stack, and `package_id` switches to the new plan. This is existing backend behaviour.
- Switching plans on Play-managed subscriptions (Play upgrade/downgrade replacement modes) is out of scope.
- The `subscriptionOnly` mode of `/premium` stays and becomes the renewal entry point.
- Lists need no change. Subscribers get `is_unlocked = true`, and prices only appear on locked items.

**Backend guard (source of truth).** Every order-creating path returns **409** with `SUBSCRIPTION_ACTIVE` when the user has an active subscription. That covers `POST /payment/create`, `POST /payment/create-product` and the Play Billing order and verification entry. **Exception:** a subscription-type package order is allowed when `can_renew` is true and `provider ≠ google_play`. Play subscriptions renew through Play itself, not through a new order. This also protects against stale clients and older app versions, which today allow extending at any time. The app maps a 409 to the "Langganan aktif" view.

### 8. Why the promo is time-boxed but still display-only
The user chose to fix the fake-reference-price risk with a promo period (option 1 of the options discussed). There are two variants:
- **(a) Chosen: display-only with a required, capped period.** The charged price stays `price_idr`. The strike price appears only during a dated promo of at most 90 days and disappears automatically. The UI states the end date and never calls the strike price "Harga normal".
- **(b) Rejected for now: a real discount.** In this variant, the promo price is actually charged and `price_idr` becomes the true normal price after the promo. It doesn't work with Google Play Billing. Play charges the fixed price configured in Play Console for each SKU, so a backoffice-driven discount would show one price in the app and charge another in Play's sheet. Doing it properly needs Play Console promotional offers or separate SKUs, which belongs in its own change.

## Risks / Trade-offs
- **Implying a discount that never existed.** Consumer-protection rules (UU 8/1999 Pasal 9–10) and Google Play policy can treat a fake "was" price as misleading. Mitigations:
  - Every promo must have an end date and lasts at most 90 days.
  - The end date is shown to the user.
  - The UI never uses the label "Harga normal".
  - The feature is opt-in: every rule is seeded `NONE`.

  The remaining risk: marketing could chain back-to-back 90-day promos. The status tags and table columns make that visible. It's a business policy decision, not something the code prevents.
- **Play Store price mismatch.** Play Billing shows the Play Console price in its own sheet. Strike prices are purely in-app labels, and the charged price is unchanged, so there's no mismatch in the amount.
- **Payment page now depends on packages loading.** This is handled by the graceful fallback above.
- **Refund of a stacked renewal.** Midtrans refunds aren't handled by the webhook today, so a refunded Midtrans renewal leaves the order `PAID` and its days are kept. Google Play refunds and revocations end access immediately. That's correct for them, because under this change a Play subscription never stacks on an earlier period. Taking back only the refunded order's days is tracked in the separate change `add-midtrans-refund-handling`.
- **Existing Play subscribers have `auto_renew = false` until their next RTDN.** Because the column was never written, some auto-renewing Play subscribers could briefly see "Perpanjang" (which only opens Play's page, so they can't pay twice). To avoid it, a one-off backfill sets `auto_renew = true` and `provider = 'google_play'` for subscriptions whose latest `PAID` order has `provider = 'google_play'`. Their true state is then corrected by the next RTDN.

## Migration Plan
1. Deploy the backend migration and API fields. They're additive, and the seeds are `NONE`, so nothing is visible yet.
2. Deploy the backoffice.
3. Release the app. Older app versions ignore the new fields.
4. Marketing turns rules on.

Rollback: set every rule to `NONE`. The columns can stay.

## Open Questions
- None blocking. Defaults chosen:
  - Percent range 1–90, rounding up to the nearest Rp 1.000.
  - Promo period is at most 90 days, with times in WIB.
  - Renewal window is the last 7 days before expiry (`RenewalWindowDays`).
  - An expired item override falls back to the global rule.
  - All packages (content and subscription) are shown on the payment page.

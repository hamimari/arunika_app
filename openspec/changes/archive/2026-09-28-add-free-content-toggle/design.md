# Design: Free content toggle

## Context
Access today is resolved as follows:
- **AR cards** (`ArService.applyUnlocked`): no linked product → unlocked; otherwise entitlement or subscription.
- **Dongeng** (`DongengService.computeUnlocked`): first short-circuits on `dongengs.is_free`.

Products are linked to content through `product_ar_cards` / `product_dongengs`. Orders and entitlements reference products with RESTRICT/NO ACTION.

## Decisions

### A content-level `is_free` flag, not product deletion
- Adding `ar_cards.is_free` mirrors the existing dongeng flag, so both content types behave the same way.
- The flag wins over any product. `applyUnlocked` checks `card.IsFree` before resolving the product and returns `IsUnlocked = true` with no product, exactly like `computeUnlocked` does.
- Alternatives considered:
  - **Deleting the product:** fails for anything sold or bundled and loses history.
  - **Price 0 on the product:** a zero-price product would still go through the order and Play flows, and Play SKUs can't be free.
  - **A flag on `products`:** splits the "is this free" logic between two tables, while dongeng already uses a content-level flag.

### Effective access shown to admins
Two sources decide whether an item is free (the flag, and whether a product exists), so the backoffice shows one computed value instead of making admins reason about both:

| `is_free` | product | `access` |
|---|---|---|
| true | any | `FREE` |
| false | none | `FREE_NO_PRODUCT` |
| false | active | `PAID` |
| false | inactive | `PAID_INACTIVE` |

The backend computes this in the admin list endpoints, which already join products for the Products page.

### The flag has its own endpoint; saving a card never changes it
`PATCH /admin/content/ar-cards/:id/free` and `.../fairy-tales/:id/free` (body `{"is_free": bool}`, required) change only the flag, following the existing `.../visibility` toggles. `PUT` on an AR card does **not** write `is_free`. The update binds the whole model, so a client that omitted the field would otherwise silently turn a free card back into a paid one (the repo already guards `play_product_id` against the same mistake). `POST` (create) does accept `is_free`. The AR card edit form applies a changed Access through the PATCH first, then saves, and does not save if the PATCH fails. Dongeng `PUT` already wrote `is_free` before this change and keeps doing so.

### Defaults
- The migration sets `is_free = false` on existing AR cards, so their current behaviour is unchanged.
- Create forms default the Access field to **Free**. A new item without a product is free anyway, so the default matches reality. An admin who picks **Premium** sees a hint that a product must be created on the Products page. Until then the item shows `FREE_NO_PRODUCT`.

### Purchases of free content
Recovering a purchase that was already paid on Google Play (`ResolvePendingPlayOrder`) is deliberately **not** blocked: the user has paid, and making the item free later must not strand them.

- The app hides purchase UI for unlocked content. A stale client or a direct API call could still create an order, so the single-product order endpoints reject a product whose linked content is `is_free` (400, "content is free").
- Packages are not blocked. A bundle can still list a free item, and the backoffice warns the admin instead. Buyers still get an entitlement row for it, which is harmless.

## Risks / Trade-offs
- If an admin flips a sold item to free and later back to paid, previous buyers keep access through their entitlements, and users who never paid lose access again. This is the expected behaviour.
- A Play SKU mapped to a free product stays active in Play Console. The admin should deactivate it there if they want. This is noted in the backoffice hint and not automated.

## Migration Plan
Adding the column is additive, and the backend is deployed before the backoffice. Rollback: ignore the column (default false).

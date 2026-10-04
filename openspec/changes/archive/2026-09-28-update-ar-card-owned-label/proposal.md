# Change: Redesign the free and bought AR card states

## Why
Free AR cards are unlocked for everyone, so the grid showed "Dimiliki" and "Sudah jadi milikmu" on them, though nothing was bought. With free content now creatable from the backoffice (`add-free-content-toggle`) it would be most of the grid. The new design (`free_and_bought.png`) gives free and bought cards their own state under the title.

## What Changes
- A free card (unlocked, no product) shows a green "Gratis" chip with a gift icon under its title.
- A bought card (unlocked, has a product) shows a grey "Dimiliki" chip with a check icon under its title.
- Neither state puts a badge over the picture any more, and the "Sudah jadi milikmu" caption is removed. Pictures stay in full colour (only locked cards are greyscale).
- Both keep the "Buka AR" button; locked cards are unchanged ("-N%" badge, lock, price, "Beli").

## Impact
- Affected spec: `collection-screen` (requirement "AR cards show ownership and a Beli or Buka AR action").
- Affected code: `lib/presentation/screens/vocab/collection_screen.dart`, `lib/constants/app_colors.dart` (two soft chip colours), `lib/constants/app_strings.dart` (unused `ownedCaption` removed), `test/presentation/screens/vocab/ar_entry_gate_test.dart`.
- Known limit: a subscriber also sees unlocked paid cards with a product, so they are labelled "Dimiliki" although access comes from the subscription. The API doesn't say how access was obtained, so this can't be told apart without a backend change.
